import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { StatCardComponent } from '../../shared/components/stat-card/stat-card.component';
import { DashboardStats } from '../../core/models/transport.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, StatCardComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1 class="page-title">Tableau de bord</h1>
          <p class="page-subtitle">{{ greeting() }}, {{ auth.user()?.prenom }} &mdash; {{ today }}</p>
        </div>
        <button class="btn btn-ghost btn-sm" (click)="load()" [disabled]="loading()">&#8635; Actualiser</button>
      </div>

      @if (loading()) {
        <div class="stats-grid">
          @for (i of [1,2,3,4]; track i) {
            <div class="skeleton-card">
              <div class="skeleton" style="width:48px;height:48px;border-radius:12px"></div>
              <div style="flex:1">
                <div class="skeleton" style="width:80px;height:24px;margin-bottom:8px"></div>
                <div class="skeleton" style="width:120px;height:12px"></div>
              </div>
            </div>
          }
        </div>
        <div class="dash-grid">
          <div class="card"><div class="skeleton" style="height:140px;border-radius:8px"></div></div>
          <div class="card"><div class="skeleton" style="height:140px;border-radius:8px"></div></div>
        </div>
      } @else if (erreur()) {
        <div class="api-error-card">
          <div class="api-error-icon">&#128308;</div>
          <div style="flex:1">
            <h3>Backend inaccessible</h3>
            <p>Impossible de joindre le serveur Django.</p>
            <p class="err-detail">{{ erreur() }}</p>
          </div>
          <button class="btn btn-primary btn-sm" (click)="load()">&#8635; Réessayer</button>
        </div>
      } @else if (stats()) {
        <div class="stats-grid">
          <app-stat-card icon="🎫" label="Réservations aujourd'hui"
            [value]="stats()!.reservations_today.toString()"
            iconBg="var(--primary-light)"
            [delta]="stats()!.delta_reservations_hier ?? 0"
            deltaLabel="vs hier" />
          <app-stat-card icon="💰" label="CA du mois (FCFA)"
            [value]="fmt(stats()!.chiffre_affaires_mois)"
            iconBg="var(--gold-light)"
            [delta]="stats()!.delta_ca_mois_precedent ?? 0"
            deltaLabel="vs mois dernier" />
          <app-stat-card icon="👥" label="Voyageurs actifs"
            [value]="stats()!.total_voyageurs.toString()"
            iconBg="#EFF6FF"
            [delta]="stats()!.nouveaux_voyageurs_semaine"
            deltaLabel="nouveaux cette semaine" />
          <app-stat-card icon="🚌" label="Trajets aujourd'hui"
            [value]="stats()!.trajets_today.toString()"
            iconBg="var(--surface-2)"
            [delta]="stats()!.trajets_planifies"
            deltaLabel="planifiés" />
        </div>

        <div class="dash-grid">
          <div class="card">
            <div class="card-header">
              <h3 class="card-title">Réservations — 7 derniers jours</h3>
              <span class="text-muted">{{ stats()!.reservations_week }} total</span>
            </div>
            @if (stats()!.reservations_par_jour.length > 0) {
              <div class="bar-chart">
                @for (val of stats()!.reservations_par_jour; track $index) {
                  <div class="bar-col">
                    <div class="bar-fill" [style.height.%]="barPct(val, stats()!.reservations_par_jour)">
                      <span class="bar-val">{{ val }}</span>
                    </div>
                    <div class="bar-lbl">{{ DAY[$index % 7] }}</div>
                  </div>
                }
              </div>
            } @else {
              <div class="empty-mini">Aucune donnée pour cette période</div>
            }
          </div>

          <div class="card">
            <div class="card-header"><h3 class="card-title">Top lignes</h3></div>
            @if (stats()!.top_lignes.length > 0) {
              @for (l of stats()!.top_lignes; track $index) {
                <div class="tl-row">
                  <div class="tl-rank">{{ $index + 1 }}</div>
                  <div class="tl-name">{{ l.ligne }}</div>
                  <div class="tl-bw"><div class="tl-bar" [style.width.%]="linePct(l.count, stats()!.top_lignes)"></div></div>
                  <div class="tl-ct">{{ l.count }}</div>
                </div>
              }
            } @else {
              <div class="empty-mini">Aucune ligne active</div>
            }
          </div>
        </div>

        <div class="dash-grid">
          <div class="card">
            <div class="card-header"><h3 class="card-title">Répartition des paiements</h3></div>
            @if (stats()!.methodes_paiement.length > 0) {
              @for (m of stats()!.methodes_paiement; track $index) {
                <div class="pm-row">
                  <div class="pm-ico">{{ pmIcon(m.methode) }}</div>
                  <div class="pm-info">
                    <div class="pm-name">{{ pmLabel(m.methode) }}</div>
                    <div class="pm-bw">
                      <div class="pm-bar"
                        [style.width.%]="pmPct(m.montant, stats()!.methodes_paiement)"
                        [style.background]="pmColor(m.methode)"></div>
                    </div>
                  </div>
                  <div class="pm-val">{{ fmt(m.montant) }} F</div>
                </div>
              }
            } @else {
              <div class="empty-mini">Aucun paiement ce mois</div>
            }
          </div>

          <div class="card">
            <h3 class="card-title" style="margin-bottom:16px">Actions rapides</h3>
            <div class="qa-grid">
              <a routerLink="/voyageurs"     class="qa-btn qa-green">&#128101; Voyageurs</a>
              <a routerLink="/trajets"       class="qa-btn qa-green">&#128642; Trajets</a>
              <a routerLink="/reservations"  class="qa-btn qa-gold">&#127915; Réservations</a>
              <a routerLink="/notifications" class="qa-btn qa-info">&#128276; Notifications</a>
              <a routerLink="/rapports"      class="qa-btn qa-neutral">&#128200; Rapports</a>
              <a routerLink="/paiements"     class="qa-btn qa-neutral">&#128179; Paiements</a>
            </div>
          </div>
        </div>

        @if (stats()!.paiements_en_attente > 0 || stats()!.trajets_planifies > 0) {
          <div class="alertes-grid">
            @if (stats()!.paiements_en_attente > 0) {
              <div class="alerte-card alerte-warning">
                <span class="alerte-ico">&#9888;</span>
                <div>
                  <div class="alerte-title">{{ stats()!.paiements_en_attente }} paiement{{ stats()!.paiements_en_attente > 1 ? 's' : '' }} en attente</div>
                  <div class="alerte-sub">À vérifier dans la section Paiements</div>
                </div>
                <a routerLink="/paiements" class="btn btn-ghost btn-sm">Voir</a>
              </div>
            }
            @if (stats()!.trajets_planifies > 0) {
              <div class="alerte-card alerte-info">
                <span class="alerte-ico">&#128641;</span>
                <div>
                  <div class="alerte-title">{{ stats()!.trajets_planifies }} trajet{{ stats()!.trajets_planifies > 1 ? 's' : '' }} planifié{{ stats()!.trajets_planifies > 1 ? 's' : '' }}</div>
                  <div class="alerte-sub">Départs prévus aujourd'hui</div>
                </div>
                <a routerLink="/trajets" class="btn btn-ghost btn-sm">Voir</a>
              </div>
            }
          </div>
        }
      }
    </div>
  `,
  styles: [`
    .api-error-card { display:flex; align-items:center; gap:16px; background:var(--error-bg); border:1px solid rgba(217,64,64,0.2); border-radius:var(--radius-lg); padding:20px 24px; }
    .api-error-icon { font-size:28px; flex-shrink:0; }
    .api-error-card h3 { font-size:15px; font-weight:700; color:var(--error); margin-bottom:4px; }
    .api-error-card p  { font-size:12px; color:var(--text-2); margin:2px 0; }
    .err-detail { font-size:11px !important; color:var(--text-3) !important; font-family:monospace; }

    .dash-grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
    .empty-mini { padding:24px; text-align:center; font-size:13px; color:var(--text-3); }

    .bar-chart { display:flex; align-items:flex-end; gap:8px; height:120px; }
    .bar-col   { flex:1; display:flex; flex-direction:column; align-items:center; gap:4px; height:100%; justify-content:flex-end; }
    .bar-fill  { width:100%; background:var(--primary); border-radius:6px 6px 0 0; min-height:4px; position:relative; display:flex; justify-content:center; transition:height 0.6s; }
    .bar-val   { position:absolute; top:-20px; font-size:11px; font-weight:700; }
    .bar-lbl   { font-size:10px; color:var(--text-3); }

    .tl-row  { display:flex; align-items:center; gap:10px; padding:8px 0; border-bottom:0.5px solid var(--divider); }
    .tl-row:last-child { border-bottom:none; }
    .tl-rank { width:20px; height:20px; border-radius:6px; background:var(--primary-light); color:var(--primary); font-size:11px; font-weight:700; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .tl-name { flex:1; font-size:13px; font-weight:500; }
    .tl-bw   { width:80px; height:6px; background:var(--surface-2); border-radius:3px; overflow:hidden; }
    .tl-bar  { height:100%; background:var(--primary); border-radius:3px; }
    .tl-ct   { min-width:28px; text-align:right; font-size:13px; font-weight:700; color:var(--primary); }

    .pm-row  { display:flex; align-items:center; gap:10px; margin-bottom:12px; }
    .pm-ico  { font-size:18px; width:28px; text-align:center; }
    .pm-info { flex:1; }
    .pm-name { font-size:12px; font-weight:500; margin-bottom:4px; }
    .pm-bw   { height:5px; background:var(--surface-2); border-radius:3px; overflow:hidden; }
    .pm-bar  { height:100%; border-radius:3px; }
    .pm-val  { font-size:12px; font-weight:700; min-width:80px; text-align:right; }

    .qa-grid { display:grid; grid-template-columns:1fr 1fr; gap:8px; }
    .qa-btn  { display:flex; align-items:center; gap:8px; padding:10px 14px; border-radius:10px; font-size:13px; font-weight:600; text-decoration:none; transition:all 0.15s; }
    .qa-green   { background:var(--primary-light); color:var(--primary); }
    .qa-green:hover   { background:var(--primary); color:#fff; }
    .qa-gold    { background:var(--gold-light); color:var(--gold); }
    .qa-gold:hover    { background:var(--gold); color:#fff; }
    .qa-info    { background:var(--info-bg); color:var(--info); }
    .qa-info:hover    { background:var(--info); color:#fff; }
    .qa-neutral { background:var(--surface-2); color:var(--text-1); }
    .qa-neutral:hover { background:var(--border); }

    .alertes-grid { display:flex; flex-direction:column; gap:10px; }
    .alerte-card  { display:flex; align-items:center; gap:14px; padding:14px 18px; border-radius:12px; }
    .alerte-warning { background:var(--warning-bg); border:1px solid rgba(245,166,35,0.25); }
    .alerte-info    { background:var(--info-bg);    border:1px solid rgba(37,99,235,0.15); }
    .alerte-ico   { font-size:20px; flex-shrink:0; }
    .alerte-title { font-size:13px; font-weight:700; }
    .alerte-sub   { font-size:12px; color:var(--text-2); margin-top:2px; }
    .alerte-card .btn { margin-left:auto; flex-shrink:0; }

    @media(max-width:900px) { .dash-grid { grid-template-columns:1fr; } }
  `]
})
export class DashboardComponent implements OnInit {
  auth    = inject(AuthService);
  private api = inject(ApiService);

  stats   = signal<DashboardStats | null>(null);
  loading = signal(false);
  erreur  = signal<string | null>(null);

  readonly DAY   = ['L','M','M','J','V','S','D'];
  readonly today = new Date().toLocaleDateString('fr-FR', { weekday:'long', day:'numeric', month:'long' });

  ngOnInit() { this.load(); }

  load(): void {
    this.loading.set(true);
    this.erreur.set(null);
    this.stats.set(null);
    this.api.getDashboardStats().subscribe({
      next: res  => { this.stats.set(res.data); this.loading.set(false); },
      error: err => {
        const msg: string = err?.error?.message ?? err?.message ?? 'Erreur réseau';
        this.erreur.set(msg);
        this.loading.set(false);
      }
    });
  }

  fmt(n: number): string { return n.toLocaleString('fr-FR'); }

  greeting(): string {
    const h = new Date().getHours();
    return h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
  }
  barPct(v: number, arr: number[]): number {
    const max = Math.max(...arr, 1);
    return Math.round(v / max * 100);
  }
  linePct(v: number, arr: Array<{ count: number }>): number {
    const max = Math.max(...arr.map(x => x.count), 1);
    return Math.round(v / max * 100);
  }
  pmPct(v: number, arr: Array<{ montant: number }>): number {
    const t = arr.reduce((s, x) => s + x.montant, 0) || 1;
    return Math.round(v / t * 100);
  }
  pmIcon(m: string): string  { const r: Record<string,string> = { mtn_momo:'📱', orange_money:'🟠', wave:'🌊', carte:'💳' }; return r[m] ?? '💰'; }
  pmLabel(m: string): string { const r: Record<string,string> = { mtn_momo:'MTN MoMo', orange_money:'Orange Money', wave:'Wave', carte:'Carte bancaire' }; return r[m] ?? m; }
  pmColor(m: string): string { const r: Record<string,string> = { mtn_momo:'#FFCC00', orange_money:'#FF6600', wave:'#1AC9E6', carte:'#2563EB' }; return r[m] ?? '#0A7C4E'; }
}
