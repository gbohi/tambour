import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ApiService, messageErreur } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { Fidelite, Reservation } from '../../core/models';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { suiviDisponible } from '../../core/suivi';

type Onglet = 'billets' | 'fidelite' | 'profil';

@Component({
  selector: 'tb-compte',
  standalone: true,
  imports: [DatePipe, FormsModule, RouterLink, IconComponent, NombrePipe],
  template: `
    <section class="tete">
      <div class="conteneur tete-contenu">
        <div class="avatar">{{ auth.user()?.initiales }}</div>
        <div class="qui"><h1>{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</h1><p>{{ auth.user()?.email }}</p></div>
        <div class="chiffres">
          <div><b>{{ auth.user()?.points_fidelite | nb }}</b><span>points</span></div>
          <div><b>{{ auth.user()?.nb_voyages | nb }}</b><span>voyages</span></div>
        </div>
      </div>
      <div class="conteneur">
        <nav class="onglets">
          <button [class.actif]="onglet() === 'billets'" (click)="aller('billets')"><tb-icon name="ticket" [size]="18" /> Mes billets</button>
          <button [class.actif]="onglet() === 'fidelite'" (click)="aller('fidelite')"><tb-icon name="gift" [size]="18" /> Fidélité & parrainage</button>
          <button [class.actif]="onglet() === 'profil'" (click)="aller('profil')"><tb-icon name="user" [size]="18" /> Mon profil</button>
        </nav>
      </div>
    </section>

    <div class="conteneur corps">
      <!-- ── Billets ─────────────────────────────────────────────────────── -->
      @if (onglet() === 'billets') {
        <div class="segment" style="margin-bottom:20px">
          <button [class.actif]="periode() === 'a_venir'" (click)="periode.set('a_venir')">À venir ({{ aVenir().length }})</button>
          <button [class.actif]="periode() === 'passes'" (click)="periode.set('passes')">Passés ({{ passes().length }})</button>
        </div>
        @if (chargement()) {
          @for (i of [1,2]; track i) { <div class="squelette" style="height:150px;margin-bottom:14px;border-radius:20px"></div> }
        } @else {
          @for (r of (periode() === 'a_venir' ? aVenir() : passes()); track r.id) {
            <article class="resa">
              <div class="date"><b>{{ r.trajet_info.heure_depart | date:'d' }}</b><span>{{ r.trajet_info.heure_depart | date:'MMM' }}</span></div>
              <div class="infos">
                <div class="route">{{ r.trajet_info.depart }} <tb-icon name="arrow-right" [size]="18" /> {{ r.trajet_info.arrivee }}</div>
                <div class="muted">{{ r.trajet_info.heure_depart | date:'EEEE, HH:mm' }} · {{ r.trajet_info.compagnie }} · {{ r.nb_passagers }} passager{{ r.nb_passagers > 1 ? 's' : '' }}</div>
                <div class="pastilles">
                  <span class="pastille" [class]="'pastille ' + couleurStatut(r)">{{ libelleStatut(r) }}</span>
                  <span class="pastille mono">{{ r.reference }}</span>
                  @if (r.avis_note) { <span class="pastille or"><tb-icon name="star" [size]="13" /> Votre note : {{ r.avis_note }}/5</span> }
                </div>
              </div>
              <div class="actions">
                <span class="montant">{{ r.montant_total | nb:'F' }}</span>
                <div class="boutons">
                  @if (suiviDisponible(r)) { <a class="btn btn-or btn-sm" [routerLink]="['/suivi', r.trajet_info.id]"><tb-icon name="navigation" [size]="16" /> Suivre le car</a> }
                  @if (r.statut === 'confirmee') { <a class="btn btn-primaire btn-sm" [routerLink]="['/billets', r.id]"><tb-icon name="qr" [size]="16" /> Billets</a>
                    <button class="btn btn-contour btn-sm" (click)="pdf(r)" aria-label="Télécharger les billets en PDF"><tb-icon name="download" [size]="16" /> PDF</button> }
                  @if (r.peut_etre_notee) { <button class="btn btn-or btn-sm" (click)="ouvrirNote(r)"><tb-icon name="star" [size]="16" /> Noter</button> }
                  @if (r.peut_etre_annulee) { <button class="btn btn-contour btn-sm" (click)="aAnnuler.set(r)">Annuler</button> }
                </div>
              </div>
            </article>
          } @empty {
            <div class="carte vide"><div class="icone-vide"><tb-icon name="ticket" [size]="28" /></div>
              <h3>{{ periode() === 'a_venir' ? 'Aucun voyage prévu' : 'Aucun voyage passé' }}</h3>
              <p>Où allez-vous ensuite ?</p><a routerLink="/" class="btn btn-primaire btn-sm">Réserver un trajet</a></div>
          }
        }
      }

      <!-- ── Fidélité ────────────────────────────────────────────────────── -->
      @if (onglet() === 'fidelite') {
        @if (fidelite(); as f) {
          <div class="fid">
            <div class="solde">
              <span class="pastille or"><tb-icon name="star" [size]="14" /> Mes points</span>
              <b>{{ f.points | nb }}</b>
              <div class="mini"><span><b>{{ f.nb_voyages }}</b> voyages</span><span><b>{{ f.nb_filleuls }}</b> amis parrainés</span><span><b>{{ f.points_parrainage | nb }}</b> pts de parrainage</span></div>
            </div>
            <div class="code carte">
              <h3>Mon code de parrainage</h3>
              <p class="muted">Vous gagnez <b>{{ f.points_parrain }} points</b> par ami inscrit, et votre ami reçoit <b>{{ f.points_filleul }} points</b>.</p>
              <div class="code-boite"><span class="mono">{{ f.code_parrainage }}</span>
                <button class="btn btn-blanc btn-sm" (click)="copier(f.code_parrainage)"><tb-icon name="check" [size]="16" /> Copier</button></div>
              <div class="partage">
                <a class="btn btn-primaire" [href]="lienWhatsapp(f)" target="_blank" rel="noopener"><tb-icon name="message" [size]="18" /> Partager sur WhatsApp</a>
                <button class="btn btn-contour" (click)="copier(lienInvitation(f))">Copier le lien d'invitation</button>
              </div>
            </div>
          </div>
          <div class="etapes">
            @for (e of etapesInvitation(f); track e.titre; let i = $index) {
              <div class="etape"><span class="num">{{ i + 1 }}</span><div><b>{{ e.titre }}</b><p>{{ e.texte }}</p></div></div>
            }
          </div>
          <div class="carte historique">
            <h3>Historique des points</h3>
            @for (m of f.historique; track m.id) {
              <div class="mvt"><span class="ico"><tb-icon [name]="m.motif === 'voyage' ? 'bus' : m.motif === 'parrainage' ? 'users' : 'gift'" [size]="18" /></span>
                <div><b>{{ m.description || m.motif_label }}</b><small>{{ m.created_at | date:'d MMMM yyyy' }}</small></div>
                <span class="pts" [class.neg]="m.points < 0">{{ m.points > 0 ? '+' : '' }}{{ m.points | nb }}</span></div>
            } @empty { <p class="muted">Pas encore de points. Voyagez ou invitez un ami pour commencer !</p> }
          </div>
        } @else { <div class="squelette" style="height:320px;border-radius:24px"></div> }
      }

      <!-- ── Profil ──────────────────────────────────────────────────────── -->
      @if (onglet() === 'profil') {
        <div class="profil">
          <form class="carte form" (ngSubmit)="enregistrer()">
            <h3>Mes informations</h3>
            <div class="ligne-champs">
              <div class="champ"><label>Prénom</label><input class="entree" name="p" [(ngModel)]="profil.prenom"></div>
              <div class="champ"><label>Nom</label><input class="entree" name="n" [(ngModel)]="profil.nom"></div>
            </div>
            <div class="champ"><label>Téléphone</label><input class="entree" name="t" [(ngModel)]="profil.telephone"></div>
            <div class="champ"><label>Email</label><input class="entree" [value]="auth.user()?.email" disabled></div>
            <label class="interrupteur"><input type="checkbox" name="sms" [(ngModel)]="profil.notif_sms"> Alertes SMS (départ, retard)</label>
            <label class="interrupteur"><input type="checkbox" name="mail" [(ngModel)]="profil.notif_email"> Billets et reçus par email</label>
            <button class="btn btn-primaire" [disabled]="envoi()">Enregistrer</button>
          </form>
          <div class="carte aide">
            <h3>Besoin d'aide ?</h3>
            <a routerLink="/aide"><tb-icon name="info" [size]="18" /> Centre d'aide</a>
            <a routerLink="/aide" fragment="contact"><tb-icon name="headset" [size]="18" /> Contacter le support</a>
            <a routerLink="/aide" fragment="reclamation"><tb-icon name="alert" [size]="18" /> Faire une réclamation</a>
            <button class="btn btn-contour" (click)="deconnexion()"><tb-icon name="logout" [size]="18" /> Se déconnecter</button>
          </div>
        </div>
      }
    </div>

    <!-- Noter un trajet -->
    @if (aNoter(); as r) {
      <div class="voile" (click)="aNoter.set(null)">
        <div class="fenetre" (click)="$event.stopPropagation()">
          <div class="fenetre-tete"><div><h3>Comment s'est passé votre voyage ?</h3>
            <p class="muted">{{ r.trajet_info.depart }} → {{ r.trajet_info.arrivee }} · {{ r.trajet_info.compagnie }}</p></div>
            <button class="btn btn-icone btn-contour" (click)="aNoter.set(null)"><tb-icon name="x" /></button></div>
          <div class="fenetre-corps">
            <div class="etoiles grandes">
              @for (n of [1,2,3,4,5]; track n) { <button (click)="note.set(n)" [class.on]="n <= note()"><tb-icon name="star" [size]="34" /></button> }
            </div>
            @for (c of criteres; track c.code) {
              <div class="critere"><span>{{ c.label }}</span>
                <div class="etoiles">@for (n of [1,2,3,4,5]; track n) { <button (click)="noteCriteres[c.code] = n" [class.on]="n <= (noteCriteres[c.code] || 0)"><tb-icon name="star" [size]="20" /></button> }</div>
              </div>
            }
            <textarea class="entree" rows="3" [(ngModel)]="commentaire" placeholder="Racontez votre expérience (facultatif)"></textarea>
            <button class="btn btn-primaire btn-bloc" [disabled]="!note() || envoi()" (click)="envoyerNote()">Publier mon avis</button>
          </div>
        </div>
      </div>
    }

    <!-- Annuler -->
    @if (aAnnuler(); as r) {
      <div class="voile" (click)="aAnnuler.set(null)">
        <div class="fenetre" (click)="$event.stopPropagation()">
          <div class="fenetre-tete"><h3>Annuler cette réservation ?</h3><button class="btn btn-icone btn-contour" (click)="aAnnuler.set(null)"><tb-icon name="x" /></button></div>
          <div class="fenetre-corps">
            <p>{{ r.trajet_info.depart }} → {{ r.trajet_info.arrivee }}, {{ r.trajet_info.heure_depart | date:'EEEE d MMMM à HH:mm' }}.</p>
            <div class="alerte info"><tb-icon name="wallet" [size]="18" /> Remboursement prévu : <b>{{ r.montant_remboursable | nb:'F' }}</b> sur votre moyen de paiement.</div>
            <div class="boutons-fin">
              <button class="btn btn-contour" (click)="aAnnuler.set(null)">Garder ma réservation</button>
              <button class="btn btn-primaire" style="background:var(--danger)" [disabled]="envoi()" (click)="annuler(r)">Confirmer l'annulation</button>
            </div>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .tete{background:linear-gradient(165deg,#072A21,#0F4A3B);color:#fff;padding-top:36px;}
    .tete-contenu{display:flex;align-items:center;gap:20px;flex-wrap:wrap;}
    .avatar{width:72px;height:72px;border-radius:24px;background:var(--or);color:var(--encre);font-size:26px;font-weight:900;display:flex;align-items:center;justify-content:center;}
    .qui{flex:1;min-width:200px;}
    .qui h1{font-size:30px;font-weight:800;letter-spacing:-.03em;}
    .qui p{opacity:.75;}
    .chiffres{display:flex;gap:12px;}
    .chiffres div{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);border-radius:18px;padding:12px 18px;display:flex;flex-direction:column;min-width:110px;}
    .chiffres b{font-size:26px;font-weight:900;} .chiffres span{font-size:13px;opacity:.7;}
    .onglets{display:flex;gap:4px;margin-top:28px;overflow-x:auto;scrollbar-width:none;}
    @media (max-width:560px){.onglets button{padding:12px 12px;font-size:14px;gap:6px;}}
    .onglets button{display:inline-flex;align-items:center;gap:8px;border:none;background:none;color:rgba(255,255,255,.7);font-weight:700;padding:14px 18px;border-radius:14px 14px 0 0;cursor:pointer;white-space:nowrap;}
    .onglets button.actif{background:var(--fond);color:var(--texte);}
    .corps{padding-top:32px;padding-bottom:40px;}
    .resa{display:grid;grid-template-columns:auto 1fr auto;gap:20px;align-items:center;background:#fff;border:1px solid var(--bord);border-radius:22px;padding:20px;margin-bottom:14px;}
    @media (max-width:720px){.resa{grid-template-columns:auto 1fr;}.resa .actions{grid-column:1/-1;flex-direction:row;justify-content:space-between;align-items:center;}}
    .date{width:64px;height:68px;border-radius:16px;background:var(--vert-clair);color:var(--vert);display:flex;flex-direction:column;align-items:center;justify-content:center;}
    .date b{font-size:26px;font-weight:900;line-height:1;} .date span{font-size:13px;font-weight:700;text-transform:uppercase;}
    .route{display:flex;align-items:center;gap:8px;font-size:20px;font-weight:800;flex-wrap:wrap;}
    .route tb-icon{color:var(--or);}
    .infos .muted::first-letter{text-transform:uppercase;}
    .pastilles{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px;}
    .actions{display:flex;flex-direction:column;align-items:flex-end;gap:10px;}
    .actions .montant{font-size:20px;}
    .boutons{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end;}
    .fid{display:grid;grid-template-columns:1fr 1.4fr;gap:20px;}
    @media (max-width:860px){.fid{grid-template-columns:1fr;}}
    .solde{border-radius:var(--r-xl);padding:28px;background:linear-gradient(150deg,var(--encre),#14402F);color:#fff;display:flex;flex-direction:column;gap:12px;}
    .solde > b{font-size:60px;font-weight:900;letter-spacing:-.04em;line-height:1;color:var(--or);}
    .solde .pastille{align-self:flex-start;}
    .mini{display:flex;flex-wrap:wrap;gap:8px 18px;font-size:14px;opacity:.85;}
    .code{display:flex;flex-direction:column;gap:14px;}
    .code h3,.historique h3,.form h3,.aide h3{font-size:20px;font-weight:800;}
    .code-boite{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:14px 14px 14px 20px;border-radius:16px;border:2px dashed var(--or);background:var(--or-clair);}
    .code-boite .mono{font-size:26px;font-weight:800;letter-spacing:.2em;}
    .partage{display:flex;gap:10px;flex-wrap:wrap;}
    .etapes{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:20px 0;}
    @media (max-width:860px){.etapes{grid-template-columns:1fr;}}
    .etape{display:flex;gap:14px;padding:20px;border-radius:var(--r-lg);background:#fff;border:1px solid var(--bord);}
    .etape .num{width:36px;height:36px;border-radius:50%;background:var(--vert);color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .etape p{color:var(--texte-2);font-size:14px;}
    .historique{display:flex;flex-direction:column;gap:6px;}
    .mvt{display:flex;align-items:center;gap:14px;padding:12px 0;border-bottom:1px solid var(--bord);}
    .mvt:last-child{border-bottom:none;}
    .mvt .ico{width:40px;height:40px;border-radius:12px;background:var(--vert-clair);color:var(--vert);display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .mvt div{flex:1;display:flex;flex-direction:column;}
    .mvt small{color:var(--texte-3);font-size:13px;}
    .pts{font-weight:900;color:var(--vert);font-size:18px;} .pts.neg{color:var(--danger);}
    .profil{display:grid;grid-template-columns:1.5fr 1fr;gap:20px;align-items:start;}
    @media (max-width:860px){.profil{grid-template-columns:1fr;}}
    .form{display:flex;flex-direction:column;gap:16px;}
    .interrupteur{display:flex;align-items:center;gap:10px;font-weight:500;cursor:pointer;}
    .interrupteur input{accent-color:var(--vert);width:20px;height:20px;}
    .form .btn{align-self:flex-start;}
    .aide{display:flex;flex-direction:column;gap:8px;}
    .aide a{display:flex;align-items:center;gap:10px;padding:12px;border-radius:12px;font-weight:600;}
    .aide a:hover{background:var(--surface-2);color:var(--vert);}
    .aide .btn{margin-top:8px;}
    .etoiles{display:flex;gap:2px;}
    .etoiles button{border:none;background:none;cursor:pointer;color:var(--bord);padding:2px;}
    .etoiles button.on{color:var(--or);}
    .etoiles button.on ::ng-deep svg{fill:currentColor;}
    .grandes{justify-content:center;}
    .critere{display:flex;justify-content:space-between;align-items:center;font-weight:600;}
    .boutons-fin{display:flex;gap:10px;justify-content:flex-end;flex-wrap:wrap;}
  `],
})
export class CompteComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private toast = inject(ToastService);

  onglet = signal<Onglet>('billets');
  periode = signal<'a_venir' | 'passes'>('a_venir');
  reservations = signal<Reservation[]>([]);
  fidelite = signal<Fidelite | null>(null);
  chargement = signal(true);
  envoi = signal(false);
  aNoter = signal<Reservation | null>(null);
  aAnnuler = signal<Reservation | null>(null);
  note = signal(0);
  noteCriteres: Record<string, number> = {};
  commentaire = '';
  profil = { prenom: '', nom: '', telephone: '', notif_sms: true, notif_email: true };
  readonly criteres = [{ code: 'note_ponctualite', label: 'Ponctualité' }, { code: 'note_confort', label: 'Confort' }, { code: 'note_proprete', label: 'Propreté' }];

  private maintenant = Date.now();
  readonly suiviDisponible = (r: Reservation) => suiviDisponible(r, this.maintenant);
  /** Un trajet en route reste « à venir » jusqu'à l'arrivée. */
  private estAVenir(r: Reservation): boolean {
    return r.statut === 'confirmee' && (new Date(r.trajet_info.heure_depart).getTime() > this.maintenant || r.trajet_info.statut === 'en_cours');
  }
  aVenir = computed(() => this.reservations()
    .filter(r => this.estAVenir(r))
    .sort((a, b) => a.trajet_info.heure_depart.localeCompare(b.trajet_info.heure_depart)));
  passes = computed(() => this.reservations()
    .filter(r => !this.estAVenir(r) && r.statut !== 'en_attente' && r.statut !== 'expiree')
    .sort((a, b) => b.trajet_info.heure_depart.localeCompare(a.trajet_info.heure_depart)));

  ngOnInit(): void {
    this.route.queryParamMap.subscribe(q => {
      const o = q.get('onglet') as Onglet;
      this.onglet.set(['billets', 'fidelite', 'profil'].includes(o) ? o : 'billets');
      this.chargerOnglet();
    });
    const u = this.auth.user();
    if (u) this.profil = { prenom: u.prenom, nom: u.nom, telephone: u.telephone, notif_sms: u.notif_sms, notif_email: u.notif_email };
  }

  aller(o: Onglet): void { this.router.navigate([], { queryParams: { onglet: o } }); }

  private chargerOnglet(): void {
    if (this.onglet() === 'billets') {
      this.chargement.set(true);
      this.api.mesReservations().subscribe({
        next: r => { this.reservations.set(r); this.chargement.set(false); },
        error: () => { this.chargement.set(false); this.toast.erreur('Impossible de charger vos billets.'); },
      });
    }
    if (this.onglet() === 'fidelite') {
      this.api.fidelite().subscribe({ next: f => this.fidelite.set(f), error: () => this.toast.erreur('Impossible de charger votre programme fidélité.') });
    }
  }

  libelleStatut(r: Reservation): string {
    if (r.statut === 'confirmee') return r.trajet_info.statut === 'termine' || new Date(r.trajet_info.heure_depart).getTime() < this.maintenant ? 'Effectué' : 'Confirmé';
    return ({ annulee: 'Annulé', remboursee: 'Remboursé', expiree: 'Expiré', en_attente: 'En attente' } as Record<string, string>)[r.statut] ?? r.statut;
  }
  couleurStatut(r: Reservation): string {
    return r.statut === 'confirmee' ? 'vert' : r.statut === 'annulee' ? 'rouge' : r.statut === 'remboursee' ? 'bleu' : '';
  }

  ouvrirNote(r: Reservation): void { this.note.set(0); this.noteCriteres = {}; this.commentaire = ''; this.aNoter.set(r); }
  envoyerNote(): void {
    const r = this.aNoter();
    if (!r) return;
    this.envoi.set(true);
    this.api.noterTrajet(r.id, this.note(), this.commentaire, this.noteCriteres).subscribe({
      next: () => { this.envoi.set(false); this.aNoter.set(null); this.toast.succes('Merci ! Votre avis aide les autres voyageurs.'); this.chargerOnglet(); },
      error: e => { this.envoi.set(false); this.toast.erreur(messageErreur(e)); },
    });
  }

  annuler(r: Reservation): void {
    this.envoi.set(true);
    this.api.annulerReservation(r.id, 'Annulation par le voyageur (site web)').subscribe({
      next: () => { this.envoi.set(false); this.aAnnuler.set(null); this.toast.succes('Réservation annulée. Le remboursement est en cours.'); this.chargerOnglet(); },
      error: e => { this.envoi.set(false); this.toast.erreur(messageErreur(e, 'Annulation impossible.')); },
    });
  }

  enregistrer(): void {
    this.envoi.set(true);
    this.api.majProfil(this.profil).subscribe({
      next: u => { this.envoi.set(false); this.auth.majUser(u); this.toast.succes('Profil enregistré.'); },
      error: e => { this.envoi.set(false); this.toast.erreur(messageErreur(e)); },
    });
  }

  deconnexion(): void { this.auth.deconnexion(); this.router.navigate(['/']); this.toast.info('Vous êtes déconnecté.'); }

  lienInvitation(f: Fidelite): string { return `${location.origin}/connexion?mode=inscription&code=${f.code_parrainage}`; }
  lienWhatsapp(f: Fidelite): string { return 'https://wa.me/?text=' + encodeURIComponent(`${f.message_partage}\n${this.lienInvitation(f)}`); }
  copier(texte: string): void {
    navigator.clipboard?.writeText(texte).then(() => this.toast.succes('Copié !'), () => this.toast.erreur('Copie impossible.'));
  }
  etapesInvitation(f: Fidelite) {
    return [
      { titre: 'Invitez vos amis', texte: 'Partagez votre code par WhatsApp, SMS ou réseaux sociaux.' },
      { titre: 'Ils s\'inscrivent', texte: 'Vos amis téléchargent TamBour et saisissent votre code à l\'inscription.' },
      { titre: 'Vous êtes récompensés', texte: `${f.points_parrain} points pour vous, ${f.points_filleul} points de bienvenue pour votre ami.` },
    ];
  }

  async pdf(r: Reservation): Promise<void> {
    const { telechargerBilletsPdf } = await import('../../core/billet-pdf');
    await telechargerBilletsPdf(r);
  }
}
