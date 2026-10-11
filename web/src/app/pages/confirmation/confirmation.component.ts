import { Component, OnInit, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import QRCode from 'qrcode';
import { ApiService } from '../../core/api.service';
import { Reservation } from '../../core/models';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

@Component({
  selector: 'tb-confirmation',
  standalone: true,
  imports: [DatePipe, RouterLink, IconComponent, NombrePipe],
  template: `
    <div class="conteneur page">
      @if (reservation(); as r) {
        @if (nouveau) {
          <div class="bravo">
            <span class="ok"><tb-icon name="check" [size]="34" [stroke]="3" /></span>
            <div><h1>C'est réservé !</h1>
              <p>Vos billets sont prêts. Présentez le QR code au chauffeur à l'embarquement, 30 minutes avant le départ.</p></div>
          </div>
        } @else {
          <h1 class="titre">Vos billets</h1>
        }

        <div class="resume carte">
          <div class="route"><b>{{ r.trajet_info.depart }}</b><tb-icon name="arrow-right" [size]="22" /><b>{{ r.trajet_info.arrivee }}</b></div>
          <div class="infos">
            <span><tb-icon name="calendar" [size]="16" /> {{ r.trajet_info.heure_depart | date:'EEEE d MMMM, HH:mm' }}</span>
            <span><tb-icon name="bus" [size]="16" /> {{ r.trajet_info.compagnie }}</span>
            <span><tb-icon name="ticket" [size]="16" /> Réf. <b class="mono">{{ r.reference }}</b></span>
            <span><tb-icon name="wallet" [size]="16" /> {{ r.montant_total | nb:'F' }}</span>
          </div>
          <div class="actions">
            <button class="btn btn-primaire btn-sm" (click)="pdf(r)" [disabled]="generation()">
              <tb-icon name="download" [size]="16" /> {{ r.passagers.length > 1 ? 'Télécharger les billets (PDF)' : 'Télécharger le billet (PDF)' }}</button>
            <button class="btn btn-blanc btn-sm" (click)="imprimer()">Imprimer</button>
            <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }" class="btn btn-contour btn-sm">Tous mes billets</a>
          </div>
        </div>

        <div class="billets">
          @for (p of r.passagers; track p.id) {
            <article class="billet">
              <div class="haut">
                <div class="marque"><img src="assets/marque/tambour-symbole-clair.svg" alt="" height="24">TamBour</div>
                <span class="pastille" [class.vert]="r.statut === 'confirmee'">{{ r.statut === 'confirmee' ? 'Valide' : r.statut }}</span>
              </div>
              <div class="corps">
                <div class="trajet">
                  <div><small>Départ</small><b>{{ r.trajet_info.heure_depart | date:'HH:mm' }}</b><span>{{ r.trajet_info.depart }}</span></div>
                  <tb-icon name="arrow-right" [size]="20" />
                  <div class="droite"><small>Arrivée</small><b>{{ r.trajet_info.heure_arrivee_estimee | date:'HH:mm' }}</b><span>{{ r.trajet_info.arrivee }}</span></div>
                </div>
                <div class="grille">
                  <div><small>Passager</small><b>{{ p.prenom }} {{ p.nom }}</b></div>
                  <div><small>Siège</small><b class="siege">{{ p.siege_numero }}</b></div>
                  <div><small>Date</small><b>{{ r.trajet_info.heure_depart | date:'d MMM yyyy' }}</b></div>
                  <div><small>Compagnie</small><b>{{ r.trajet_info.compagnie }}</b></div>
                </div>
              </div>
              <div class="dechirure"></div>
              <div class="qr">
                @if (qr()[p.id]) { <img [src]="qr()[p.id]" [alt]="'QR code du billet de ' + p.prenom"> } @else { <div class="squelette" style="width:150px;height:150px"></div> }
                <span class="mono">{{ p.billet?.reference_billet }}</span>
                <button class="btn btn-contour btn-sm pdf-un" (click)="pdf(r, p.id)" [disabled]="generation()"><tb-icon name="download" [size]="14" /> PDF</button>
                @if (p.billet?.utilise_le) { <span class="pastille">Utilisé le {{ p.billet?.utilise_le | date:'d/MM à HH:mm' }}</span> }
              </div>
            </article>
          }
        </div>
      } @else if (erreur()) {
        <div class="carte vide"><div class="icone-vide"><tb-icon name="ticket" [size]="28" /></div><h3>Billets introuvables</h3>
          <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }" class="btn btn-primaire btn-sm">Mes billets</a></div>
      } @else {
        <div class="squelette" style="height:420px;border-radius:24px;margin-top:32px"></div>
      }
    </div>
  `,
  styles: [`
    .page{padding-top:32px;padding-bottom:40px;}
    .bravo{display:flex;gap:20px;align-items:center;padding:28px;border-radius:var(--r-xl);background:linear-gradient(150deg,var(--vert-900),var(--vert));color:#fff;margin-bottom:24px;}
    .ok{width:68px;height:68px;border-radius:50%;background:var(--or);color:var(--encre);display:flex;align-items:center;justify-content:center;flex-shrink:0;animation:monte .4s;}
    .bravo h1{font-size:32px;font-weight:900;letter-spacing:-.03em;}
    .bravo p{opacity:.85;}
    .titre{font-size:32px;font-weight:800;letter-spacing:-.03em;margin-bottom:20px;}
    .resume{display:flex;flex-direction:column;gap:14px;margin-bottom:28px;}
    .route{display:flex;align-items:center;gap:12px;font-size:24px;font-weight:800;}
    .route tb-icon{color:var(--or);}
    .infos{display:flex;flex-wrap:wrap;gap:10px 22px;color:var(--texte-2);}
    .infos span{display:inline-flex;align-items:center;gap:6px;}
    .actions{display:flex;gap:10px;flex-wrap:wrap;}
    .billets{display:grid;grid-template-columns:repeat(auto-fill,minmax(520px,1fr));gap:20px;}
    @media (max-width:600px){.billets{grid-template-columns:1fr;}}
    .billet{display:grid;grid-template-columns:1fr auto auto;background:#fff;border-radius:var(--r-xl);box-shadow:var(--ombre-2);overflow:hidden;border:1px solid var(--bord);}
    .haut{grid-column:1/-1;display:flex;justify-content:space-between;align-items:center;padding:14px 22px;background:var(--encre);color:#fff;}
    .marque{display:flex;align-items:center;gap:8px;font-weight:700;font-size:18px;} .marque img{height:24px;width:auto;}
    .corps{padding:22px;display:flex;flex-direction:column;gap:18px;}
    .trajet{display:flex;justify-content:space-between;align-items:center;gap:12px;}
    .trajet tb-icon{color:var(--or);}
    .trajet div{display:flex;flex-direction:column;}
    .trajet .droite{text-align:right;}
    .trajet b{font-size:28px;font-weight:900;}
    small{font-size:12px;color:var(--texte-3);text-transform:uppercase;letter-spacing:.06em;font-weight:700;}
    .grille{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
    .grille div{display:flex;flex-direction:column;}
    .siege{font-size:22px;color:var(--vert);}
    .dechirure{width:0;border-left:2px dashed var(--bord);margin:18px 0;}
    .qr{padding:22px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;}
    .qr img{width:150px;height:150px;image-rendering:pixelated;}
    .qr .mono{font-size:12px;color:var(--texte-2);}
    .pdf-un{padding:6px 12px;font-size:13px;}
    @media (max-width:600px){
      .billet{grid-template-columns:1fr;}
      .dechirure{width:auto;height:0;border-left:none;border-top:2px dashed var(--bord);margin:0 18px;}
    }
    @media print{
      :host ::ng-deep tb-entete,:host ::ng-deep tb-pied{display:none;}
      .actions,.bravo,.pdf-un{display:none;}
      .billet{break-inside:avoid;box-shadow:none;}
    }
  `],
})
export class ConfirmationComponent implements OnInit {
  private api = inject(ApiService);
  private route = inject(ActivatedRoute);
  reservation = signal<Reservation | null>(null);
  qr = signal<Record<string, string>>({});
  erreur = signal(false);
  nouveau = false;
  generation = signal(false);

  ngOnInit(): void {
    this.nouveau = this.route.snapshot.queryParamMap.get('nouveau') === '1';
    this.api.reservation(this.route.snapshot.paramMap.get('id') ?? '').subscribe({
      next: async r => {
        this.reservation.set(r);
        const codes: Record<string, string> = {};
        for (const p of r.passagers) {
          if (p.billet?.qr_data) {
            codes[p.id] = await QRCode.toDataURL(p.billet.qr_data, { margin: 1, width: 300, color: { dark: '#0B1A14', light: '#FFFFFF' } });
          }
        }
        this.qr.set(codes);
      },
      error: () => this.erreur.set(true),
    });
  }

  imprimer(): void { window.print(); }

  /** PDF identique à celui de l'application mobile ; chargé à la demande pour alléger la page. */
  async pdf(r: Reservation, passagerId?: string): Promise<void> {
    this.generation.set(true);
    try {
      const { telechargerBilletsPdf } = await import('../../core/billet-pdf');
      await telechargerBilletsPdf(r, passagerId);
    } finally { this.generation.set(false); }
  }
}
