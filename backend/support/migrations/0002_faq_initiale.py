from django.db import migrations

FAQ = [
    ('reservation', 'Comment réserver un billet ?',
     "Sur l'accueil, choisissez votre ville de départ, d'arrivée, la date et le nombre de passagers, puis "
     "« Rechercher un trajet ». Sélectionnez un départ, renseignez les passagers et payez par Mobile Money "
     "ou carte. Vos billets arrivent aussitôt dans « Mes billets »."),
    ('reservation', 'Puis-je choisir mon siège ?',
     "Les sièges sont attribués automatiquement parmi les places disponibles au moment de la réservation. "
     "Les passagers d'une même réservation sont placés le plus près possible les uns des autres."),
    ('reservation', 'Combien de passagers par réservation ?',
     "Jusqu'à 9 passagers par réservation. Chaque passager reçoit son propre billet avec un QR code."),
    ('paiement', 'Quels moyens de paiement sont acceptés ?',
     'MTN Mobile Money, Orange Money, Wave et carte bancaire.'),
    ('paiement', "J'ai été débité mais je n'ai pas reçu mon billet",
     "Patientez quelques minutes puis ouvrez « Mes billets ». Si le billet n'apparaît toujours pas, faites une "
     "réclamation depuis « Mon compte » › « Faire une réclamation » en choisissant « Problème de paiement »."),
    ('billet', 'Comment embarquer ?',
     "Présentez le QR code de votre billet (dans « Mes billets ») au contrôleur à la gare, au moins 30 minutes "
     "avant le départ. Le billet peut aussi être présenté imprimé ou en PDF."),
    ('annulation', 'Comment annuler une réservation ?',
     "Ouvrez « Mes billets », choisissez la réservation puis « Annuler ». Les conditions de remboursement "
     "dépendent du délai avant le départ et de la compagnie."),
    ('fidelite', 'Comment gagner des points de fidélité ?',
     "Vous gagnez des points à chaque voyage payé, et en parrainant vos amis : vous et votre ami recevez des "
     "points dès qu'il s'inscrit avec votre code."),
    ('fidelite', 'Où trouver mon code de parrainage ?',
     "Dans « Mon compte » › « Programme fidélité ». Partagez-le à vos amis : ils le saisissent lors de leur "
     "inscription."),
    ('compte', 'Comment modifier mes informations ?',
     "Dans « Mon compte » › « Modifier mon profil »."),
]


def creer_faq(apps, schema_editor):
    QuestionFAQ = apps.get_model('support', 'QuestionFAQ')
    for ordre, (categorie, question, reponse) in enumerate(FAQ):
        QuestionFAQ.objects.get_or_create(question=question, defaults={
            'categorie': categorie, 'reponse': reponse, 'ordre': ordre})


class Migration(migrations.Migration):
    dependencies = [('support', '0001_initial')]
    operations = [migrations.RunPython(creer_faq, migrations.RunPython.noop)]
