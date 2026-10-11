import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, RouterLink, RouterLinkActive } from '@angular/router';
import { map } from 'rxjs';
import { IconComponent } from '../../shared/components/icon/icon.component';

interface Section { titre?: string; texte?: string; points?: string[]; }
interface PageInfo { titre: string; groupe: string; intro: string; sections: Section[]; action?: { libelle: string; lien: string; fragment?: string }; }

const PAGES: Record<string, PageInfo> = {
  'a-propos': {
    titre: 'À propos de TamBour', groupe: 'TamBour',
    intro: "TamBour rassemble les compagnies de car de Côte d'Ivoire sur une seule plateforme pour rendre le voyage interurbain simple, sûr et moderne.",
    sections: [
      { titre: 'Notre mission', texte: "Permettre à chacun de comparer les départs, de réserver en deux minutes et de voyager avec un billet sur son téléphone, sans file d'attente à la gare." },
      { titre: 'Ce que nous proposons', points: ['Les horaires et les prix de plusieurs compagnies au même endroit', 'Le paiement par Orange Money, Wave, MTN MoMo, Moov Money ou carte bancaire', 'Un billet avec QR code, contrôlé par le chauffeur à l\'embarquement', 'Un programme de fidélité et de parrainage'] },
      { titre: 'Nos valeurs', texte: 'Transparence des prix, ponctualité, sécurité des voyageurs et service client joignable 7 jours sur 7.' },
    ],
  },
  conditions: {
    titre: 'Conditions générales de vente', groupe: 'Légal',
    intro: 'Les présentes conditions régissent la vente de billets de car sur le site et l\'application TamBour.',
    sections: [
      { titre: '1. Réservation', texte: 'La réservation est ferme dès la confirmation du paiement. Un billet nominatif avec QR code est émis pour chaque passager.' },
      { titre: '2. Prix et paiement', texte: 'Les prix sont indiqués en francs CFA, toutes taxes comprises. Le paiement s\'effectue par Mobile Money ou carte bancaire via un prestataire sécurisé.' },
      { titre: '3. Annulation et remboursement', texte: 'L\'annulation est possible depuis votre compte jusqu\'à 2 heures avant le départ, selon les conditions de la compagnie. Le remboursement est effectué sur le moyen de paiement utilisé.' },
      { titre: '4. Responsabilité', texte: 'Le transport est exécuté par la compagnie partenaire indiquée sur le billet, qui en assume la responsabilité.' },
    ],
  },
  transport: {
    titre: 'Conditions de transport', groupe: 'Légal',
    intro: 'Les règles à connaître avant de monter à bord.',
    sections: [
      { titre: 'Embarquement', points: ['Présentez-vous à la gare 30 minutes avant le départ', 'Présentez le QR code de votre billet au chauffeur, sur téléphone ou imprimé', 'Une pièce d\'identité peut vous être demandée'] },
      { titre: 'À bord', points: ['Votre siège est attribué automatiquement et indiqué sur le billet', 'Il est interdit de fumer et de transporter des matières dangereuses', 'Les enfants de moins de 12 ans voyagent accompagnés'] },
    ],
  },
  partenaires: {
    titre: 'Devenir compagnie partenaire', groupe: 'TamBour',
    intro: 'Vous êtes une compagnie de transport ? Vendez vos billets en ligne et remplissez vos cars.',
    sections: [
      { titre: 'Les avantages', points: ['Visibilité auprès de milliers de voyageurs', 'Encaissement Mobile Money sans effort', 'Tableau de bord : trajets, réservations, remplissage, revenus', 'L\'application TamBour Pro pour contrôler les billets'] },
      { titre: 'Comment faire ?', texte: 'Contactez notre équipe commerciale : nous configurons vos lignes, vos cars et vos tarifs avec vous.' },
    ],
    action: { libelle: 'Nous contacter', lien: '/aide', fragment: 'contact' },
  },
  chauffeurs: {
    titre: 'Devenez chauffeur TamBour', groupe: 'TamBour',
    intro: 'Rejoignez les équipes de nos compagnies partenaires.',
    sections: [
      { titre: 'Le profil recherché', points: ['Permis D en cours de validité', 'Expérience du transport de voyageurs', 'Sens du service et de la sécurité'] },
      { titre: 'Vos outils', texte: 'Avec l\'application TamBour Pro, vous voyez vos trajets du jour, la liste des passagers, scannez les billets et clôturez le trajet à l\'arrivée.' },
    ],
    action: { libelle: 'Envoyer ma candidature', lien: '/aide', fragment: 'contact' },
  },
  reserver: {
    titre: 'Comment réserver un billet de car ?', groupe: 'Service client',
    intro: 'Votre billet en 3 étapes, en moins de deux minutes.',
    sections: [
      { titre: '1. Recherchez', texte: 'Indiquez votre ville de départ, d\'arrivée, la date et le nombre de passagers, puis comparez les départs : horaires, prix, confort et avis.' },
      { titre: '2. Payez', texte: 'Renseignez les voyageurs et payez par Orange Money, Wave, MTN MoMo, Moov Money ou carte bancaire. Les sièges sont attribués automatiquement, côte à côte.' },
      { titre: '3. Embarquez', texte: 'Vos billets apparaissent dans « Mes billets ». Présentez le QR code au chauffeur à l\'embarquement.' },
    ],
    action: { libelle: 'Rechercher un trajet', lien: '/' },
  },
  bagages: {
    titre: 'Bagages à bord', groupe: 'Service client',
    intro: 'Ce que vous pouvez emporter avec vous.',
    sections: [
      { points: ['1 bagage en soute (20 kg maximum) inclus', '1 bagage à main qui tient sous le siège ou dans le porte-bagages', 'Les bagages supplémentaires sont acceptés selon la place disponible, avec un supplément payé à la gare', 'Étiquetez vos bagages avec votre nom et votre téléphone'] },
    ],
  },
  confidentialite: {
    titre: 'Politique de confidentialité', groupe: 'Légal',
    intro: 'Comment TamBour protège vos données personnelles.',
    sections: [
      { titre: 'Données collectées', texte: 'Nom, prénom, téléphone, email, historique de réservations et de paiements, et votre position uniquement si vous demandez un itinéraire vers une gare.' },
      { titre: 'Utilisation', texte: 'Émettre vos billets, vous envoyer les informations de voyage, gérer votre fidélité et améliorer le service. Vos données ne sont jamais revendues.' },
      { titre: 'Vos droits', texte: 'Vous pouvez accéder à vos données, les corriger ou demander leur suppression en contactant le support.' },
    ],
  },
  'droits-passagers': {
    titre: 'Droits des passagers', groupe: 'Légal',
    intro: 'En cas de retard ou d\'annulation, vous êtes informé et accompagné.',
    sections: [
      { points: ['Information par notification et SMS en cas de retard ou d\'annulation', 'Remboursement intégral si la compagnie annule le trajet', 'Possibilité de réclamation depuis le centre d\'aide, avec réponse sous 48 h'] },
    ],
    action: { libelle: 'Faire une réclamation', lien: '/aide', fragment: 'reclamation' },
  },
  'mentions-legales': {
    titre: 'Mentions légales', groupe: 'Légal',
    intro: 'Informations sur l\'éditeur du service.',
    sections: [
      { titre: 'Éditeur', texte: 'TamBour, Abidjan, Côte d\'Ivoire. Contact : via le centre d\'aide.' },
      { titre: 'Hébergement', texte: 'Le service est hébergé par un prestataire d\'hébergement cloud.' },
      { titre: 'Propriété intellectuelle', texte: 'Les marques, logos et contenus du site sont la propriété de TamBour ou de ses partenaires.' },
    ],
  },
  cookies: {
    titre: 'Cookies', groupe: 'Légal',
    intro: 'TamBour utilise uniquement le stockage nécessaire au fonctionnement du site.',
    sections: [
      { texte: 'Nous conservons dans votre navigateur votre session de connexion et votre réservation en cours. Aucun cookie publicitaire n\'est déposé.' },
    ],
  },
};

