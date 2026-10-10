import csv
from django.http import HttpResponse
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from authentication.permissions import EstAdmin
from yobus_backend.utils import error_response


class ExportCsvView(APIView):
    """
    Export CSV des données — admin uniquement.
    GET /api/v1/rapports/export/?type=reservations&date_debut=2026-01-01&date_fin=2026-01-31
    Types : reservations | paiements | voyageurs | trajets
    """
    permission_classes = [IsAuthenticated, EstAdmin]

    TYPES_VALIDES = ['reservations', 'paiements', 'voyageurs', 'trajets']

    def get(self, request):
        type_export = request.query_params.get('type', '')
        date_debut  = request.query_params.get('date_debut', '')
        date_fin    = request.query_params.get('date_fin', '')

        if type_export not in self.TYPES_VALIDES:
            return error_response(
                f"Type invalide. Valeurs acceptées : {', '.join(self.TYPES_VALIDES)}")

        filename = f'yobus_{type_export}_{date_debut}_{date_fin}.csv'
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        response.write('\ufeff')  # BOM UTF-8 pour Excel

        writer = csv.writer(response)
        getattr(self, f'_export_{type_export}')(writer, date_debut, date_fin)
        return response

    def _export_reservations(self, writer, debut, fin):
        from reservations.models import Reservation
        writer.writerow([
            'Reference', 'Voyageur', 'Email', 'Trajet',
            'Heure depart', 'Passagers', 'Montant (FCFA)', 'Statut', 'Date creation',
        ])
        qs = Reservation.objects.select_related(
            'user', 'trajet__ligne__depart', 'trajet__ligne__arrivee'
        ).order_by('-created_at')
        if debut: qs = qs.filter(created_at__date__gte=debut)
        if fin:   qs = qs.filter(created_at__date__lte=fin)
        for r in qs:
            ligne = (f'{r.trajet.ligne.depart.nom} > {r.trajet.ligne.arrivee.nom}'
                     if r.trajet and r.trajet.ligne else '')
            writer.writerow([
                r.reference,
                r.user.nom_complet if r.user else '',
                r.user.email if r.user else '',
                ligne,
                r.trajet.heure_depart.strftime('%d/%m/%Y %H:%M') if r.trajet else '',
                r.nb_passagers,
                r.montant_total,
                r.get_statut_display(),
                r.created_at.strftime('%d/%m/%Y %H:%M'),
            ])

    def _export_paiements(self, writer, debut, fin):
        from paiements.models import Paiement
        writer.writerow([
            'Reference', 'Methode', 'Montant (FCFA)', 'Rembourse (FCFA)',
            'Telephone', 'Statut', 'Initie le', 'Confirme le',
        ])
        qs = Paiement.objects.order_by('-created_at')
        if debut: qs = qs.filter(created_at__date__gte=debut)
        if fin:   qs = qs.filter(created_at__date__lte=fin)
        for p in qs:
            writer.writerow([
                p.reference,
                p.get_methode_display(),
                p.montant,
                p.montant_rembourse,
                p.telephone,
                p.get_statut_display(),
                p.created_at.strftime('%d/%m/%Y %H:%M'),
                p.confirme_le.strftime('%d/%m/%Y %H:%M') if p.confirme_le else '',
            ])

    def _export_voyageurs(self, writer, debut, fin):
        from authentication.models import User
        writer.writerow([
            'Prenom', 'Nom', 'Email', 'Telephone',
            'Voyages', 'Points fidelite', 'Email verifie', 'Actif', 'Inscrit le',
        ])
        qs = User.objects.filter(role='voyageur').order_by('-date_joined')
        if debut: qs = qs.filter(date_joined__date__gte=debut)
        if fin:   qs = qs.filter(date_joined__date__lte=fin)
        for u in qs:
            writer.writerow([
                u.prenom, u.nom, u.email, u.telephone,
                u.nb_voyages, u.points_fidelite,
                'Oui' if u.is_verified else 'Non',
                'Oui' if u.is_active else 'Non',
                u.date_joined.strftime('%d/%m/%Y'),
            ])

    def _export_trajets(self, writer, debut, fin):
        from transport.models import Trajet
        writer.writerow([
            'Depart', 'Arrivee', 'Compagnie', 'Heure depart',
            'Prix (FCFA)', 'Classe', 'Capacite', 'Places dispo',
            'Taux remplissage (%)', 'Note moyenne', 'Statut',
        ])
        qs = Trajet.objects.select_related(
            'ligne__depart', 'ligne__arrivee', 'bus', 'transporteur'
        ).order_by('-heure_depart')
        if debut: qs = qs.filter(heure_depart__date__gte=debut)
        if fin:   qs = qs.filter(heure_depart__date__lte=fin)
        for t in qs:
            cap  = t.bus.capacite if t.bus else 0
            dispo = t.sieges.filter(statut='libre').count()
            taux = round((cap - dispo) / cap * 100) if cap > 0 else 0
            writer.writerow([
                t.ligne.depart.nom if t.ligne else '',
                t.ligne.arrivee.nom if t.ligne else '',
                t.transporteur.nom if t.transporteur else '',
                t.heure_depart.strftime('%d/%m/%Y %H:%M'),
                t.prix_actuel,
                t.bus.get_classe_display() if t.bus else '',
                cap, dispo, taux,
                t.note_moyenne,
                t.get_statut_display(),
            ])
