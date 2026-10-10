import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Trajet } from '../../core/models/transport.model';

@Component({
  selector: 'app-trajets',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Trajets</h1><p class="page-subtitle">{{ total() }} trajets</p></div>
        <div class="header-actions">
          <input type="date" class="form-control btn-sm" [(ngModel)]="filtreDate" (change)="onFiltreChange()" style="width:auto">
          <select class="form-control" [(ngModel)]="filtreStatut" (change)="onFiltreChange()" style="width:auto">
            <option value="">Tous statuts</option>
            <option value="planifie">Planifié</option>
            <option value="en_cours">En cours</option>
            <option value="termine">Terminé</option>
            <option value="annule">Annulé</option>
            <option value="retarde">Retardé</option>
          </select>
        </div>
      </div>
      <div class="filters">
        <div class="search-box">
          <span class="search-icon">&#128269;</span>
          <input type="text" class="form-control" placeholder="Ville, compagnie..."
            [(ngModel)]="search" (ngModelChange)="search$.next($event)">
        </div>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreClasse" (change)="onFiltreChange()">
          <option value="">Toutes classes</option>
          <option value="standard">Standard</option>
          <option value="confort">Confort</option>
          <option value="vip">VIP</option>
        </select>
      </div>
      <div class="table-card">
        @if (loading()) {
          <div style="padding:48px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
        } @else {
          <div class="table-container">
            <table>
              <thead><tr>
                <th>Trajet</th><th>Compagnie</th><th>Départ</th><th>Classe</th>
                <th>Prix</th><th>Places</th><th>Statut</th><th>Note</th>
                @if (canManage()) { <th>Actions</th> }
              </tr></thead>
              <tbody>
                @for (t of trajets(); track t.id) {
                  <tr>
                    <td>
                      <div style="font-weight:600">{{ t.depart_nom }} &#8594; {{ t.arrivee_nom }}</div>
                      <div style="font-size:11px;color:var(--text-2)">{{ t.bus_immatriculation }} &middot; {{ t.duree_label }}</div>
                    </td>
                    <td>{{ t.compagnie }}</td>
                    <td>{{ t.heure_depart | date:'dd/MM HH:mm' }}</td>
                    <td><span class="badge" [ngClass]="classBadge(t.bus_classe)">{{ t.bus_classe }}</span></td>
                    <td>
                      <strong style="color:var(--primary)">{{ t.prix_actuel | number:'1.0-0' }} F</strong>
                      @if (t.est_en_promo) { <span class="badge badge-gold" style="margin-left:4px">Promo</span> }
                    </td>
                    <td>
                      <div class="pb"><div class="pbf" [style.width.%]="placesPct(t)" [style.background]="t.places_disponibles < 5 ? 'var(--error)' : 'var(--primary)'"></div></div>
                      <div style="font-size:11px;color:var(--text-2)">{{ t.places_disponibles }}/{{ t.places_total }}</div>
                    </td>
                    <td><span class="badge" [ngClass]="statutBadge(t.statut)">{{ statutLabel(t.statut) }}</span></td>
                    <td>
                      @if (+t.note_moyenne > 0) { <span style="color:var(--gold);font-weight:700">&#9733; {{ t.note_moyenne }}</span> }
                      @else { <span class="text-hint">—</span> }
                    </td>
                    @if (canManage()) {
                      <td (click)="$event.stopPropagation()">
                        <div style="display:flex;gap:4px">
                          @if (t.statut === 'planifie' || t.statut === 'en_cours') {
                            <button class="btn btn-ghost btn-sm" (click)="openRetard(t)">&#9200; Retard</button>
                            <button class="btn btn-danger btn-sm" (click)="openAnnuler(t)">&#10005;</button>
                          }
                        </div>
                      </td>
                    }
                  </tr>
                } @empty {
                  <tr><td [attr.colspan]="canManage() ? 9 : 8">
                    <div class="empty-state"><div class="empty-icon">🚌</div><h3>Aucun trajet</h3><p>Modifiez les filtres.</p></div>
                  </td></tr>
                }
              </tbody>
            </table>
          </div>
          <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
        }
      </div>
    </div>
    @if (trajetRetard()) {
      <div class="modal-backdrop" (click)="trajetRetard.set(null)">
        <div class="modal" style="max-width:420px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div class="modal-title">&#9200; Signaler un retard</div><button class="modal-close" (click)="trajetRetard.set(null)">&#215;</button></div>
          <div class="modal-body">
            <p style="color:var(--text-2);margin-bottom:16px">{{ trajetRetard()!.depart_nom }} &#8594; {{ trajetRetard()!.arrivee_nom }}</p>
            <div class="form-group">
              <label class="form-label">Durée du retard (minutes)</label>
              <input type="number" class="form-control" [(ngModel)]="retardMin" min="5" max="480">
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="trajetRetard.set(null)">Annuler</button>
            <button class="btn btn-primary" (click)="confirmerRetard()">Signaler</button>
          </div>
        </div>
      </div>
    }
    @if (trajetAnnuler()) {
      <div class="modal-backdrop" (click)="trajetAnnuler.set(null)">
        <div class="modal" style="max-width:420px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div class="modal-title">&#10005; Annuler le trajet</div><button class="modal-close" (click)="trajetAnnuler.set(null)">&#215;</button></div>
          <div class="modal-body">
            <div style="background:var(--error-bg);border:1px solid rgba(217,64,64,0.2);border-radius:10px;padding:12px;color:var(--error);font-size:13px;margin-bottom:16px">
              &#9888; Cette action est irréversible. Les voyageurs seront remboursés.
            </div>
            <div class="form-group">
              <label class="form-label">Motif</label>
              <textarea class="form-control" [(ngModel)]="motifAnnulation" rows="3" placeholder="Ex: Panne mécanique…"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="trajetAnnuler.set(null)">Annuler</button>
            <button class="btn btn-danger" (click)="confirmerAnnulation()" [disabled]="!motifAnnulation">Confirmer</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`.pb{height:5px;background:var(--surface-2);border-radius:3px;overflow:hidden;margin-bottom:3px;}.pbf{height:100%;border-radius:3px;transition:width 0.4s;}`]
})
export class TrajetsComponent implements OnInit {
  auth    = inject(AuthService);
  private api   = inject(ApiService);
  private toast = inject(ToastService);
  trajets = signal<Trajet[]>([]);
  total = signal(0); page = signal(1); loading = signal(false);
  trajetRetard  = signal<Trajet | null>(null);
  trajetAnnuler = signal<Trajet | null>(null);
  search = ''; filtreStatut = ''; filtreDate = ''; filtreClasse = '';
  retardMin = 30; motifAnnulation = '';
  readonly pageSize = 20;
  search$ = new Subject<string>();

  ngOnInit(): void {
    this.search$.pipe(debounceTime(400), distinctUntilChanged()).subscribe(() => { this.page.set(1); this.load(); });
    this.load();
  }
  canManage(): boolean { return this.auth.hasRole('admin','support','transporteur'); }
  onFiltreChange(): void { this.page.set(1); this.load(); }
  onPage(p: number): void { this.page.set(p); this.load(); }
  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = { page: String(this.page()) };
    if (this.search)       p['search']  = this.search;
    if (this.filtreStatut) p['statut']  = this.filtreStatut;
    if (this.filtreDate)   p['date']    = this.filtreDate;
    if (this.filtreClasse) p['classe']  = this.filtreClasse;
    this.api.getTrajets(p).subscribe({
      next: res => { this.trajets.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  openRetard(t: Trajet): void { this.trajetRetard.set(t); this.retardMin = 30; }
  openAnnuler(t: Trajet): void { this.trajetAnnuler.set(t); this.motifAnnulation = ''; }
  confirmerRetard(): void {
    const t = this.trajetRetard();
    if (!t) return;
    this.api.signalerRetard(t.id, this.retardMin).subscribe({
      next: () => { this.toast.success('Retard signalé.'); this.trajetRetard.set(null); this.load(); },
      error: () => this.toast.error("Erreur lors du signalement.")
    });
  }
  confirmerAnnulation(): void {
    const t = this.trajetAnnuler();
    if (!t) return;
    this.api.annulerTrajet(t.id, this.motifAnnulation).subscribe({
      next: () => { this.toast.success('Trajet annulé.'); this.trajetAnnuler.set(null); this.load(); },
      error: () => this.toast.error("Erreur lors de l'annulation.")
    });
  }
  placesPct(t: Trajet): number { return t.places_total ? (t.places_total-t.places_disponibles)/t.places_total*100 : 0; }
  classBadge(c: string): string { const m: Record<string,string> = { vip:'badge-gold', confort:'badge-primary', standard:'badge-neutral' }; return m[c] ?? 'badge-neutral'; }
  statutLabel(s: string): string { const m: Record<string,string> = { planifie:'Planifié', en_cours:'En cours', termine:'Terminé', annule:'Annulé', retarde:'Retardé' }; return m[s] ?? s; }
  statutBadge(s: string): string { const m: Record<string,string> = { planifie:'badge-info', en_cours:'badge-success', termine:'badge-neutral', annule:'badge-error', retarde:'badge-warning' }; return m[s] ?? 'badge-neutral'; }
}