@Component({
  selector: 'tb-infos',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, IconComponent],
  template: `
    @if (page(); as p) {
      <section class="tete"><div class="conteneur"><span class="surtitre">{{ p.groupe }}</span><h1>{{ p.titre }}</h1><p>{{ p.intro }}</p></div></section>
      <div class="conteneur corps">
        <nav class="menu">
          @for (e of menu; track e.cle) { <a [routerLink]="['/infos', e.cle]" routerLinkActive="actif">{{ e.titre }}</a> }
        </nav>
        <article class="carte texte">
          @for (s of p.sections; track $index) {
            <section>
              @if (s.titre) { <h2>{{ s.titre }}</h2> }
              @if (s.texte) { <p>{{ s.texte }}</p> }
              @if (s.points) { <ul>@for (pt of s.points; track pt) { <li><tb-icon name="check-circle" [size]="18" />{{ pt }}</li> }</ul> }
            </section>
          }
          @if (p.action; as a) { <a class="btn btn-primaire" [routerLink]="a.lien" [fragment]="a.fragment">{{ a.libelle }} <tb-icon name="arrow-right" [size]="18" /></a> }
        </article>
      </div>
    }
  `,
  styles: [`
    .tete{background:linear-gradient(165deg,#072A21,#0F4A3B);color:#fff;padding:56px 0 48px;}
    .tete .surtitre{color:var(--or);}
    h1{font-size:clamp(30px,4vw,44px);font-weight:900;letter-spacing:-.03em;margin:6px 0 10px;}
    .tete p{max-width:640px;color:rgba(255,255,255,.85);font-size:17px;}
    .corps{display:grid;grid-template-columns:260px minmax(0,1fr);gap:28px;padding-top:36px;padding-bottom:40px;align-items:start;}
    @media (max-width:860px){.corps{grid-template-columns:1fr;}.menu{display:none !important;}}
    .menu{display:flex;flex-direction:column;gap:2px;position:sticky;top:96px;}
    .menu a{padding:10px 14px;border-radius:12px;font-weight:600;color:var(--texte-2);font-size:15px;}
    .menu a:hover{background:var(--surface-2);color:var(--texte);}
    .menu a.actif{background:var(--vert-clair);color:var(--vert);}
    .texte{display:flex;flex-direction:column;gap:24px;padding:32px;}
    @media (max-width:560px){.texte{padding:22px;}}
    h2{font-size:20px;font-weight:800;margin-bottom:8px;}
    p{color:var(--texte-2);line-height:1.65;}
    ul{list-style:none;display:flex;flex-direction:column;gap:10px;}
    li{display:flex;gap:10px;align-items:flex-start;color:var(--texte-2);}
    li tb-icon{color:var(--vert);flex-shrink:0;margin-top:2px;}
    .btn{align-self:flex-start;}
  `],
})
export class InfosComponent {
  private route = inject(ActivatedRoute);
  private cle = toSignal(this.route.paramMap.pipe(map(p => p.get('page') ?? 'a-propos')), { initialValue: 'a-propos' });
  page = computed(() => PAGES[this.cle()] ?? PAGES['a-propos']);
  readonly menu = Object.entries(PAGES).map(([cle, p]) => ({ cle, titre: p.titre }));
}
