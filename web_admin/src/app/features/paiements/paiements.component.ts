import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Paiement } from '../../core/models/reservation.model';

@Component({
  selector: 'app-paiements',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1 class="page-title">Paiements</h1>
          <p class="page-subtitle">{{ total() }} transactions &middot; CA : <strong style="color:var(--primary)">{{ fmt(caTotal()) }} FCFA</strong></p>
        </div>
        <button class="btn btn-ghost btn-sm" (click)="exportCsv()">&#128229; CSV</button>
      </div>
      <div class="kpi-grid">
        <div class="kpi kpi-s"><div class="kpi-v">{{ nbSucces() }}</div><div class="kpi-l">&#10003; Réussis</div></div>
        <div class="kpi kpi-w"><div class="kpi-v">{{ nbAttente() }}</div><div class="kpi-l">&#8987; En attente</div></div>
        <div class="kpi kpi-e"><div class="kpi-v">{{ nbEchec() }}</div><div class="kpi-l">&#10005; Échoués</div></div>
        <div class="kpi kpi-i"><div class="kpi-v">{{ nbRembourse() }}</div><div class="kpi-l">&#8617; Remboursés</div></div>
      </div>
      <div class="filters">
        <div class="search-box">
          <span class="search-icon">&#128269;</span>
          <input type="text" class="form-control" placeholder="Référence, téléphone..."
            [(ngModel)]="search" (ngModelChange)="search$.next($event)">
        </div>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreStatut" (change)="onFiltreChange()">
          <option value="">Tous statuts</option>
          <option value="initie">Initié</option>
          <option value="en_attente">En attente</option>
          <option value="succes">Réussi</option>
          <option value="echec">Échoué</option>
          <option value="rembourse">Remboursé</option>
        </select>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreMethode" (change)="onFiltreChange()">
          <option value="">Toutes méthodes</option>
          <option value="mtn_momo">MTN MoMo</option>
          <option value="orange_money">Orange Money</option>
          <option value="wave">Wave</option>
          <option value="carte">Carte bancaire</option>
        </select>
      </div>
      <div class="table-card">
        @if (loading()) {
          <div style="padding:48px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
        } @else {
          <div class="table-container">
            <table>
              <thead><tr>
                <th>Référence</th><th>Méthode</th><th>Montant</th>
                <th>Téléphone</th><th>Statut</th><th>Initié le</th><th>Confirmé le</th>
              </tr></thead>
              <tbody>
                @for (pm of paiements(); track pm.id) {
                  <tr>
                    <td><code style="font-size:11px;background:var(--surface-2);padding:3px 7px;border-radius:5px;font-weight:700">{{ pm.reference }}</code></td>
                    <td><div style="display:flex;align-items:center;gap:6px"><span>{{ methodeIcon(pm.methode) }}</span><span>{{ pm.methode_label }}</span></div></td>
                    <td>
                      <strong [style.color]="pm.statut === 'echec' ? 'var(--error)' : 'var(--primary)'">{{ fmt(pm.montant) }} FCFA</strong>
                      @if (pm.montant_rembourse > 0) { <div style="font-size:11px;color:var(--error)">&minus;{{ fmt(pm.montant_rembourse) }} remboursé</div> }
                    </td>
                    <td>{{ pm.telephone }}</td>
                    <td><span class="badge" [ngClass]="statutBadge(pm.statut)">{{ pm.statut_label }}</span></td>
                    <td style="color:var(--text-2)">{{ pm.created_at | date:'dd/MM HH:mm' }}</td>
                    <td style="color:var(--text-2)">{{ pm.confirme_le ? (pm.confirme_le | date:'dd/MM HH:mm') : '—' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="7"><div class="empty-state"><div class="empty-icon">💳</div><h3>Aucune transaction</h3></div></td></tr>
                }
              </tbody>
            </table>
          </div>
          <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
        }
      </div>
    </div>
  `,
  styles: [`
    .kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;}
    .kpi{background:var(--surface);border:0.5px solid var(--border);border-radius:14px;padding:16px 20px;box-shadow:var(--shadow-sm);}
    .kpi-v{font-size:28px;font-weight:800;margin-bottom:4px;}
    .kpi-l{font-size:12px;color:var(--text-2);}
    .kpi-s .kpi-v{color:var(--success);}
    .kpi-w .kpi-v{color:var(--warning);}
    .kpi-e .kpi-v{color:var(--error);}
    .kpi-i .kpi-v{color:var(--info);}
    @media(max-width:700px){.kpi-grid{grid-template-columns:repeat(2,1fr);}}
  `]
})
export class PaiementsComponent implements OnInit {
  private api   = inject(ApiService);
  private toast = inject(ToastService);
  paiements     = signal<Paiement[]>([]);
  total = signal(0); page = signal(1); loading = signal(false);
  search = ''; filtreStatut = ''; filtreMethode = '';
  readonly pageSize = 20;
  search$ = new Subject<string>();

  // Tous les computed() sont dans la classe — jamais de .filter() dans le template
  caTotal     = computed(() => this.paiements().filter(pm => pm.statut === 'succes').reduce((s, pm) => s + pm.montant, 0));
  nbSucces    = computed(() => this.paiements().filter(pm => pm.statut === 'succes').length);
  nbAttente   = computed(() => this.paiements().filter(pm => pm.statut === 'en_attente').length);
  nbEchec     = computed(() => this.paiements().filter(pm => pm.statut === 'echec').length);
  nbRembourse = computed(() => this.paiements().filter(pm => pm.statut === 'rembourse').length);

  ngOnInit(): void {
    this.search$.pipe(debounceTime(400), distinctUntilChanged()).subscribe(() => { this.page.set(1); this.load(); });
    this.load();
  }
  onFiltreChange(): void { this.page.set(1); this.load(); }
  onPage(p: number): void { this.page.set(p); this.load(); }
  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = { page: String(this.page()) };
    if (this.search)        p['search']  = this.search;
    if (this.filtreStatut)  p['statut']  = this.filtreStatut;
    if (this.filtreMethode) p['methode'] = this.filtreMethode;
    this.api.getPaiements(p).subscribe({
      next: res => { this.paiements.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  fmt(n: number): string { return n.toLocaleString('fr-FR'); }
  methodeIcon(m: string): string { const r: Record<string,string> = { mtn_momo:'📱', orange_money:'🟠', wave:'🌊', carte:'💳' }; return r[m] ?? '💰'; }
  statutBadge(s: string): string { const r: Record<string,string> = { initie:'badge-neutral', en_attente:'badge-warning', succes:'badge-success', echec:'badge-error', rembourse:'badge-info', annule:'badge-neutral' }; return r[s] ?? 'badge-neutral'; }
  exportCsv(): void {
    const csv = ['Référence,Méthode,Montant,Téléphone,Statut,Date',
      ...this.paiements().map(pm => [pm.reference,pm.methode_label,pm.montant,pm.telephone,pm.statut_label,pm.created_at].join(','))].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    Object.assign(document.createElement('a'), { href: url, download: 'paiements.csv' }).click();
    URL.revokeObjectURL(url);
  }
}
