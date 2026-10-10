import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { User } from '../../core/models/user.model';

@Component({
  selector: 'app-voyageurs',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Voyageurs</h1><p class="page-subtitle">{{ total() }} voyageurs enregistrés</p></div>
        <button class="btn btn-ghost btn-sm" (click)="exportCsv()">&#128229; CSV</button>
      </div>
      <div class="filters">
        <div class="search-box">
          <span class="search-icon">&#128269;</span>
          <input type="text" class="form-control" placeholder="Nom, email, téléphone..."
            [(ngModel)]="search" (ngModelChange)="search$.next($event)">
        </div>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreVerif" (change)="onFiltreChange()">
          <option value="">Email vérifié (tous)</option>
          <option value="true">Vérifié</option>
          <option value="false">Non vérifié</option>
        </select>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreActif" (change)="onFiltreChange()">
          <option value="">Statut (tous)</option>
          <option value="true">Actifs</option>
          <option value="false">Désactivés</option>
        </select>
      </div>
      <div class="table-card">
        @if (loading()) {
          <div style="padding:48px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
        } @else {
          <div class="table-container">
            <table>
              <thead><tr>
                <th>Voyageur</th><th>Contact</th><th>Voyages</th><th>Points</th>
                <th>Vérifié</th><th>Statut</th><th>Inscrit le</th>
                @if (auth.isAdmin()) { <th>Actions</th> }
              </tr></thead>
              <tbody>
                @for (u of voyageurs(); track u.id) {
                  <tr class="clickable" (click)="selected.set(u)">
                    <td>
                      <div style="display:flex;align-items:center;gap:10px">
                        <div class="avatar">{{ u.initiales }}</div>
                        <div>
                          <div style="font-weight:600">{{ u.nom_complet }}</div>
                          <div style="font-size:11px;color:var(--text-2)">{{ u.email }}</div>
                        </div>
                      </div>
                    </td>
                    <td>{{ u.telephone || '—' }}</td>
                    <td><strong>{{ u.nb_voyages }}</strong></td>
                    <td><span class="badge badge-gold">&#11088; {{ u.points_fidelite }}</span></td>
                    <td>
                      @if (u.is_verified) { <span class="badge badge-success">&#10003; Vérifié</span> }
                      @else { <span class="badge badge-warning">&#9203; En attente</span> }
                    </td>
                    <td>
                      @if (u.is_active !== false) { <span class="badge badge-success">Actif</span> }
                      @else { <span class="badge badge-error">Désactivé</span> }
                    </td>
                    <td style="color:var(--text-2)">{{ u.date_inscription | date:'dd/MM/yyyy' }}</td>
                    @if (auth.isAdmin()) {
                      <td (click)="$event.stopPropagation()">
                        <button class="btn btn-sm"
                          [class.btn-danger]="u.is_active !== false"
                          [class.btn-outline]="u.is_active === false"
                          (click)="toggleActif(u)">
                          {{ u.is_active !== false ? 'Désactiver' : 'Réactiver' }}
                        </button>
                      </td>
                    }
                  </tr>
                } @empty {
                  <tr><td [attr.colspan]="auth.isAdmin() ? 8 : 7">
                    <div class="empty-state"><div class="empty-icon">👥</div><h3>Aucun voyageur</h3><p>Modifiez les filtres.</p></div>
                  </td></tr>
                }
              </tbody>
            </table>
          </div>
          <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
        }
      </div>
    </div>
    @if (selected()) {
      <div class="modal-backdrop" (click)="selected.set(null)">
        <div class="modal" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div style="display:flex;align-items:center;gap:12px">
              <div class="avatar avatar-lg">{{ selected()!.initiales }}</div>
              <div><div class="modal-title">{{ selected()!.nom_complet }}</div><div style="font-size:13px;color:var(--text-2)">{{ selected()!.email }}</div></div>
            </div>
            <button class="modal-close" (click)="selected.set(null)">&#215;</button>
          </div>
          <div class="modal-body">
            <div class="info-box" style="margin-bottom:16px;display:flex;gap:24px">
              <div style="text-align:center"><div style="font-size:22px;font-weight:800;color:var(--primary)">{{ selected()!.nb_voyages }}</div><div style="font-size:11px;color:var(--text-2)">Voyages</div></div>
              <div style="text-align:center"><div style="font-size:22px;font-weight:800;color:var(--gold)">{{ selected()!.points_fidelite }}</div><div style="font-size:11px;color:var(--text-2)">Points</div></div>
            </div>
            <div class="info-row"><span class="info-label">Téléphone</span><span class="info-value">{{ selected()!.telephone || '—' }}</span></div>
            <div class="info-row"><span class="info-label">SMS</span><span class="info-value">{{ selected()!.notif_sms ? 'Activé' : 'Désactivé' }}</span></div>
            <div class="info-row"><span class="info-label">Email notif.</span><span class="info-value">{{ selected()!.notif_email ? 'Activé' : 'Désactivé' }}</span></div>
            <div class="info-row"><span class="info-label">Inscrit le</span><span class="info-value">{{ selected()!.date_inscription | date:'dd/MM/yyyy' }}</span></div>
          </div>
          <div class="modal-footer"><button class="btn btn-ghost" (click)="selected.set(null)">Fermer</button></div>
        </div>
      </div>
    }
  `
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
