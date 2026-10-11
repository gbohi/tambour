import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Transporteur } from '../../core/models/transport.model';

@Component({
  selector: 'app-transporteurs',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Compagnies partenaires</h1><p class="page-subtitle">{{ total() | nb }} compagnies de transport</p></div>
        <div class="segmented">
          <button [class.active]="filtreVerif === ''" (click)="filtreVerif = ''; onFiltreChange()">Toutes</button>
          <button [class.active]="filtreVerif === 'true'" (click)="filtreVerif = 'true'; onFiltreChange()">Vérifiées</button>
          <button [class.active]="filtreVerif === 'false'" (click)="filtreVerif = 'false'; onFiltreChange()">À vérifier</button>
        </div>
      </div>
      @if (loading()) {
        <div class="grille">@for (i of [1,2,3]; track i) { <div class="skeleton" style="height:220px;border-radius:16px"></div> }</div>
      } @else {
        <div class="grille">
          @for (t of transporteurs(); track t.id) {
            <article class="carte" (click)="selected.set(t)">
              <div class="haut">
                <div class="logo">{{ t.nom[0] }}</div>
                <div class="titre"><h3>{{ t.nom }}</h3>
                  <div class="note"><tb-icon name="star" [size]="14" /> {{ t.note_moyenne }} <span>/ 5</span></div></div>
                @if (t.est_verifie) { <span class="badge badge-success">Vérifiée</span> } @else { <span class="badge badge-warning">À vérifier</span> }
              </div>
              <ul class="infos">
                <li><tb-icon name="mail" [size]="15" /> {{ t.email }}</li>
                <li><tb-icon name="phone" [size]="15" /> {{ t.telephone }}</li>
                <li><tb-icon name="banknote" [size]="15" /> Commission {{ t.taux_commission }} %</li>
              </ul>
              <div class="actions" (click)="$event.stopPropagation()">
                @if (!t.est_verifie) {
                  <button class="btn btn-primary btn-sm" (click)="verifier(t)"><tb-icon name="shield" [size]="15" /> Vérifier</button>
                } @else {
                  <button class="btn btn-ghost btn-sm" (click)="verifier(t, false)">Retirer la vérification</button>
                }
                <span style="flex:1"></span>
                @if (!t.est_actif) { <span class="badge badge-error">Inactive</span> }
                <button class="icon-btn" [class.danger]="t.est_actif" [class.success]="!t.est_actif"
                  [attr.data-tip]="t.est_actif ? 'Désactiver' : 'Réactiver'" (click)="toggleActif(t)">
                  <tb-icon [name]="t.est_actif ? 'x-circle' : 'check-circle'" />
                </button>
              </div>
            </article>
          } @empty {
            <div class="card empty-state" style="grid-column:1/-1"><div class="empty-icon"><tb-icon name="building" [size]="26" /></div><h3>Aucune compagnie</h3></div>
          }
        </div>
        @if (total() > pageSize) {
          <div class="table-card"><app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" /></div>
        }
      }
    </div>

    @if (selected(); as t) {
      <div class="drawer-backdrop" (click)="selected.set(null)"></div>
      <aside class="drawer">
        <div class="drawer-header">
          <div class="cell-flex"><div class="logo">{{ t.nom[0] }}</div>
            <div><div class="modal-title">{{ t.nom }}</div><div class="cell-sub">RCCM : {{ t.rccm || 'non renseigné' }}</div></div></div>
          <button class="modal-close" (click)="selected.set(null)"><tb-icon name="x" /></button>
        </div>
        <div class="drawer-body">
          <div>
            <div class="info-row"><span class="info-label">Email</span><span class="info-value">{{ t.email }}</span></div>
            <div class="info-row"><span class="info-label">Téléphone</span><span class="info-value">{{ t.telephone }}</span></div>
            <div class="info-row"><span class="info-label">Adresse</span><span class="info-value">{{ t.adresse || '—' }}</span></div>
            <div class="info-row"><span class="info-label">Commission TamBour</span><span class="info-value">{{ t.taux_commission }} %</span></div>
            <div class="info-row"><span class="info-label">Note des voyageurs</span><span class="info-value text-gold">★ {{ t.note_moyenne }} / 5</span></div>
            <div class="info-row"><span class="info-label">Partenaire depuis</span><span class="info-value">{{ t.created_at | date:'d MMMM yyyy' }}</span></div>
          </div>
        </div>
        <div class="drawer-footer"><button class="btn btn-ghost" (click)="selected.set(null)">Fermer</button></div>
      </aside>
    }
  `,
  styles: [`
    .grille{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:18px;}
    .carte{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-lg);padding:20px;display:flex;flex-direction:column;gap:16px;
      cursor:pointer;transition:border-color .15s,box-shadow .15s,transform .15s;}
    .carte:hover{border-color:#CFD8D3;box-shadow:var(--shadow-md);transform:translateY(-2px);}
    .haut{display:flex;align-items:flex-start;gap:12px;}
    .logo{width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,var(--ink),#2B4A3E);color:#fff;font-size:20px;font-weight:800;
      display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .titre{flex:1;min-width:0;}
    .titre h3{font-size:17px;font-weight:800;}
    .note{display:flex;align-items:center;gap:4px;color:var(--gold-dark);font-weight:700;font-size:13px;}
    .note span{color:var(--text-3);font-weight:500;}
    .infos{list-style:none;display:flex;flex-direction:column;gap:8px;font-size:13px;color:var(--text-2);}
    .infos li{display:flex;align-items:center;gap:8px;}
    .actions{display:flex;align-items:center;gap:8px;padding-top:14px;border-top:1px solid var(--divider);}
  `]
})
export class TransporteursComponent implements OnInit {
  private api   = inject(ApiService);
  private toast = inject(ToastService);
  transporteurs = signal<Transporteur[]>([]);
  total   = signal(0); page = signal(1); loading = signal(false);
  selected = signal<Transporteur | null>(null);
  filtreVerif = ''; readonly pageSize = 12;

  ngOnInit() { this.load(); }
  onFiltreChange(): void { this.page.set(1); this.load(); }
  onPage(p: number): void { this.page.set(p); this.load(); }
  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = { page: String(this.page()) };
    if (this.filtreVerif) p['est_verifie'] = this.filtreVerif;
    this.api.getTransporteurs(p).subscribe({
      next: res => { this.transporteurs.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  verifier(t: Transporteur, v = true): void {
    this.api.verifierTransporteur(t.id, v).subscribe({
      next: () => { this.toast.success(v ? 'Transporteur vérifié.' : 'Vérification retirée.'); this.load(); },
      error: () => this.toast.error('Erreur lors de la mise à jour.')
    });
  }
  toggleActif(t: Transporteur): void {
    this.api.toggleTransporteurActif(t.id, !t.est_actif).subscribe({
      next: () => { this.toast.success(t.est_actif ? 'Désactivé.' : 'Réactivé.'); this.load(); },
      error: () => this.toast.error('Erreur lors de la mise à jour.')
    });
  }
  stars(n: number): string { const k = Math.min(5, Math.max(0, Math.round(n))); return '★'.repeat(k)+'☆'.repeat(5-k); }
}
