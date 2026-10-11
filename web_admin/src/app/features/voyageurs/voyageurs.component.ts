import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { User } from '../../core/models/user.model';

@Component({
  selector: 'app-voyageurs',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Voyageurs</h1><p class="page-subtitle">{{ total() | nb }} comptes voyageurs</p></div>
        <button class="btn btn-secondary" (click)="exportCsv()"><tb-icon name="download" [size]="16" /> Exporter (CSV)</button>
      </div>
      <div class="table-card">
        <div class="toolbar">
          <div class="search-box">
            <span class="search-icon"><tb-icon name="search" [size]="16" /></span>
            <input type="text" class="form-control" placeholder="Nom, email, téléphone…" [(ngModel)]="search" (ngModelChange)="search$.next($event)">
          </div>
          <select class="form-control" [(ngModel)]="filtreVerif" (change)="onFiltreChange()">
            <option value="">Email vérifié ou non</option><option value="true">Email vérifié</option><option value="false">Non vérifié</option>
          </select>
          <div class="segmented">
            <button [class.active]="filtreActif === ''" (click)="filtreActif = ''; onFiltreChange()">Tous</button>
            <button [class.active]="filtreActif === 'true'" (click)="filtreActif = 'true'; onFiltreChange()">Actifs</button>
            <button [class.active]="filtreActif === 'false'" (click)="filtreActif = 'false'; onFiltreChange()">Désactivés</button>
          </div>
        </div>
        <div class="table-container">
          <table>
            <thead><tr><th>Voyageur</th><th>Téléphone</th><th class="right">Voyages</th><th class="right">Points</th><th>Code parrain</th><th>Statut</th><th>Inscription</th><th></th></tr></thead>
            <tbody>
              @if (loading()) {
                <tr><td colspan="8"><div class="loading-row"><span class="spinner"></span></div></td></tr>
              } @else {
                @for (u of voyageurs(); track u.id) {
                  <tr class="clickable" (click)="selected.set(u)">
                    <td><div class="cell-flex"><div class="avatar">{{ u.initiales }}</div>
                      <div><div class="cell-main">{{ u.nom_complet }}</div><div class="cell-sub">{{ u.email }}
                        @if (u.is_verified) { <tb-icon name="check-circle" [size]="12" class="text-success" /> }</div></div></div></td>
                    <td>{{ u.telephone || '—' }}</td>
                    <td class="right">{{ u.nb_voyages | nb }}</td>
                    <td class="right"><span class="text-gold" style="font-weight:700">{{ u.points_fidelite | nb }}</span></td>
                    <td><span class="mono">{{ u.code_parrainage || '—' }}</span></td>
                    <td><span class="badge" [ngClass]="u.is_active === false ? 'badge-error' : 'badge-success'">{{ u.is_active === false ? 'Désactivé' : 'Actif' }}</span></td>
                    <td class="text-muted">{{ u.date_inscription | date:'d MMM yyyy' }}</td>
                    <td class="right" (click)="$event.stopPropagation()">
                      @if (auth.isAdmin()) {
                        <button class="icon-btn" [class.danger]="u.is_active !== false" [class.success]="u.is_active === false"
                          [attr.data-tip]="u.is_active === false ? 'Réactiver' : 'Désactiver'" (click)="toggleActif(u)">
                          <tb-icon [name]="u.is_active === false ? 'check-circle' : 'x-circle'" />
                        </button>
                      }
                    </td>
                  </tr>
                } @empty {
                  <tr><td colspan="8"><div class="empty-state"><div class="empty-icon"><tb-icon name="users" [size]="26" /></div><h3>Aucun voyageur</h3></div></td></tr>
                }
              }
            </tbody>
          </table>
        </div>
        <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
      </div>
    </div>

    @if (selected(); as u) {
      <div class="drawer-backdrop" (click)="selected.set(null)"></div>
      <aside class="drawer">
        <div class="drawer-header">
          <div class="cell-flex"><div class="avatar avatar-lg">{{ u.initiales }}</div>
            <div><div class="modal-title">{{ u.nom_complet }}</div><div class="cell-sub">{{ u.email }}</div></div></div>
          <button class="modal-close" (click)="selected.set(null)"><tb-icon name="x" /></button>
        </div>
        <div class="drawer-body">
          <div class="kpis">
            <div><b>{{ u.nb_voyages | nb }}</b><span>voyages</span></div>
            <div><b class="text-gold">{{ u.points_fidelite | nb }}</b><span>points fidélité</span></div>
          </div>
          <div>
            <div class="info-row"><span class="info-label">Téléphone</span><span class="info-value">{{ u.telephone || '—' }}</span></div>
            <div class="info-row"><span class="info-label">Code de parrainage</span><span class="info-value mono">{{ u.code_parrainage || '—' }}</span></div>
            <div class="info-row"><span class="info-label">Email vérifié</span><span class="info-value">{{ u.is_verified ? 'Oui' : 'Non' }}</span></div>
            <div class="info-row"><span class="info-label">Notifications SMS</span><span class="info-value">{{ u.notif_sms ? 'Activées' : 'Désactivées' }}</span></div>
            <div class="info-row"><span class="info-label">Notifications email</span><span class="info-value">{{ u.notif_email ? 'Activées' : 'Désactivées' }}</span></div>
            <div class="info-row"><span class="info-label">Inscrit le</span><span class="info-value">{{ u.date_inscription | date:'d MMMM yyyy' }}</span></div>
          </div>
        </div>
        <div class="drawer-footer"><button class="btn btn-ghost" (click)="selected.set(null)">Fermer</button></div>
      </aside>
    }
  `,
  styles: [`
    .kpis{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
    .kpis div{background:var(--surface-2);border-radius:14px;padding:16px;display:flex;flex-direction:column;}
    .kpis b{font-size:26px;font-weight:800;} .kpis span{font-size:12px;color:var(--text-2);}
  `]
})
export class VoyageursComponent implements OnInit {
  auth    = inject(AuthService);
  private api   = inject(ApiService);
  private toast = inject(ToastService);
  voyageurs = signal<User[]>([]);
  total     = signal(0);
  page      = signal(1);
  loading   = signal(false);
  selected  = signal<User | null>(null);
  search = ''; filtreVerif = ''; filtreActif = '';
  readonly pageSize = 20;
  search$ = new Subject<string>();

  ngOnInit(): void {
    this.search$.pipe(debounceTime(400), distinctUntilChanged()).subscribe(() => { this.page.set(1); this.load(); });
    this.load();
  }
  onFiltreChange(): void { this.page.set(1); this.load(); }
  onPage(p: number): void { this.page.set(p); this.load(); }

  load(): void {
    this.loading.set(true);
    const p: Record<string, string> = { page: String(this.page()), role: 'voyageur' };
    if (this.search)      p['search']      = this.search;
    if (this.filtreVerif) p['is_verified'] = this.filtreVerif;
    if (this.filtreActif) p['is_active']   = this.filtreActif;
    this.api.getUtilisateurs(p).subscribe({
      next: res => { this.voyageurs.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  toggleActif(u: User): void {
    this.api.toggleUserActif(u.id, u.is_active === false).subscribe({
      next: () => { this.toast.success(u.is_active === false ? 'Compte réactivé.' : 'Compte désactivé.'); this.load(); },
      error: () => this.toast.error('Erreur lors de la mise à jour.')
    });
  }
  exportCsv(): void {
    const csv = ['Nom,Email,Téléphone,Voyages,Points,Vérifié,Inscrit',
      ...this.voyageurs().map(u => [u.nom_complet,u.email,u.telephone,u.nb_voyages,u.points_fidelite,u.is_verified,u.date_inscription].join(','))].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    Object.assign(document.createElement('a'), { href: url, download: 'voyageurs.csv' }).click();
    URL.revokeObjectURL(url);
  }
}
