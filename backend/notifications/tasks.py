import logging
from celery import shared_task
from django.contrib.auth import get_user_model
from django.utils import timezone

logger = logging.getLogger(__name__)
User = get_user_model()


@shared_task(bind=True, max_retries=3, default_retry_delay=60, name='notifications.envoyer_sms_confirmation')
def envoyer_sms_confirmation(self, reservation_id):
    try:
        from reservations.models import Reservation
        from .services import SMSService, NotificationService
        reservation = Reservation.objects.select_related('user', 'trajet__ligne__depart', 'trajet__ligne__arrivee').prefetch_related('passagers__siege').get(id=reservation_id)
        user = reservation.user
        if user.notif_sms and user.telephone:
            SMSService().envoyer_confirmation_reservation(user, reservation)
        NotificationService.confirmation_reservation(user, reservation)
        logger.info(f'Confirmation envoyee pour reservation {reservation.reference}')
    except Exception as exc:
        logger.error(f'Erreur confirmation {reservation_id}: {exc}')
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=120, name='notifications.envoyer_sms_verification')
def envoyer_sms_verification(self, user_id, code):
    try:
        from .services import SMSService
        user = User.objects.get(id=user_id)
        if user.telephone:
            SMSService().envoyer_code_verification(user, code)
    except Exception as exc:
        logger.error(f'Erreur SMS verif {user_id}: {exc}')
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=60, name='notifications.envoyer_alerte_retard_bulk')
def envoyer_alerte_retard_bulk(self, trajet_id, retard_minutes):
    try:
        from reservations.models import Reservation
        from .services import SMSService, NotificationService
        reservations = Reservation.objects.filter(trajet_id=trajet_id, statut=Reservation.Statut.CONFIRMEE).select_related('user', 'trajet__ligne__depart', 'trajet__ligne__arrivee')
        sms = SMSService()
        nb = 0
        for res in reservations:
            NotificationService.alerte_retard(res.user, res, retard_minutes)
            if res.user.notif_sms and res.user.telephone:
                sms.envoyer_rappel_voyage(res.user, res)
                nb += 1
        logger.info(f'Alertes retard envoyees : {nb} SMS pour trajet {trajet_id}')
    except Exception as exc:
        logger.error(f'Erreur alertes retard {trajet_id}: {exc}')
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=2, default_retry_delay=30, name='notifications.envoyer_email_verification')
def envoyer_email_verification(self, user_id, code):
    try:
        from .services import EmailService
        user = User.objects.get(id=user_id)
        if user.notif_email:
            EmailService().code_verification(user, code)
    except Exception as exc:
        logger.error(f'Erreur email verif {user_id}: {exc}')
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=2, name='notifications.envoyer_email_reinit_mdp')
def envoyer_email_reinit_mdp(self, user_id, code):
    try:
        from .services import EmailService
        user = User.objects.get(id=user_id)
        EmailService().reinitialisation_mot_de_passe(user, code)
    except Exception as exc:
        logger.error(f'Erreur email reinit mdp {user_id}: {exc}')
        raise self.retry(exc=exc)


@shared_task(name='notifications.envoyer_rappels_voyages')
def envoyer_rappels_voyages():
    from reservations.models import Reservation
    from .services import SMSService, NotificationService
    maintenant = timezone.now()
    dans_deux_heures = maintenant + timezone.timedelta(hours=2)
    fenetre_debut = dans_deux_heures - timezone.timedelta(minutes=5)
    fenetre_fin = dans_deux_heures + timezone.timedelta(minutes=5)
    reservations = Reservation.objects.filter(
        statut=Reservation.Statut.CONFIRMEE,
        trajet__heure_depart__range=(fenetre_debut, fenetre_fin)
    ).select_related('user', 'trajet__ligne__depart', 'trajet__ligne__arrivee')
    sms_service = SMSService()
    nb = 0
    for res in reservations:
        NotificationService.rappel_voyage(res.user, res)
        if res.user.notif_sms and res.user.telephone:
            sms_service.envoyer_rappel_voyage(res.user, res)
        nb += 1
    logger.info(f'Rappels envoyes : {nb}')
    return nb


