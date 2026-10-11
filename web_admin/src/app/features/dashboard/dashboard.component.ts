import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { DashboardStats, Trajet } from '../../core/models/transport.model';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

const METHODES: Record<string, { label: string; couleur: string }> = {
  orange_money: { label: 'Orange Money', couleur: '#FF7900' },
  mtn_momo:     { label: 'MTN MoMo',     couleur: '#FFCB05' },
  wave:         { label: 'Wave',         couleur: '#1DC8F2' },
  carte:        { label: 'Carte bancaire', couleur: '#2563EB' },
};

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1 class="page-title">{{ salutation() }}, {{ auth.user()?.prenom }}</h1>
          <p class="page-subtitle">Voici l'activité de TamBour aujourd'hui.</p>
        </div>
        <div class="header-actions">
          <button class="btn btn-secondary btn-sm" (click)="charger()" [disabled]="chargement()">
            <tb-icon name="refresh" [size]="16" /> Actualiser
          </button>
          <a class="btn btn-primary btn-sm" routerLink="/trajets"><tb-icon name="route" [size]="16" /> Gérer les trajets</a>
        </div>
      </div>

      @if (erreur()) {
        <div class="card alerte"><tb-icon name="alert" /> {{ erreur() }}</div>
      }

      <!-- Indicateurs -->
      <div class="stats-grid">
        @if (!stats()) {
          @for (i of [1,2,3,4]; track i) { <div class="skeleton-card"><div class="skeleton" style="height:72px;width:100%"></div></div> }
        } @else {
          <a class="stat-card clickable" routerLink="/reservations">
            <div class="stat-top">
              <div class="stat-icon"><tb-icon name="ticket" /></div>
              <span class="stat-delta" [class.pos]="(stats()!.delta_reservations_hier ?? 0) > 0" [class.neg]="(stats()!.delta_reservations_hier ?? 0) < 0">
                {{ signe(stats()!.delta_reservations_hier ?? 0) }} vs hier
              </span>
            </div>
            <div><div class="stat-value">{{ stats()!.reservations_today | nb }}</div><div class="stat-label">Réservations aujourd'hui</div></div>
          </a>
          <a class="stat-card clickable" routerLink="/paiements">
            <div class="stat-top">
              <div class="stat-icon gold"><tb-icon name="wallet" /></div>
              <span class="stat-delta" [class.pos]="(stats()!.delta_ca_mois_precedent ?? 0) > 0" [class.neg]="(stats()!.delta_ca_mois_precedent ?? 0) < 0">
                {{ signe(stats()!.delta_ca_mois_precedent ?? 0) }} %
              </span>
            </div>
            <div><div class="stat-value">{{ stats()!.chiffre_affaires_mois | nb }} <small>F</small></div><div class="stat-label">Chiffre d'affaires du mois</div></div>
          </a>
          <a class="stat-card clickable" routerLink="/voyageurs">
            <div class="stat-top">
              <div class="stat-icon info"><tb-icon name="users" /></div>
              <span class="stat-delta pos">+{{ stats()!.nouveaux_voyageurs_semaine }} cette semaine</span>
            </div>
            <div><div class="stat-value">{{ stats()!.total_voyageurs | nb }}</div><div class="stat-label">Voyageurs inscrits</div></div>
          </a>
          <a class="stat-card clickable" routerLink="/trajets">
            <div class="stat-top">
              <div class="stat-icon neutral"><tb-icon name="bus" /></div>
              <span class="stat-delta">{{ stats()!.taux_remplissage_moyen | nb }} % remplis</span>
            </div>
            <div><div class="stat-value">{{ stats()!.trajets_today | nb }}</div><div class="stat-label">Départs aujourd'hui</div></div>
          </a>
        }
      </div>

      <div class="grille">
        <!-- Réservations 7 jours -->
        <div class="card">
          <div class="card-header">
            <div><div class="card-title">Réservations — 7 derniers jours</div>
              <div class="card-subtitle">{{ totalSemaine() | nb }} réservations sur la période</div></div>
          </div>
          <div class="histo">
            @for (v of stats()?.reservations_par_jour ?? []; track $index) {
              <div class="col" [class.aujourdhui]="$last">
                <span class="val">{{ v }}</span>
                <div class="barre" [style.height.%]="pct(v)"></div>
                <span class="jour">{{ jours[$index] }}</span>
              </div>
            }
          </div>
        </div>

        <!-- Moyens de paiement -->
        <div class="card">
          <div class="card-header"><div class="card-title">Moyens de paiement</div><span class="card-subtitle">Ce mois</span></div>
          @if (paiements().length === 0) {
            <div class="empty-state"><div class="empty-icon"><tb-icon name="wallet" [size]="26" /></div><p>Aucun paiement ce mois-ci</p></div>
          } @else {
            <div class="donut-zone">
              <div class="donut" [style.background]="donut()"><div class="trou"><strong>{{ totalPaiements() | nb }}</strong><span>FCFA</span></div></div>
              <ul class="legende">
                @for (p of paiements(); track p.methode) {
                  <li><i [style.background]="p.couleur"></i><span>{{ p.label }}</span><b>{{ p.pct }} %</b></li>
                }
              </ul>
            </div>
          }
        </div>
      </div>

      <div class="grille">
        <!-- Prochains départs -->
        <div class="table-card">
          <div class="toolbar">
            <div class="card-title">Prochains départs</div>
            <span class="spacer"></span>
            <a class="btn btn-ghost btn-sm" routerLink="/trajets">Tout voir <tb-icon name="arrow-right" [size]="16" /></a>
          </div>
          <div class="table-container">
            <table>
              <tbody>
                @for (t of departs(); track t.id) {
                  <tr>
                    <td style="width:76px"><div class="heure">{{ t.heure_depart | date:'HH:mm' }}</div><div class="cell-sub">{{ t.heure_depart | date:'EEE d' }}</div></td>
                    <td><div class="route">{{ t.depart_nom }} <span class="arrow"><tb-icon name="arrow-right" [size]="14" /></span> {{ t.arrivee_nom }}</div>
                      <div class="cell-sub">{{ t.compagnie }} · {{ t.chauffeur_nom || 'Chauffeur non attribué' }}</div></td>
                    <td style="width:150px">
                      <div class="remplissage"><div class="progress" [class.warn]="remplissage(t) > 85"><span [style.width.%]="remplissage(t)"></span></div>
                      <span class="cell-sub">{{ t.places_total - t.places_disponibles }}/{{ t.places_total }}</span></div>
                    </td>
                  </tr>
                } @empty {
                  <tr><td><div class="empty-state">Aucun départ à venir</div></td></tr>
                }
              </tbody>
            </table>
          </div>
        </div>

        <!-- Lignes + à traiter -->
        <div class="colonne">
          <div class="card">
            <div class="card-header"><div class="card-title">Lignes les plus réservées</div></div>
            @for (l of stats()?.top_lignes ?? []; track l.ligne; let i = $index) {
              <div class="ligne-top">
                <span class="rang">{{ i + 1 }}</span>
                <span class="nom">{{ l.ligne }}</span>
                <div class="progress"><span [style.width.%]="pctLigne(l.count)"></span></div>
                <b>{{ l.count }}</b>
              </div>
            } @empty { <p class="text-muted">Pas encore de réservations.</p> }
          </div>
          <div class="a-traiter">
            <a class="tuile" routerLink="/support"><tb-icon name="headset" /><div><b>{{ reclamationsOuvertes() }}</b><span>réclamations à traiter</span></div></a>
            <a class="tuile" routerLink="/trajets"><tb-icon name="steering" /><div><b>{{ sansChauffeur() }}</b><span>départs sans chauffeur</span></div></a>
            <a class="tuile" routerLink="/paiements"><tb-icon name="clock" /><div><b>{{ stats()?.paiements_en_attente ?? 0 }}</b><span>paiements en attente</span></div></a>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .stat-card{text-decoration:none;color:inherit;}
    .stat-value small{font-size:15px;color:var(--text-2);font-weight:700;}
    .alerte{display:flex;gap:10px;align-items:center;color:var(--error);background:var(--error-bg);border-color:transparent;}
    .grille{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(0,1fr);gap:20px;}
    @media (max-width:1100px){.grille{grid-template-columns:1fr;}}
    .histo{display:flex;align-items:flex-end;gap:12px;height:220px;padding-top:12px;}
    .col{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%;gap:8px;}
    .barre{width:100%;max-width:48px;min-height:4px;border-radius:10px 10px 4px 4px;background:linear-gradient(180deg,#A9CDBF,#5DBB8F);transition:height .5s cubic-bezier(.2,.8,.2,1);}
    .col.aujourdhui .barre{background:linear-gradient(180deg,#2E8466,var(--primary));}
    .val{font-size:12px;font-weight:700;color:var(--text-2);}
    .jour{font-size:12px;color:var(--text-3);font-weight:600;text-transform:capitalize;}
    .col.aujourdhui .jour{color:var(--primary);}
    .donut-zone{display:flex;align-items:center;gap:28px;flex-wrap:wrap;justify-content:center;}
    .donut{width:168px;height:168px;border-radius:50%;display:flex;align-items:center;justify-content:center;}
    .trou{width:112px;height:112px;border-radius:50%;background:var(--surface);display:flex;flex-direction:column;align-items:center;justify-content:center;}
    .trou strong{font-size:18px;font-weight:800;}
    .trou span{font-size:11px;color:var(--text-3);font-weight:600;}
    .legende{list-style:none;display:flex;flex-direction:column;gap:10px;min-width:180px;}
    .legende li{display:flex;align-items:center;gap:10px;font-size:14px;}
    .legende i{width:10px;height:10px;border-radius:3px;}
    .legende b{margin-left:auto;}
    .heure{font-size:16px;font-weight:800;font-variant-numeric:tabular-nums;}
    .remplissage{display:flex;flex-direction:column;gap:6px;}
    .colonne{display:flex;flex-direction:column;gap:20px;}
    .ligne-top{display:grid;grid-template-columns:26px 1fr 90px 32px;align-items:center;gap:12px;padding:8px 0;font-size:14px;}
    .rang{width:24px;height:24px;border-radius:7px;background:var(--surface-2);font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;color:var(--text-2);}
    .ligne-top .nom{font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .ligne-top b{text-align:right;}
    .a-traiter{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;}
    .tuile{display:flex;flex-direction:column;gap:10px;padding:16px;border-radius:var(--radius-lg);background:var(--surface);border:1px solid var(--border);
      text-decoration:none;color:var(--text-2);transition:border-color .15s,box-shadow .15s;}
    .tuile:hover{border-color:#CFD8D3;box-shadow:var(--shadow-md);color:var(--primary);}
    .tuile b{display:block;font-size:22px;color:var(--text-1);}
    .tuile span{font-size:12px;}
  `]
})
export class DashboardComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);

  stats = signal<DashboardStats | null>(null);
  departs = signal<Trajet[]>([]);
  reclamationsOuvertes = signal(0);
  sansChauffeur = signal(0);
  chargement = signal(false);
  erreur = signal<string | null>(null);

  /** Libellés des 7 derniers jours (le dernier = aujourd'hui) */
  readonly jours = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i));
    return i === 6 ? "Auj." : new Intl.DateTimeFormat('fr-FR', { weekday: 'short' }).format(d).replace('.', '');
  });

  totalSemaine = computed(() => (this.stats()?.reservations_par_jour ?? []).reduce((a, b) => a + b, 0));
  paiements = computed(() => {
    const liste = this.stats()?.methodes_paiement ?? [];
    const total = liste.reduce((s, p) => s + p.montant, 0) || 1;
    return liste.map(p => ({ ...p, ...(METHODES[p.methode] ?? { label: p.methode, couleur: '#0F4A3B' }),
      pct: Math.round(p.montant / total * 100) }));
  });
  totalPaiements = computed(() => this.paiements().reduce((s, p) => s + p.montant, 0));
  donut = computed(() => {
    let acc = 0;
    const parts = this.paiements().map(p => { const de = acc; acc += p.pct; return `${p.couleur} ${de}% ${acc}%`; });
    return `conic-gradient(${parts.join(',')})`;
  });

  ngOnInit(): void { this.charger(); }

  charger(): void {
    this.chargement.set(true);
    this.erreur.set(null);
    this.api.getDashboardStats().subscribe({
      next: r => { this.stats.set(r.data); this.chargement.set(false); },
      error: e => { this.erreur.set(e?.error?.message ?? 'Impossible de charger les statistiques.'); this.chargement.set(false); },
    });
    this.api.getTrajets({ a_venir: 'true', ordering: 'heure_depart', page_size: 6 }).subscribe({
      next: r => this.departs.set(r.data.results), error: () => {},
    });
    this.api.getTrajets({ a_venir: 'true', sans_chauffeur: 'true', page_size: 1 }).subscribe({
      next: r => this.sansChauffeur.set(r.data.count), error: () => {},
    });
    this.api.getReclamations({ statut: 'ouverte' }).subscribe({
      next: r => this.reclamationsOuvertes.set(r.data.stats?.ouverte ?? 0), error: () => {},
    });
  }

  salutation(): string {
    const h = new Date().getHours();
    return h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
  }
  signe(n: number): string { return n > 0 ? `+${n}` : `${n}`; }
  pct(v: number): number { return Math.max(3, Math.round(v / Math.max(...(this.stats()?.reservations_par_jour ?? [1]), 1) * 100)); }
  pctLigne(v: number): number { return Math.round(v / Math.max(...(this.stats()?.top_lignes ?? []).map(l => l.count), 1) * 100); }
  remplissage(t: Trajet): number { return t.places_total ? Math.round((t.places_total - t.places_disponibles) / t.places_total * 100) : 0; }
}
