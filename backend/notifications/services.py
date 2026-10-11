import logging
logger = logging.getLogger(__name__)


class SMSService:
    """Envoi SMS via Africa's Talking."""

    def __init__(self):
        try:
            import africastalking
            from django.conf import settings
            africastalking.initialize(username=settings.AT_USERNAME, api_key=settings.AT_API_KEY)
            self.sms = africastalking.SMS
            self.sender_id = settings.AT_SENDER_ID
            self._actif = True
        except Exception:
            self._actif = False

    def envoyer(self, telephone, message, user=None):
        from .models import LogSMS
        log = LogSMS.objects.create(user=user, telephone=self._normaliser(telephone), message=message)
        if not self._actif:
            logger.info(f'SMS simule vers {telephone}: {message[:60]}')
            log.statut = LogSMS.Statut.ENVOYE
            log.save(update_fields=['statut'])
            return True
        try:
            response = self.sms.send(message=message, recipients=[self._normaliser(telephone)], sender_id=self.sender_id)
            recipients = response.get('SMSMessageData', {}).get('Recipients', [])
            if recipients and recipients[0].get('status') == 'Success':
                log.statut = LogSMS.Statut.ENVOYE
                log.reference_at = recipients[0].get('messageId', '')
                log.cout = recipients[0].get('cost', '0').replace('XOF ', '')
                log.save(update_fields=['statut', 'reference_at', 'cout'])
                return True
            log.statut = LogSMS.Statut.ECHEC
            log.message_erreur = str(response)
            log.save(update_fields=['statut', 'message_erreur'])
            return False
        except Exception as e:
            log.statut = LogSMS.Statut.ECHEC
            log.message_erreur = str(e)
            log.save(update_fields=['statut', 'message_erreur'])
            logger.error(f'Erreur SMS vers {telephone}: {e}')
            return False

    def envoyer_confirmation_reservation(self, user, reservation):
        message = (
            f'TamBour - Reservation {reservation.reference} confirmee !\n'
            f'{reservation.trajet.ligne.depart.nom} -> {reservation.trajet.ligne.arrivee.nom}\n'
            f'Depart : {reservation.trajet.heure_depart.strftime("%d/%m/%Y a %H:%M")}\n'
            f'Sieges : {", ".join(p.siege.numero for p in reservation.passagers.all())}\n'
            f'Montant : {reservation.montant_total:,} FCFA. Bonne route !'
        )
        return self.envoyer(user.telephone, message, user)

    def envoyer_rappel_voyage(self, user, reservation):
        message = (
            f'TamBour - Rappel : votre bus part dans 2 heures.\n'
            f'{reservation.trajet.ligne.depart.nom} -> {reservation.trajet.ligne.arrivee.nom}\n'
            f'Depart : {reservation.trajet.heure_depart.strftime("%H:%M")}. Soyez a la gare 30 min avant.'
        )
        return self.envoyer(user.telephone, message, user)

    def envoyer_code_verification(self, user, code):
        message = f'TamBour - Code de verification : {code}. Valable 15 minutes. Ne partagez pas ce code.'
        return self.envoyer(user.telephone, message, user)

    def _normaliser(self, telephone):
        tel = telephone.replace(' ', '').replace('-', '')
        if not tel.startswith('+'):
            if tel.startswith('225'): return f'+{tel}'
            if len(tel) == 10: return f'+225{tel}'
        return tel


class EmailService:
    """Envoi emails via Django."""

    def envoyer(self, destinataire, sujet, template_html, contexte):
        try:
            from django.core.mail import EmailMultiAlternatives
            from django.template.loader import render_to_string
            from django.utils.html import strip_tags
            html_content = render_to_string(template_html, contexte)
            text_content = strip_tags(html_content)
            from django.conf import settings
            email = EmailMultiAlternatives(subject=sujet, body=text_content, from_email=settings.DEFAULT_FROM_EMAIL, to=[destinataire])
            email.attach_alternative(html_content, 'text/html')
            email.send()
            logger.info(f'Email envoye a {destinataire}: {sujet}')
            return True
        except Exception as e:
            logger.error(f'Erreur email vers {destinataire}: {e}')
            return False

    def confirmation_reservation(self, user, reservation):
        return self.envoyer(user.email, f'TamBour - Reservation {reservation.reference} confirmee', 'emails/confirmation_reservation.html', {'user': user, 'reservation': reservation, 'trajet': reservation.trajet, 'passagers': reservation.passagers.all()})

    def code_verification(self, user, code):
        return self.envoyer(user.email, 'TamBour - Code de verification', 'emails/code_verification.html', {'user': user, 'code': code})

    def reinitialisation_mot_de_passe(self, user, code):
        return self.envoyer(user.email, 'TamBour - Reinitialisation mot de passe', 'emails/reinit_mdp.html', {'user': user, 'code': code})


class NotificationService:
    """Cree des notifications in-app."""

    @staticmethod
    def creer(user, type_notif, titre, message, reservation_id=None, trajet_id=None, metadata=None):
        from .models import Notification
        return Notification.objects.create(user=user, type_notif=type_notif, titre=titre, message=message, reservation_id=reservation_id, trajet_id=trajet_id, metadata=metadata or {})

    @staticmethod
    def confirmation_reservation(user, reservation):
        return NotificationService.creer(user=user, type_notif='confirmation', titre='Réservation confirmée !', message=f'Votre billet {reservation.reference} pour {reservation.trajet.ligne.depart.nom} → {reservation.trajet.ligne.arrivee.nom} est confirmé.', reservation_id=reservation.id, trajet_id=reservation.trajet.id)

    @staticmethod
    def rappel_voyage(user, reservation):
        return NotificationService.creer(user=user, type_notif='rappel', titre='Départ dans 2 heures', message=f'Votre bus {reservation.trajet.ligne.depart.nom} → {reservation.trajet.ligne.arrivee.nom} part à {reservation.trajet.heure_depart.strftime("%H:%M")}. Soyez à la gare 30 min avant.', reservation_id=reservation.id, trajet_id=reservation.trajet.id)

    @staticmethod
    def alerte_retard(user, reservation, retard_minutes):
        return NotificationService.creer(user=user, type_notif='retard', titre='Retard signalé', message=f'Le bus {reservation.trajet.ligne.depart.nom} → {reservation.trajet.ligne.arrivee.nom} accuse un retard de {retard_minutes} minutes.', reservation_id=reservation.id, trajet_id=reservation.trajet.id, metadata={'retard_minutes': retard_minutes})