@shared_task(name='notifications.expirer_reservations')
def expirer_reservations():
    from reservations.models import Reservation
    from transport.models import Siege
    reservations_expirees = Reservation.objects.filter(statut=Reservation.Statut.EN_ATTENTE, expire_at__lt=timezone.now())
    nb = 0
    for reservation in reservations_expirees:
        Siege.objects.filter(passager__reservation=reservation).update(statut=Siege.Statut.LIBRE, reserve_jusqu=None)
        reservation.statut = Reservation.Statut.EXPIREE
        reservation.save(update_fields=['statut', 'updated_at'])
        nb += 1
    if nb:
        logger.info(f'Reservations expirees : {nb}')
    return nb


@shared_task(name='notifications.generer_trajets_depuis_horaires')
def generer_trajets_depuis_horaires():
    from transport.models import Horaire, Trajet, Siege
    from datetime import datetime, timedelta
    import pytz
    tz = pytz.timezone('Africa/Abidjan')
    demain = timezone.now().date() + timedelta(days=1)
    jour_semaine = demain.weekday()
    horaires = Horaire.objects.filter(est_actif=True).select_related('ligne__depart', 'ligne__arrivee', 'transporteur', 'bus')
    nb = 0
    for horaire in horaires:
        if jour_semaine not in horaire.jours:
            continue
        if not horaire.bus or not horaire.bus.est_operationnel:
            continue
        heure_depart = tz.localize(datetime.combine(demain, horaire.heure_depart))
        duree = horaire.ligne.duree_estimee_minutes or 180
        heure_arrivee = heure_depart + timedelta(minutes=duree)
        trajet, created = Trajet.objects.get_or_create(
            ligne=horaire.ligne, bus=horaire.bus, transporteur=horaire.transporteur,
            heure_depart=heure_depart,
            defaults={'heure_arrivee_estimee': heure_arrivee, 'prix_fcfa': horaire.prix_fcfa, 'statut': Trajet.Statut.PLANIFIE})
        if created:
            Siege.generer_pour_trajet(trajet)
            nb += 1
    logger.info(f'Trajets generes pour le {demain} : {nb}')
    return nb


@shared_task(name='notifications.calculer_versements_mensuels')
def calculer_versements_mensuels():
    from paiements.models import Paiement, Versement
    from transport.models import Transporteur
    from django.db.models import Sum
    import calendar
    maintenant = timezone.now()
    if maintenant.month == 1:
        annee, mois = maintenant.year - 1, 12
    else:
        annee, mois = maintenant.year, maintenant.month - 1
    premier_jour = timezone.datetime(annee, mois, 1, tzinfo=timezone.utc)
    dernier_jour = timezone.datetime(annee, mois, calendar.monthrange(annee, mois)[1], 23, 59, 59, tzinfo=timezone.utc)
    nb = 0
    for transporteur in Transporteur.objects.filter(est_actif=True):
        total = Paiement.objects.filter(reservation__trajet__transporteur=transporteur, statut=Paiement.Statut.SUCCES, confirme_le__range=(premier_jour, dernier_jour)).aggregate(total=Sum('montant'))['total'] or 0
        if total == 0:
            continue
        commission = int(total * float(transporteur.taux_commission) / 100)
        net = total - commission
        versement, created = Versement.objects.get_or_create(
            transporteur=transporteur, periode_debut=premier_jour.date(), periode_fin=dernier_jour.date(),
            defaults={'montant_brut': total, 'commission_yobus': commission, 'montant_net': net})
        if created:
            nb += 1
            logger.info(f'Versement cree : {transporteur.nom} - {net:,} FCFA')
    logger.info(f'Versements calcules : {nb}')
    return nb


@shared_task(name='notifications.nettoyer_tokens_push_invalides')
def nettoyer_tokens_push_invalides():
    from .models import TokenPush
    from datetime import timedelta
    seuil = timezone.now() - timedelta(days=90)
    nb_supprimes, _ = TokenPush.objects.filter(est_actif=False, updated_at__lt=seuil).delete()
    logger.info(f'Tokens push supprimes : {nb_supprimes}')
    return nb_supprimes
