import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Versement } from '../../core/models/reservation.model';

interface ExportConfig { type: string; label: string; icon: string; desc: string; }

@Component({
  selector: 'app-rapports',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1 class="page-title">Rapports &amp; Exports</h1>
          <p class="page-subtitle">Exports en temps réel depuis le backend Django</p>
        </div>
      </div>

      <!-- Sélecteur de période -->
      <div class="card" style="max-width:600px">
        <h3 class="card-title" style="margin-bottom:14px">&#128197; Période du rapport</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
          <div class="form-group">
            <label class="form-label">Date de début</label>
            <input type="date" class="form-control" [(ngModel)]="dateDebut">
          </div>
          <div class="form-group">
            <label class="form-label">Date de fin</label>
            <input type="date" class="form-control" [(ngModel)]="dateFin">
          </div>
        </div>
        <div style="display:flex;gap:8px;margin-top:14px">
          <button class="btn btn-ghost btn-sm" (click)="setPeriode('week')">Cette semaine</button>
          <button class="btn btn-ghost btn-sm" (click)="setPeriode('month')">Ce mois</button>
          <button class="btn btn-ghost btn-sm" (click)="setPeriode('quarter')">Ce trimestre</button>
          <button class="btn btn-ghost btn-sm" (click)="setPeriode('year')">Cette année</button>
        </div>
      </div>

      <!-- Exports disponibles -->
      <div>
        <h3 style="margin-bottom:14px">Exports disponibles</h3>
        @if (exportErreur()) {
          <div style="background:var(--error-bg);border:1px solid rgba(217,64,64,0.2);border-radius:10px;padding:12px 16px;color:var(--error);font-size:13px;margin-bottom:14px;display:flex;align-items:center;gap:8px">
            <span>&#9888;</span><span>{{ exportErreur() }}</span>
            <button class="btn btn-ghost btn-sm" style="margin-left:auto" (click)="exportErreur.set(null)">&#215;</button>
          </div>
        }
        <div class="eg">
          @for (e of exports; track e.type) {
            <div class="ec">
              <div style="font-size:28px;flex-shrink:0">{{ e.icon }}</div>
              <div style="flex:1">
                <div style="font-size:14px;font-weight:700">{{ e.label }}</div>
                <div style="font-size:12px;color:var(--text-2);margin:3px 0">{{ e.desc }}</div>
                <div style="font-size:11px;color:var(--text-3)">
                  Période : <strong>{{ dateDebut }}</strong> &rarr; <strong>{{ dateFin }}</strong>
                </div>
              </div>
              <button class="btn btn-outline btn-sm" (click)="exporter(e)"
                [disabled]="exportLoading() === e.type">
                @if (exportLoading() === e.type) {
                  <span class="spin">&#9696;</span> Export…
                } @else {
                  &#128229; Télécharger
                }
              </button>
            </div>
          }
        </div>
      </div>

      <!-- Versements transporteurs — données réelles -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128176; Versements transporteurs</h3>
          <div style="display:flex;gap:8px;align-items:center">
            <select class="form-control" style="width:auto;height:32px;font-size:12px" [(ngModel)]="filtreStatutVers" (change)="loadVersements()">
              <option value="">Tous statuts</option>
              <option value="en_attente">En attente</option>
              <option value="traite">Traités</option>
              <option value="annule">Annulés</option>
            </select>
            <button class="btn btn-ghost btn-sm" (click)="exportVersementsCsv()" [disabled]="versements().length === 0">
              &#128229; CSV
            </button>
          </div>
        </div>

        @if (versLoading()) {
          <div style="padding:32px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
        } @else if (versErreur()) {
          <div style="padding:24px;text-align:center;color:var(--error)">
            <div style="font-size:20px;margin-bottom:8px">&#9888;</div>
            <div>{{ versErreur() }}</div>
            <button class="btn btn-ghost btn-sm" style="margin-top:12px" (click)="loadVersements()">Réessayer</button>
          </div>
        } @else {
          <div class="table-container">
            <table>
              <thead>
                <tr>
                  <th>Transporteur</th>
                  <th>Période</th>
                  <th>Brut (FCFA)</th>
                  <th>Commission</th>
                  <th>Net à verser</th>
                  <th>Statut</th>
                  <th>Traité le</th>
                </tr>
              </thead>
              <tbody>
                @for (v of versements(); track v.id) {
                  <tr>
                    <td><strong>{{ v.transporteur_nom }}</strong></td>
                    <td style="color:var(--text-2);font-size:12px">
                      {{ v.periode_debut | date:'dd/MM/yyyy' }} &rarr; {{ v.periode_fin | date:'dd/MM/yyyy' }}
                    </td>
                    <td>{{ fmtN(v.montant_brut) }} F</td>
                    <td style="color:var(--error)">&minus;{{ fmtN(v.montant_commission) }} F</td>
                    <td><strong style="color:var(--primary)">{{ fmtN(v.montant_net) }} F</strong></td>
                    <td>
                      <span class="badge"
                        [class.badge-success]="v.statut === 'traite'"
                        [class.badge-warning]="v.statut === 'en_attente'"
                        [class.badge-error]="v.statut === 'annule'">
                        {{ statutVers(v.statut) }}
                      </span>
                    </td>
                    <td style="color:var(--text-2)">
                      {{ v.traite_le ? (v.traite_le | date:'dd/MM/yyyy') : '—' }}
                    </td>
                  </tr>
                } @empty {
                  <tr><td colspan="7">
                    <div class="empty-state" style="padding:40px">
                      <div class="empty-icon">&#128176;</div>
                      <h3>Aucun versement</h3>
                      <p>Les versements sont calculés automatiquement le 1er de chaque mois.</p>
                    </div>
                  </td></tr>
                }
              </tbody>
            </table>
          </div>
          @if (versTotal() > versPageSize) {
            <app-pagination
              [page]="versPage()"
              [total]="versTotal()"
              [pageSize]="versPageSize"
              (pageChange)="onVersPage($event)" />
          }
          <!-- Totaux -->
          @if (versements().length > 0) {
            <div class="totaux">
              <span>Total brut : <strong>{{ fmtN(totalBrut()) }} F</strong></span>
              <span>Commissions : <strong style="color:var(--error)">&minus;{{ fmtN(totalCommission()) }} F</strong></span>
              <span>Net total : <strong style="color:var(--primary)">{{ fmtN(totalNet()) }} F</strong></span>
            </div>
          }
        }
      </div>
    </div>
  `,
  styles: [`
    .eg { display:grid; grid-template-columns:repeat(auto-fill,minmax(320px,1fr)); gap:12px; }
    .ec { background:var(--surface); border:0.5px solid var(--border); border-radius:14px; padding:16px 18px; display:flex; align-items:center; gap:14px; box-shadow:var(--shadow-sm); transition:box-shadow 0.15s; }
    .ec:hover { box-shadow:var(--shadow-md); }
    .spin { display:inline-block; animation:spin 1s linear infinite; }
    @keyframes spin { to { transform:rotate(360deg); } }
    .totaux { display:flex; gap:24px; padding:14px 16px; background:var(--surface-2); border-top:0.5px solid var(--divider); font-size:13px; flex-wrap:wrap; }
    .totaux strong { font-size:14px; }
  `]
})
export class RapportsComponent implements OnInit {
  private api   = inject(ApiService);
  private toast = inject(ToastService);

  // Période
  dateDebut = this.firstOfMonth();
  dateFin   = this.todayStr();

  // Exports
  exportLoading = signal<string | null>(null);
  exportErreur  = signal<string | null>(null);

  readonly exports: ExportConfig[] = [
    { type: 'reservations', label: 'Réservations',  icon: '🎫', desc: 'Toutes les réservations de la période sélectionnée.' },
    { type: 'paiements',    label: 'Paiements',     icon: '💳', desc: 'Transactions CinetPay avec statuts et montants.' },
    { type: 'voyageurs',    label: 'Voyageurs',     icon: '👥', desc: 'Base voyageurs complète avec points fidélité.' },
    { type: 'trajets',      label: 'Trajets',       icon: '🚌', desc: 'Tous les trajets avec taux de remplissage.' },
  ];

  // Versements
  versements       = signal<Versement[]>([]);
  versTotal        = signal(0);
  versPage         = signal(1);
  versLoading      = signal(false);
  versErreur       = signal<string | null>(null);
  filtreStatutVers = '';
  readonly versPageSize = 20;

  // Totaux calculés
  totalBrut       = signal(0);
  totalCommission = signal(0);
  totalNet        = signal(0);

  ngOnInit(): void { this.loadVersements(); }

  setPeriode(p: 'week' | 'month' | 'quarter' | 'year'): void {
    const now = new Date();
    if (p === 'week') {
      const d = new Date(now);
      d.setDate(now.getDate() - (now.getDay() || 7) + 1);
      this.dateDebut = this.dateStr(d);
      this.dateFin   = this.todayStr();
    } else if (p === 'month') {
      this.dateDebut = this.firstOfMonth();
      this.dateFin   = this.todayStr();
    } else if (p === 'quarter') {
      const q = Math.floor(now.getMonth() / 3);
      this.dateDebut = this.dateStr(new Date(now.getFullYear(), q * 3, 1));
      this.dateFin   = this.todayStr();
    } else {
      this.dateDebut = this.dateStr(new Date(now.getFullYear(), 0, 1));
      this.dateFin   = this.todayStr();
    }
  }

  // Export réel depuis le backend
  exporter(e: ExportConfig): void {
    if (!this.dateDebut || !this.dateFin) {
      this.exportErreur.set('Veuillez sélectionner une période.');
      return;
    }
    this.exportErreur.set(null);
    this.exportLoading.set(e.type);

    this.api.exportCsv(e.type, this.dateDebut, this.dateFin).subscribe({
      next: (blob: Blob) => {
        const url  = URL.createObjectURL(blob);
        const name = `yobus_${e.type}_${this.dateDebut}_${this.dateFin}.csv`;
        Object.assign(document.createElement('a'), { href: url, download: name }).click();
        URL.revokeObjectURL(url);
        this.toast.success('Export "' + e.label + '" téléchargé.');
        this.exportLoading.set(null);
      },
      error: err => {
        const msg: string = err?.error?.message ?? err?.message ?? 'Erreur lors de l\'export.';
        this.exportErreur.set(msg);
        this.toast.error(msg);
        this.exportLoading.set(null);
      }
    });
  }

  loadVersements(): void {
    this.versLoading.set(true);
    this.versErreur.set(null);
    const p: Record<string, string | number> = { page: this.versPage() };
    if (this.filtreStatutVers) p['statut'] = this.filtreStatutVers;

    this.api.getVersements(p).subscribe({
      next: res => {
        this.versements.set(res.data.results);
        this.versTotal.set(res.data.count);
        // Totaux sur la page courante
        this.totalBrut.set(res.data.results.reduce((s, v) => s + v.montant_brut, 0));
        this.totalCommission.set(res.data.results.reduce((s, v) => s + v.montant_commission, 0));
        this.totalNet.set(res.data.results.reduce((s, v) => s + v.montant_net, 0));
        this.versLoading.set(false);
      },
      error: err => {
        const msg: string = err?.error?.message ?? err?.message ?? 'Impossible de charger les versements.';
        this.versErreur.set(msg);
        this.versLoading.set(false);
      }
    });
  }

  onVersPage(p: number): void { this.versPage.set(p); this.loadVersements(); }

  // Export CSV local des versements affichés
  exportVersementsCsv(): void {
    const header = 'Transporteur,Période début,Période fin,Brut,Commission,Net,Statut,Traité le';
    const rows = this.versements().map(v =>
      [v.transporteur_nom, v.periode_debut, v.periode_fin,
       v.montant_brut, v.montant_commission, v.montant_net,
       v.statut, v.traite_le ?? ''].join(','));
    const csv = [header, ...rows].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    Object.assign(document.createElement('a'), { href: url, download: 'versements.csv' }).click();
    URL.revokeObjectURL(url);
    this.toast.success('Versements exportés.');
  }

  statutVers(s: string): string {
    const m: Record<string, string> = { en_attente: '⏳ En attente', traite: '✓ Traité', annule: '✕ Annulé' };
    return m[s] ?? s;
  }
  fmtN(n: number): string { return n.toLocaleString('fr-FR'); }
  private dateStr(d: Date): string { return d.toISOString().split('T')[0]; }
  private todayStr(): string { return this.dateStr(new Date()); }
  private firstOfMonth(): string { const d = new Date(); d.setDate(1); return this.dateStr(d); }
}
