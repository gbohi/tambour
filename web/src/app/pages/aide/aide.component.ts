import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService, messageErreur } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { CategorieFAQ, InfosContact } from '../../core/models';
import { IconComponent } from '../../shared/components/icon/icon.component';

const CATEGORIES_RECLAMATION = [
  ['paiement', 'Problème de paiement'], ['billet', 'Billet non reçu ou invalide'], ['remboursement', 'Annulation / remboursement'],
  ['retard', 'Retard ou annulation du car'], ['bagage', 'Bagage perdu ou endommagé'], ['service', 'Accueil ou comportement du personnel'], ['autre', 'Autre'],
];

@Component({
  selector: 'tb-aide',
  standalone: true,
  imports: [FormsModule, RouterLink, IconComponent],
  template: `
    <section class="tete">
      <div class="conteneur centre">
        <span class="surtitre">Centre d'aide</span>
        <h1 class="titre-section">Comment pouvons-nous vous aider ?</h1>
        <div class="recherche"><tb-icon name="search" [size]="20" />
          <input class="entree" placeholder="Paiement, billet, remboursement, points…" [value]="filtre()" (input)="filtre.set($any($event.target).value)"></div>
      </div>
    </section>

    <div class="conteneur corps">
      <div class="faq">
        @for (c of filtrees(); track c.code) {
          <div class="categorie">
            <h2>{{ c.label }}</h2>
            @for (q of c.questions; track q.id) {
              <details><summary>{{ q.question }}<tb-icon name="chevron-down" [size]="20" /></summary><p>{{ q.reponse }}</p></details>
            }
          </div>
        } @empty {
          <div class="vide"><div class="icone-vide"><tb-icon name="search" [size]="28" /></div><h3>Aucune réponse trouvée</h3><p>Écrivez-nous, nous vous répondons rapidement.</p></div>
        }
      </div>

      <section id="contact" class="bloc">
        <div class="bloc-tete"><h2>Contacter le support</h2><p class="muted">{{ infos()?.horaires ?? 'Tous les jours, 6h – 22h' }}</p></div>
        <div class="canaux">
          <a class="canal" [href]="'tel:' + (infos()?.telephone ?? '').replace(' ', '')"><span class="ico"><tb-icon name="phone" /></span><div><b>Appeler</b><small>{{ infos()?.telephone }}</small></div></a>
          <a class="canal" [href]="'https://wa.me/' + (infos()?.whatsapp ?? '').replace('+', '')" target="_blank" rel="noopener"><span class="ico wa"><tb-icon name="message" /></span><div><b>WhatsApp</b><small>Réponse rapide</small></div></a>
          <a class="canal" [href]="'mailto:' + infos()?.email"><span class="ico or"><tb-icon name="mail" /></span><div><b>Email</b><small>{{ infos()?.email }}</small></div></a>
        </div>
        <form class="carte form" (ngSubmit)="envoyerMessage()">
          <h3>Écrivez-nous</h3>
          @if (!auth.connecte()) {
            <div class="ligne-champs">
              <div class="champ"><label>Nom complet</label><input class="entree" name="nom" [(ngModel)]="message.nom"></div>
              <div class="champ"><label>Email ou téléphone</label><input class="entree" name="contact" [(ngModel)]="contactLibre"></div>
            </div>
          }
          <div class="champ"><label>Sujet</label><input class="entree" name="sujet" [(ngModel)]="message.sujet" placeholder="Ex. : modifier ma réservation"></div>
          <div class="champ"><label>Message</label><textarea class="entree" rows="4" name="msg" [(ngModel)]="message.message"></textarea></div>
          <button class="btn btn-primaire" [disabled]="envoi()"><tb-icon name="send" [size]="18" /> Envoyer</button>
        </form>
      </section>

      <section id="reclamation" class="bloc">
        <div class="bloc-tete"><h2>Faire une réclamation</h2><p class="muted">Un problème avec un voyage, un paiement ou un billet ? Nous revenons vers vous sous 48 h.</p></div>
        @if (auth.connecte()) {
          <form class="carte form" (ngSubmit)="reclamer()">
            <div class="champ"><label>Motif</label>
              <div class="motifs">
                @for (c of categories; track c[0]) {
                  <button type="button" class="motif" [class.actif]="reclamation.categorie === c[0]" (click)="reclamation.categorie = c[0]">{{ c[1] }}</button>
                }
              </div></div>
            <div class="ligne-champs">
              <div class="champ"><label>Référence de réservation <span class="hint">(facultatif)</span></label>
                <input class="entree mono" name="ref" [(ngModel)]="reclamation.reference_reservation" placeholder="TB202610123456"></div>
              <div class="champ"><label>Objet</label><input class="entree" name="obj" [(ngModel)]="reclamation.sujet"></div>
            </div>
            <div class="champ"><label>Que s'est-il passé ?</label><textarea class="entree" rows="5" name="desc" [(ngModel)]="reclamation.description"></textarea></div>
            <button class="btn btn-primaire" [disabled]="envoi()"><tb-icon name="send" [size]="18" /> Envoyer la réclamation</button>
          </form>
        } @else {
          <div class="carte connexion">
            <p>Connectez-vous pour déposer une réclamation et suivre son traitement.</p>
            <a class="btn btn-primaire" routerLink="/connexion" [queryParams]="{ retour: '/aide#reclamation' }">Se connecter</a>
          </div>
        }
      </section>
    </div>
  `,
  styles: [`
    .tete{background:linear-gradient(165deg,#072A21,#0F4A3B);color:#fff;padding:64px 0 56px;}
    .centre{text-align:center;display:flex;flex-direction:column;align-items:center;}
    .tete .surtitre{color:var(--or);}
    .recherche{position:relative;width:100%;max-width:620px;margin-top:16px;color:var(--texte);}
    .recherche tb-icon{position:absolute;left:18px;top:50%;transform:translateY(-50%);color:var(--texte-3);}
    .recherche .entree{padding-left:50px;height:60px;border-radius:999px;font-size:17px;border:none;box-shadow:var(--ombre-3);}
    .corps{padding-top:40px;padding-bottom:40px;display:flex;flex-direction:column;gap:56px;}
    .faq{display:grid;grid-template-columns:repeat(2,1fr);gap:28px;}
    @media (max-width:860px){.faq{grid-template-columns:1fr;}}
    .categorie h2{font-size:18px;margin-bottom:12px;}
    details{border:1px solid var(--bord);border-radius:var(--r);background:#fff;margin-bottom:8px;}
    summary{list-style:none;cursor:pointer;padding:16px 18px;font-weight:600;display:flex;justify-content:space-between;gap:12px;align-items:center;}
    summary::-webkit-details-marker{display:none;}
    summary tb-icon{color:var(--texte-3);transition:transform .2s;flex-shrink:0;}
    details[open] summary tb-icon{transform:rotate(180deg);}
    details p{padding:0 18px 16px;color:var(--texte-2);}
    .bloc{display:flex;flex-direction:column;gap:18px;scroll-margin-top:96px;}
    .bloc-tete h2{font-size:28px;font-weight:800;letter-spacing:-.02em;}
    .canaux{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;}
    @media (max-width:760px){.canaux{grid-template-columns:1fr;}}
    .canal{display:flex;align-items:center;gap:14px;padding:18px;border-radius:var(--r-lg);background:#fff;border:1px solid var(--bord);transition:all .2s;}
    .canal:hover{box-shadow:var(--ombre-2);border-color:transparent;}
    .canal div{display:flex;flex-direction:column;} .canal small{color:var(--texte-2);font-size:14px;}
    .ico{width:48px;height:48px;border-radius:14px;background:var(--vert-clair);color:var(--vert);display:flex;align-items:center;justify-content:center;}
    .ico.wa{background:#E7F9EE;color:#1FA855;} .ico.or{background:var(--or-clair);color:var(--or-fonce);}
    .form{display:flex;flex-direction:column;gap:16px;}
    .form .btn{align-self:flex-start;}
    .form h3{font-size:20px;}
    .motifs{display:flex;flex-wrap:wrap;gap:8px;}
    .motif{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:9px 14px;font-weight:600;font-size:14px;cursor:pointer;color:var(--texte-2);}
    .motif:hover{border-color:var(--vert);color:var(--vert);}
    .motif.actif{background:var(--vert);border-color:var(--vert);color:#fff;}
    .connexion{display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;}
  `],
})
export class AideComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private toast = inject(ToastService);

  readonly categories = CATEGORIES_RECLAMATION;
  faq = signal<CategorieFAQ[]>([]);
  infos = signal<InfosContact | null>(null);
  filtre = signal('');
  envoi = signal(false);
  message = { nom: '', sujet: '', message: '' };
  contactLibre = '';
  reclamation = { categorie: '', sujet: '', description: '', reference_reservation: '' };

  filtrees = computed(() => {
    const q = this.filtre().toLowerCase().trim();
    if (!q) return this.faq();
    return this.faq().map(c => ({ ...c, questions: c.questions.filter(x => `${x.question} ${x.reponse}`.toLowerCase().includes(q)) }))
      .filter(c => c.questions.length);
  });

  ngOnInit(): void {
    this.api.faq().subscribe({ next: f => this.faq.set(f), error: () => {} });
    this.api.contact().subscribe({ next: i => this.infos.set(i), error: () => {} });
  }

  envoyerMessage(): void {
    const m = this.message;
    if (m.sujet.trim().length < 3 || m.message.trim().length < 10) { this.toast.erreur('Indiquez un sujet et un message (10 caractères minimum).'); return; }
    const contact = this.contactLibre.trim();
    const corps = this.auth.connecte() ? { sujet: m.sujet, message: m.message }
      : { ...m, ...(contact.includes('@') ? { email: contact } : { telephone: contact }) };
    this.envoi.set(true);
    this.api.envoyerMessage(corps).subscribe({
      next: r => { this.envoi.set(false); this.toast.succes(r.message); this.message = { nom: '', sujet: '', message: '' }; this.contactLibre = ''; },
      error: e => { this.envoi.set(false); this.toast.erreur(messageErreur(e)); },
    });
  }

  reclamer(): void {
    const r = this.reclamation;
    if (!r.categorie) { this.toast.erreur('Choisissez un motif.'); return; }
    if (r.sujet.trim().length < 3 || r.description.trim().length < 20) { this.toast.erreur('Décrivez le problème (20 caractères minimum).'); return; }
    this.envoi.set(true);
    this.api.reclamer({ ...r, reference_reservation: r.reference_reservation.trim().toUpperCase() }).subscribe({
      next: res => { this.envoi.set(false); this.toast.succes(res.message); this.reclamation = { categorie: '', sujet: '', description: '', reference_reservation: '' }; },
      error: e => { this.envoi.set(false); this.toast.erreur(messageErreur(e)); },
    });
  }
}
