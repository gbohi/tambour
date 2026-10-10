import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Transporteur } from '../../core/models/transport.model';

@Component({
  selector: 'app-transporteurs',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Transporteurs partenaires</h1><p class="page-subtitle">{{ total() }} partenaires</p></div>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreVerif" (change)="onFiltreChange()">
          <option value="">Tous</option>
          <option value="true">Vérifiés</option>
          <option value="false">En attente</option>
        </select>
      </div>
      @if (loading()) {
        <div class="tg"><div class="skeleton-card" style="height:200px;border-radius:16px" *ngFor="let i of [1,2,3,4,5,6]"></div></div>
      } @else {
        <div class="tg">
          @for (t of transporteurs(); track t.id) {
            <div class="tc" (click)="selected.set(t)">
              <div class="tc-hd">
                <div class="tc-lg">{{ t.nom[0] }}</div>
                <div>
                  @if (t.est_verifie) { <span class="badge badge-success">&#10003; Vérifié</span> }
                  @else { <span class="badge badge-warning">&#9203; En attente</span> }
                  @if (!t.est_actif) { <span class="badge badge-error" style="margin-left:4px">Inactif</span> }
                </div>
              </div>
              <h3 class="tc-nom">{{ t.nom }}</h3>
              <div class="tc-note">
                <span style="color:var(--gold)">{{ stars(+t.note_moyenne) }}</span>
                <span style="font-size:12px;color:var(--text-2)">{{ t.note_moyenne }}/5</span>
              </div>
              <div class="tc-meta">
                <span>&#128231; {{ t.email }}</span>
                <span>&#128222; {{ t.telephone }}</span>
                <span>&#128176; Commission {{ t.taux_commission }}%</span>
              </div>
              <div class="tc-act" (click)="$event.stopPropagation()">
                @if (!t.est_verifie) {
                  <button class="btn btn-primary btn-sm" (click)="verifier(t)">&#10003; Vérifier</button>
                } @else {
                  <button class="btn btn-ghost btn-sm" (click)="verifier(t, false)">Retirer vérif.</button>
                }
                <button class="btn btn-sm" [class.btn-danger]="t.est_actif" [class.btn-outline]="!t.est_actif" (click)="toggleActif(t)">
                  {{ t.est_actif ? 'Désactiver' : 'Réactiver' }}
                </button>
              </div>
            </div>
          } @empty {
            <div class="empty-state" style="grid-column:1/-1"><div class="empty-icon">🚌</div><h3>Aucun transporteur</h3></div>
          }
        </div>
        <div style="background:var(--surface);border:0.5px solid var(--border);border-radius:var(--radius-lg);overflow:hidden">
          <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
        </div>
      }
    </div>
    @if (selected()) {
      <div class="modal-backdrop" (click)="selected.set(null)">
        <div class="modal" style="max-width:520px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div><div class="modal-title">{{ selected()!.nom }}</div><div style="font-size:13px;color:var(--text-2)">RCCM : {{ selected()!.rccm || '—' }}</div></div>
            <button class="modal-close" (click)="selected.set(null)">&#215;</button>
          </div>
          <div class="modal-body">
            <div class="info-row"><span class="info-label">Email</span><span class="info-value">{{ selected()!.email }}</span></div>
            <div class="info-row"><span class="info-label">Téléphone</span><span class="info-value">{{ selected()!.telephone }}</span></div>
            <div class="info-row"><span class="info-label">Adresse</span><span class="info-value">{{ selected()!.adresse || '—' }}</span></div>
            <div class="info-row"><span class="info-label">Commission</span><span class="info-value">{{ selected()!.taux_commission }}%</span></div>
            <div class="info-row"><span class="info-label">Note</span><span class="info-value">{{ stars(+selected()!.note_moyenne) }} {{ selected()!.note_moyenne }}/5</span></div>
            <div class="info-row"><span class="info-label">Partenaire depuis</span><span class="info-value">{{ selected()!.created_at | date:'dd/MM/yyyy' }}</span></div>
          </div>
          <div class="modal-footer"><button class="btn btn-ghost" (click)="selected.set(null)">Fermer</button></div>
        </div>
      </div>
    }
  `,
  styles: [`
    .tg{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:16px;}
    .tc{background:var(--surface);border:0.5px solid var(--border);border-radius:16px;padding:20px;cursor:pointer;transition:all 0.15s;box-shadow:var(--shadow-sm);}
    .tc:hover{box-shadow:var(--shadow-md);border-color:var(--primary);transform:translateY(-2px);}
    .tc-hd{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;}
    .tc-lg{width:44px;height:44px;border-radius:12px;background:var(--primary);color:#fff;display:flex;align-items:center;justify-content:center;font-size:20px;font-weight:800;}
    .tc-nom{font-size:16px;font-weight:700;margin-bottom:6px;}
    .tc-note{display:flex;align-items:center;gap:6px;margin-bottom:10px;}
    .tc-meta{display:flex;flex-direction:column;gap:4px;font-size:12px;color:var(--text-2);margin-bottom:14px;}
    .tc-act{display:flex;gap:6px;}
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
