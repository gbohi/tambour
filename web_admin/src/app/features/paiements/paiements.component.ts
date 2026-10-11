import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Paiement } from '../../core/models/reservation.model';
import { METHODES_PAIEMENT, infoMethode } from '../../shared/paiements/paiements';

@Component({
  selector: 'app-paiements',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Paiements</h1>
          <p class="page-subtitle">{{ total() | nb }} transactions · encaissé sur cette page : <b class="text-primary">{{ caTotal() | nb:'FCFA' }}</b></p></div>
        <button class="btn btn-secondary" (click)="exportCsv()"><tb-icon name="download" [size]="16" /> Exporter (CSV)</button>
      </div>
      <div class="stats-grid">
        <div class="stat-card"><div class="stat-top"><div class="stat-icon"><tb-icon name="check-circle" /></div></div>
          <div><div class="stat-value">{{ nbSucces() | nb }}</div><div class="stat-label">Réussis</div></div></div>
        <div class="stat-card"><div class="stat-top"><div class="stat-icon gold"><tb-icon name="clock" /></div></div>
          <div><div class="stat-value">{{ nbAttente() | nb }}</div><div class="stat-label">En attente</div></div></div>
        <div class="stat-card"><div class="stat-top"><div class="stat-icon error"><tb-icon name="x-circle" /></div></div>
          <div><div class="stat-value">{{ nbEchec() | nb }}</div><div class="stat-label">Échoués</div></div></div>
        <div class="stat-card"><div class="stat-top"><div class="stat-icon info"><tb-icon name="refresh" /></div></div>
          <div><div class="stat-value">{{ nbRembourse() | nb }}</div><div class="stat-label">Remboursés</div></div></div>
      </div>
      <div class="table-card">
        <div class="toolbar">
          <div class="search-box"><span class="search-icon"><tb-icon name="search" [size]="16" /></span>
            <input type="text" class="form-control" placeholder="Référence, téléphone…" [(ngModel)]="search" (ngModelChange)="search$.next($event)"></div>
          <select class="form-control" [(ngModel)]="filtreStatut" (change)="onFiltreChange()">
            <option value="">Tous les statuts</option><option value="succes">Réussi</option><option value="en_attente">En attente</option>
            <option value="initie">Initié</option><option value="echec">Échoué</option><option value="rembourse">Remboursé</option>
          </select>
          <div class="segmented">
            <button [class.active]="filtreMethode === ''" (click)="filtreMethode = ''; onFiltreChange()">Tous</button>
            @for (m of methodes; track m.code) {
              <button [class.active]="filtreMethode === m.code" (click)="filtreMethode = m.code; onFiltreChange()">
                @if (m.logo) { <img class="logo-pm" [src]="m.logo" alt=""> } @else { <tb-icon name="card" [size]="16" /> }{{ m.court }}</button>
            }
          </div>
        </div>
        <div class="table-container">
          <table>
            <thead><tr><th>Référence</th><th>Moyen</th><th>Téléphone</th><th class="right">Montant</th><th>Statut</th><th>Date</th></tr></thead>
            <tbody>
              @if (loading()) {
                <tr><td colspan="6"><div class="loading-row"><span class="spinner"></span></div></td></tr>
              } @else {
                @for (pm of paiements(); track pm.id) {
                  <tr>
                    <td><span class="mono cell-main">{{ pm.reference }}</span></td>
                    <td><span class="methode">@if (info(pm.methode).logo; as logo) { <img class="logo-pm grand" [src]="logo" alt=""> } @else { <span class="logo-carte"><tb-icon name="card" [size]="15" /></span> }{{ info(pm.methode).label }}</span></td>
                    <td>{{ pm.telephone }}</td>
                    <td class="right"><span class="amount" [class.text-error]="pm.statut === 'echec'">{{ pm.montant | nb:'F' }}</span>
                      @if (pm.montant_rembourse > 0) { <div class="cell-sub text-error">− {{ pm.montant_rembourse | nb }} remboursé</div> }</td>
                    <td><span class="badge" [ngClass]="statutBadge(pm.statut)">{{ pm.statut_label }}</span></td>
                    <td class="text-muted">{{ (pm.confirme_le || pm.created_at) | date:'d MMM, HH:mm' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="6"><div class="empty-state"><div class="empty-icon"><tb-icon name="wallet" [size]="26" /></div><h3>Aucune transaction</h3></div></td></tr>
                }
              }
            </tbody>
          </table>
        </div>
        <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
      </div>
    </div>
  `,
  styles: [`
    .pastille{display:inline-block;width:9px;height:9px;border-radius:3px;}
    .methode{display:inline-flex;align-items:center;gap:10px;font-weight:600;}
    .logo-pm{width:18px;height:18px;object-fit:contain;}
    .logo-pm.grand{width:26px;height:26px;}
    .logo-carte{width:26px;height:26px;border-radius:7px;background:var(--surface-3);color:var(--text-2);display:inline-flex;align-items:center;justify-content:center;}
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
  readonly methodes = METHODES_PAIEMENT;
  readonly info = infoMethode;
  statutBadge(s: string): string { const r: Record<string,string> = { initie:'badge-neutral', en_attente:'badge-warning', succes:'badge-success', echec:'badge-error', rembourse:'badge-info', annule:'badge-neutral' }; return r[s] ?? 'badge-neutral'; }
  exportCsv(): void {
    const csv = ['Référence,Méthode,Montant,Téléphone,Statut,Date',
      ...this.paiements().map(pm => [pm.reference,pm.methode_label,pm.montant,pm.telephone,pm.statut_label,pm.created_at].join(','))].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    Object.assign(document.createElement('a'), { href: url, download: 'paiements.csv' }).click();
    URL.revokeObjectURL(url);
  }
}
