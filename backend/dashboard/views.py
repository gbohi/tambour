from datetime import timedelta

from django.utils import timezone
from django.db.models import Sum, Count
from django.db.models.functions import Concat
from django.db.models import Value

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from authentication.permissions import EstAdminOuSupport
from tambour_backend.utils import success_response


class DashboardStatsView(APIView):
    """
    GET /api/v1/dashboard/stats/
    Statistiques en temps réel pour le tableau de bord admin.
    Accès : admin, support uniquement.
    """
    permission_classes = [IsAuthenticated, EstAdminOuSupport]

    def get(self, request):
        from authentication.models import User
        from transport.models import Trajet
        from reservations.models import Reservation
        from paiements.models import Paiement

        now          = timezone.now()
        today_start  = now.replace(hour=0, minute=0, second=0, microsecond=0)
        yesterday    = today_start - timedelta(days=1)
        week_start   = today_start - timedelta(days=7)
        month_start  = today_start.replace(day=1)

        # ── Réservations ────────────────────────────────────────────
        res_today = Reservation.objects.filter(
            created_at__gte=today_start,
            statut__in=['confirmee', 'en_attente']
        ).count()

        res_hier = Reservation.objects.filter(
            created_at__gte=yesterday,
            created_at__lt=today_start,
            statut__in=['confirmee', 'en_attente']
        ).count()

        res_week = Reservation.objects.filter(
            created_at__gte=week_start,
            statut__in=['confirmee', 'en_attente']
        ).count()

        # Réservations par jour sur 7 jours (du plus ancien au plus récent)
        res_par_jour = []
        for i in range(6, -1, -1):
            d = today_start - timedelta(days=i)
            n = Reservation.objects.filter(
                created_at__gte=d,
                created_at__lt=d + timedelta(days=1),
                statut__in=['confirmee', 'en_attente']
            ).count()
            res_par_jour.append(n)

        # ── Chiffre d'affaires ──────────────────────────────────────
        ca_mois = Paiement.objects.filter(
            statut='succes',
            confirme_le__gte=month_start
        ).aggregate(t=Sum('montant'))['t'] or 0

        mois_prec_fin   = month_start - timedelta(seconds=1)
        mois_prec_debut = mois_prec_fin.replace(day=1)
        ca_prec = Paiement.objects.filter(
            statut='succes',
            confirme_le__gte=mois_prec_debut,
            confirme_le__lte=mois_prec_fin
        ).aggregate(t=Sum('montant'))['t'] or 0

        delta_ca = (
            round((ca_mois - ca_prec) / ca_prec * 100)
            if ca_prec else 0
        )

        # ── Voyageurs ───────────────────────────────────────────────
        total_voyageurs  = User.objects.filter(role='voyageur', is_active=True).count()
        nouveaux_semaine = User.objects.filter(
            role='voyageur', date_joined__gte=week_start).count()

        # ── Trajets ─────────────────────────────────────────────────
        trajets_today = Trajet.objects.filter(
            heure_depart__gte=today_start,
            heure_depart__lt=today_start + timedelta(days=1)
        ).count()

        trajets_planifies = Trajet.objects.filter(
            heure_depart__gte=now,
            heure_depart__lt=today_start + timedelta(days=1),
            statut='planifie'
        ).count()

        # ── Paiements en attente ────────────────────────────────────
        paiements_attente = Paiement.objects.filter(
            statut__in=['initie', 'en_attente']
        ).count()

        # ── Taux remplissage moyen (7 derniers jours) ───────────────
        trajets_recents = list(
            Trajet.objects.filter(
                heure_depart__gte=week_start,
                heure_depart__lt=now
            ).select_related('bus')
        )
        taux = 0
        if trajets_recents:
            totaux = [
                (t.bus.capacite - t.sieges.filter(statut='libre').count()) / t.bus.capacite * 100
                for t in trajets_recents
                if t.bus and t.bus.capacite > 0
            ]
            taux = round(sum(totaux) / len(totaux)) if totaux else 0

        # ── Top lignes du mois ──────────────────────────────────────
        top_lignes_qs = (
            Reservation.objects
            .filter(created_at__gte=month_start, statut__in=['confirmee', 'en_attente'])
            .annotate(
                ligne=Concat(
                    'trajet__ligne__depart__nom',
                    Value(' > '),
                    'trajet__ligne__arrivee__nom',
                )
            )
            .values('ligne')
            .annotate(count=Count('id'))
            .order_by('-count')[:5]
        )
        top_lignes = [{'ligne': r['ligne'], 'count': r['count']} for r in top_lignes_qs]

        # ── Méthodes de paiement du mois ────────────────────────────
        methodes_qs = (
            Paiement.objects
            .filter(statut='succes', confirme_le__gte=month_start)
            .values('methode')
            .annotate(montant=Sum('montant'))
            .order_by('-montant')
        )
        methodes_paiement = [
            {'methode': m['methode'], 'montant': m['montant'] or 0}
            for m in methodes_qs
        ]

        return success_response(data={
            # KPI principaux
            'reservations_today':         res_today,
            'reservations_week':          res_week,
            'delta_reservations_hier':    res_today - res_hier,
            'chiffre_affaires_mois':      int(ca_mois),
            'delta_ca_mois_precedent':    delta_ca,
            'total_voyageurs':            total_voyageurs,
            'nouveaux_voyageurs_semaine': nouveaux_semaine,
            'trajets_today':              trajets_today,
            'trajets_planifies':          trajets_planifies,
            'paiements_en_attente':       paiements_attente,
            'taux_remplissage_moyen':     taux,
            # Graphiques
            'reservations_par_jour':      res_par_jour,
            'top_lignes':                 top_lignes,
            'methodes_paiement':          methodes_paiement,
        })
