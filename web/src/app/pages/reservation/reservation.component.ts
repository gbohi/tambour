import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { switchMap } from 'rxjs';
import { ApiService, messageErreur } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { MethodePaiement, PassagerSaisie, Trajet } from '../../core/models';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

const METHODES: { code: MethodePaiement; label: string; detail: string; couleur: string; texte: string }[] = [
  { code: 'orange_money', label: 'Orange Money', detail: 'Validation par code sur votre téléphone', couleur: '#FF7900', texte: '#fff' },
  { code: 'mtn_momo', label: 'MTN Mobile Money', detail: 'Validation par code sur votre téléphone', couleur: '#FFCB05', texte: '#1A1A1A' },
  { code: 'wave', label: 'Wave', detail: 'Confirmez dans l\'application Wave', couleur: '#1DC8F2', texte: '#fff' },
  { code: 'carte', label: 'Carte bancaire', detail: 'Visa, Mastercard — paiement sécurisé', couleur: '#1E293B', texte: '#fff' },
];

@Component({
  selector: 'tb-reservation',
  standalone: true,
  imports: [DatePipe, FormsModule, RouterLink, IconComponent, NombrePipe],
  template: `
    <div class="conteneur page">
      <a class="retour" (click)="retour()"><tb-icon name="arrow-left" [size]="18" /> Retour aux résultats</a>

      <ol class="etapes">
        <li [class.faite]="etape() > 1" [class.active]="etape() === 1"><span>1</span> Voyageurs</li>
        <li [class.active]="etape() === 2"><span>2</span> Paiement</li>
        <li><span>3</span> Billets</li>
      </ol>

      @if (erreurChargement()) {
        <div class="carte vide"><div class="icone-vide"><tb-icon name="alert" [size]="28" /></div>
          <h3>Ce départ n'est plus disponible</h3><p>{{ erreurChargement() }}</p>
          <a routerLink="/" class="btn btn-primaire btn-sm">Nouvelle recherche</a></div>
      } @else {
        <div class="disposition">
          <div class="principal">
            @if (etape() === 1) {
              <section class="carte">
                <h2>Qui voyage ?</h2>
                <p class="muted">Les billets sont nominatifs. Le premier voyageur reçoit les billets de tous les passagers.</p>
                @if (!auth.connecte()) {
                  <div class="alerte info"><tb-icon name="user" [size]="18" />
                    <span>Déjà client ? <a [routerLink]="'/connexion'" [queryParams]="{ retour: urlActuelle() }"><b>Connectez-vous</b></a> pour gagner des points sur ce voyage.</span></div>
                }
                @for (p of voyageurs; track i; let i = $index) {
                  <fieldset class="voyageur">
                    <legend><span class="num">{{ i + 1 }}</span> Passager {{ i + 1 }} @if (i === 0) { <span class="pastille vert">Contact</span> }</legend>
                    <div class="ligne-champs">
                      <div class="champ"><label>Prénom</label><input class="entree" [(ngModel)]="p.prenom" [name]="'prenom' + i" autocomplete="given-name" placeholder="Ex. : Aya"></div>
                      <div class="champ"><label>Nom</label><input class="entree" [(ngModel)]="p.nom" [name]="'nom' + i" autocomplete="family-name" placeholder="Ex. : Koné"></div>
                    </div>
                    <div class="ligne-champs">
                      <div class="champ"><label>Téléphone</label><input class="entree" type="tel" [(ngModel)]="p.telephone" [name]="'tel' + i" autocomplete="tel" placeholder="07 00 00 00 00"></div>
                      <div class="champ"><label>Email <span class="hint">{{ i === 0 ? '(billets envoyés ici)' : '(facultatif)' }}</span></label>
                        <input class="entree" type="email" [(ngModel)]="p.email" [name]="'email' + i" autocomplete="email" placeholder="vous@exemple.ci"></div>
                    </div>
                  </fieldset>
                }
                @if (erreur()) { <div class="alerte erreur"><tb-icon name="alert" [size]="18" /> {{ erreur() }}</div> }
                <button class="btn btn-primaire btn-lg btn-bloc" (click)="versPaiement()">Continuer vers le paiement <tb-icon name="arrow-right" [size]="20" /></button>
              </section>
            }

            @if (etape() === 2) {
              <section class="carte">
                <h2>Comment souhaitez-vous payer ?</h2>
                <p class="muted">Paiement sécurisé. Vos billets sont émis dès la confirmation.</p>
                <div class="methodes">
                  @for (m of methodes; track m.code) {
                    <label class="methode" [class.choisie]="methode() === m.code">
                      <input type="radio" name="methode" [checked]="methode() === m.code" (change)="methode.set(m.code)">
                      <span class="logo-pay" [style.background]="m.couleur" [style.color]="m.texte">{{ initialesMethode(m.label) }}</span>
                      <span class="txt"><b>{{ m.label }}</b><small>{{ m.detail }}</small></span>
                      <span class="coche"><tb-icon name="check" [size]="16" /></span>
                    </label>
                  }
                </div>
                @if (methode() !== 'carte') {
                  <div class="champ"><label>Numéro {{ methodeLabel() }}</label>
                    <input class="entree" type="tel" [(ngModel)]="telephonePaiement" name="telpay" placeholder="07 00 00 00 00"></div>
                }
                @if (!auth.connecte()) {
                  <div class="alerte or"><tb-icon name="lock" [size]="18" />
                    <span>Pour finaliser, <a [routerLink]="'/connexion'" [queryParams]="{ retour: urlActuelle(), mode: 'inscription' }"><b>créez votre compte</b></a>
                    ou <a [routerLink]="'/connexion'" [queryParams]="{ retour: urlActuelle() }"><b>connectez-vous</b></a> : vos billets y seront enregistrés. Vos informations sont conservées.</span></div>
                }
                @if (erreur()) { <div class="alerte erreur"><tb-icon name="alert" [size]="18" /> {{ erreur() }}</div> }
                <div class="actions">
                  <button class="btn btn-contour" (click)="etape.set(1)"><tb-icon name="arrow-left" [size]="18" /> Voyageurs</button>
                  <button class="btn btn-primaire btn-lg payer" (click)="payer()" [disabled]="envoi() || !auth.connecte()">
                    @if (envoi()) { <span class="spinner blanc"></span> Paiement en cours… }
                    @else { <tb-icon name="lock" [size]="18" /> Payer {{ total() | nb:'F' }} }
                  </button>
                </div>
                <p class="garantie"><tb-icon name="shield" [size]="16" /> Annulation possible jusqu'à 2 h avant le départ, selon les conditions de la compagnie.</p>
              </section>
            }
          </div>

          <aside class="recap">
            @if (trajet(); as t) {
              <div class="carte">
                <div class="recap-tete"><span class="pastille vert">{{ t.heure_depart | date:'EEEE d MMMM' }}</span></div>
                <div class="parcours">
                  <div class="arret"><b>{{ t.heure_depart | date:'HH:mm' }}</b><div><span>{{ t.depart.nom }}</span>@if (t.gare_depart) { <small>{{ t.gare_depart.nom }}</small> }</div></div>
                  <div class="trait"><small>{{ t.duree_label }} · direct</small></div>
                  <div class="arret"><b>{{ t.heure_arrivee_estimee | date:'HH:mm' }}</b><div><span>{{ t.arrivee.nom }}</span></div></div>
                </div>
                <div class="cie"><span class="logo-cie">{{ t.compagnie[0] }}</span><div><b>{{ t.compagnie }}</b><small>{{ classeLabel(t.bus_classe) }} · {{ t.bus_immatriculation }}</small></div></div>
                <div class="lignes">
                  <div><span>{{ nbPassagers() }} × billet</span><span>{{ t.prix_actuel | nb:'F' }}</span></div>
                  <div><span>Frais de service</span><span class="vert">Offerts</span></div>
                  <div class="total"><span>Total</span><span>{{ total() | nb:'F' }}</span></div>
                </div>
                <p class="siege"><tb-icon name="seat" [size]="16" /> Sièges attribués automatiquement, côte à côte.</p>
              </div>
            } @else { <div class="squelette" style="height:380px;border-radius:20px"></div> }
          </aside>
        </div>
      }
    </div>
  `,
  styles: [`
    .page{padding-top:28px;padding-bottom:40px;}
    .retour{display:inline-flex;align-items:center;gap:8px;color:var(--texte-2);font-weight:600;cursor:pointer;}
    .retour:hover{color:var(--vert);}
    .etapes{list-style:none;display:flex;gap:10px;margin:24px 0 28px;flex-wrap:wrap;}
    .etapes li{display:flex;align-items:center;gap:10px;font-weight:600;color:var(--texte-3);}
    .etapes li:not(:last-child)::after{content:'';width:40px;height:2px;background:var(--bord);margin-left:4px;}
    .etapes span{width:30px;height:30px;border-radius:50%;border:2px solid var(--bord);display:flex;align-items:center;justify-content:center;font-size:14px;}
    .etapes .active{color:var(--texte);} .etapes .active span{background:var(--vert);border-color:var(--vert);color:#fff;}
    @media (max-width:560px){.etapes{gap:6px;flex-wrap:nowrap;font-size:14px;}.etapes li{gap:6px;}.etapes li:not(:last-child)::after{width:14px;}}
    .etapes .faite{color:var(--vert);} .etapes .faite span{background:var(--vert-clair);border-color:var(--vert-clair);}
    .disposition{display:grid;grid-template-columns:1fr 380px;gap:28px;align-items:start;}
    @media (max-width:980px){.disposition{grid-template-columns:1fr;}.recap{order:-1;}}
    .principal section{display:flex;flex-direction:column;gap:18px;padding:32px;}
    @media (max-width:560px){.principal section{padding:22px;}}
    h2{font-size:26px;font-weight:800;letter-spacing:-.02em;}
    .muted{margin-top:-10px;}
    .alerte a{color:inherit;text-decoration:underline;}
    .voyageur{border:1px solid var(--bord);border-radius:var(--r-lg);padding:20px;display:flex;flex-direction:column;gap:14px;}
    legend{display:flex;align-items:center;gap:10px;font-weight:700;padding:0 8px;}
    .num{width:28px;height:28px;border-radius:50%;background:var(--encre);color:#fff;display:flex;align-items:center;justify-content:center;font-size:13px;}
    .methodes{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
    @media (max-width:640px){.methodes{grid-template-columns:1fr;}}
    .methode{position:relative;display:flex;align-items:center;gap:14px;padding:16px;border:2px solid var(--bord);border-radius:var(--r-lg);cursor:pointer;transition:border-color .15s,background .15s;}
    .methode:hover{border-color:#C8D2CD;}
    .methode.choisie{border-color:var(--vert);background:var(--vert-clair);}
    .methode input{position:absolute;opacity:0;}
    .logo-pay{width:48px;height:48px;border-radius:14px;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:15px;flex-shrink:0;}
    .txt{display:flex;flex-direction:column;flex:1;}
    .txt small{font-size:13px;color:var(--texte-2);}
    .coche{width:24px;height:24px;border-radius:50%;border:2px solid var(--bord);display:flex;align-items:center;justify-content:center;color:transparent;}
    .choisie .coche{background:var(--vert);border-color:var(--vert);color:#fff;}
    .actions{display:flex;gap:12px;justify-content:space-between;flex-wrap:wrap;}
    .payer{flex:1;min-width:240px;}
    .garantie{display:flex;align-items:center;gap:8px;font-size:14px;color:var(--texte-2);}
    .recap{position:sticky;top:96px;}
    .recap .carte{display:flex;flex-direction:column;gap:20px;}
    .parcours{display:flex;flex-direction:column;}
    .arret{display:grid;grid-template-columns:58px 1fr;gap:12px;align-items:start;}
    .arret b{font-size:20px;font-weight:800;}
    .arret span{font-weight:700;font-size:17px;display:block;}
    .arret small{font-size:13px;color:var(--texte-3);}
    .trait{margin-left:76px;border-left:2px dashed var(--vert);padding:10px 0 10px 16px;color:var(--texte-3);}
    .cie{display:flex;gap:12px;align-items:center;padding:14px;border-radius:var(--r);background:var(--surface-2);}
    .cie small{display:block;font-size:13px;color:var(--texte-2);}
    .logo-cie{width:40px;height:40px;border-radius:12px;background:var(--encre);color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;}
    .lignes{display:flex;flex-direction:column;gap:10px;border-top:1px solid var(--bord);padding-top:16px;}
    .lignes div{display:flex;justify-content:space-between;color:var(--texte-2);}
    .lignes .vert{color:var(--vert);font-weight:700;}
    .lignes .total{color:var(--texte);font-size:20px;font-weight:900;border-top:1px solid var(--bord);padding-top:12px;}
    .siege{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--texte-2);}
  `],
})
export class ReservationComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private toast = inject(ToastService);

  readonly methodes = METHODES;
  trajet = signal<Trajet | null>(null);
  erreurChargement = signal('');
  etape = signal(1);
  methode = signal<MethodePaiement>('orange_money');
  envoi = signal(false);
  erreur = signal('');
  nbPassagers = signal(1);
  voyageurs: PassagerSaisie[] = [];
  telephonePaiement = '';
  private trajetId = '';

  total = computed(() => (this.trajet()?.prix_actuel ?? 0) * this.nbPassagers());
  methodeLabel = computed(() => METHODES.find(m => m.code === this.methode())?.label ?? '');

  ngOnInit(): void {
    this.trajetId = this.route.snapshot.paramMap.get('trajetId') ?? '';
    this.nbPassagers.set(Math.min(9, Math.max(1, Number(this.route.snapshot.queryParamMap.get('passagers')) || 1)));
    const brouillon = this.lireBrouillon();
    this.voyageurs = brouillon?.voyageurs?.length === this.nbPassagers() ? brouillon.voyageurs
      : Array.from({ length: this.nbPassagers() }, () => ({ prenom: '', nom: '', telephone: '', email: '' }));
    const u = this.auth.user();
    if (u && !this.voyageurs[0].prenom) {
      this.voyageurs[0] = { prenom: u.prenom, nom: u.nom, telephone: u.telephone, email: u.email };
    }
    this.telephonePaiement = brouillon?.telephone || this.voyageurs[0].telephone || u?.telephone || '';
    if (brouillon?.etape === 2 && this.valides()) this.etape.set(2);
    this.api.trajet(this.trajetId).subscribe({
      next: t => this.trajet.set(t),
      error: () => this.erreurChargement.set('Il a peut-être déjà eu lieu ou il est complet. Lancez une nouvelle recherche.'),
    });
  }

  urlActuelle(): string { this.sauverBrouillon(); return this.router.url; }

  retour(): void {
    const t = this.trajet();
    if (!t) { this.router.navigate(['/']); return; }
    this.router.navigate(['/recherche'], { queryParams: { depart: t.depart.id, arrivee: t.arrivee.id,
      date: t.heure_depart.slice(0, 10), passagers: this.nbPassagers() } });
  }

  private valides(): boolean {
    return this.voyageurs.every(p => p.prenom.trim().length >= 2 && p.nom.trim().length >= 2 && p.telephone.replace(/\D/g, '').length >= 8);
  }

  versPaiement(): void {
    this.erreur.set('');
    if (!this.valides()) { this.erreur.set('Renseignez le prénom, le nom et le téléphone de chaque passager.'); return; }
    if (!this.telephonePaiement) this.telephonePaiement = this.voyageurs[0].telephone;
    this.etape.set(2);
    this.sauverBrouillon();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  payer(): void {
    this.erreur.set('');
    const tel = this.methode() === 'carte' ? this.voyageurs[0].telephone : this.telephonePaiement;
    if (tel.replace(/\D/g, '').length < 8) { this.erreur.set('Indiquez le numéro qui va payer.'); return; }
    this.envoi.set(true);
    const passagers = this.voyageurs.map(p => ({ ...p, telephone: p.telephone.replace(/\s/g, ''), email: p.email.trim() }));
    this.api.reserver(this.trajetId, passagers, passagers[0].email).pipe(
      switchMap(res => this.api.payer(res.id, this.methode(), tel.replace(/\s/g, '')).pipe(
        switchMap(p => [{ res, p }]))),
    ).subscribe({
      next: ({ res, p }) => {
        this.effacerBrouillon();
        if (p.url_paiement) { window.location.href = p.url_paiement; return; }
        this.toast.succes(p.simulation ? 'Paiement confirmé — bon voyage !' : p.message);
        this.auth.rafraichirProfil();
        this.router.navigate(['/billets', res.id], { queryParams: { nouveau: 1 } });
      },
      error: e => { this.envoi.set(false); this.erreur.set(messageErreur(e, 'Le paiement n\'a pas pu être lancé. Réessayez.')); },
    });
  }

  initialesMethode(l: string): string { return l.split(' ').map(x => x[0]).join('').slice(0, 3).toUpperCase(); }
  classeLabel(c: string): string { return ({ standard: 'Standard', confort: 'Confort', vip: 'VIP' } as Record<string, string>)[c] ?? c; }

  // Brouillon conservé si le voyageur doit se connecter en cours de route
  private cle(): string { return `tb_resa_${this.trajetId}`; }
  private sauverBrouillon(): void {
    try { sessionStorage.setItem(this.cle(), JSON.stringify({ voyageurs: this.voyageurs, telephone: this.telephonePaiement, etape: this.etape() })); } catch { /* indisponible */ }
  }
  private lireBrouillon(): { voyageurs: PassagerSaisie[]; telephone: string; etape: number } | null {
    try { return JSON.parse(sessionStorage.getItem(this.cle()) ?? 'null'); } catch { return null; }
  }
  private effacerBrouillon(): void { try { sessionStorage.removeItem(this.cle()); } catch { /* indisponible */ } }
}
