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
import { Reservation, Passager, Billet } from '../../core/models/reservation.model';

@Component({
  selector: 'app-reservations',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Réservations</h1><p class="page-subtitle">{{ total() | nb }} réservations</p></div>
        <button class="btn btn-secondary" (click)="exportCsv()"><tb-icon name="download" [size]="16" /> Exporter (CSV)</button>
      </div>

      <div class="table-card">
        <div class="toolbar">
          <div class="search-box">
            <span class="search-icon"><tb-icon name="search" [size]="16" /></span>
            <input type="text" class="form-control" placeholder="Référence, nom, email…" [(ngModel)]="search" (ngModelChange)="search$.next($event)">
          </div>
          <div class="segmented">
            @for (s of statuts; track s.code) {
              <button [class.active]="filtreStatut === s.code" (click)="filtreStatut = s.code; onFiltreChange()">{{ s.label }}</button>
            }
          </div>
          <span class="spacer"></span>
          <input type="date" class="form-control" [(ngModel)]="filtreDate" (change)="onFiltreChange()" title="Date du voyage">
        </div>
        <div class="table-container">
          <table>
            <thead><tr><th>Référence</th><th>Voyageur</th><th>Voyage</th><th>Passagers</th><th class="right">Montant</th><th>Statut</th><th class="right"></th></tr></thead>
            <tbody>
              @if (loading()) {
                <tr><td colspan="7"><div class="loading-row"><span class="spinner"></span></div></td></tr>
              } @else {
                @for (r of reservations(); track r.id) {
                  <tr class="clickable" (click)="ouvrirDetail(r)">
                    <td><div class="mono cell-main">{{ r.reference }}</div><div class="cell-sub">{{ r.created_at | date:'d MMM, HH:mm' }}</div></td>
                    <td><div class="cell-main">{{ r.user_info?.nom_complet }}</div><div class="cell-sub">{{ r.user_info?.telephone || r.user_info?.email }}</div></td>
                    <td><div class="route">{{ r.trajet_info.depart }} <span class="arrow"><tb-icon name="arrow-right" [size]="14" /></span> {{ r.trajet_info.arrivee }}</div>
                      <div class="cell-sub">{{ r.trajet_info.heure_depart | date:'EEE d MMM, HH:mm' }} · {{ r.trajet_info.compagnie }}</div></td>
                    <td><span class="chip"><tb-icon name="users" [size]="14" /> {{ r.nb_passagers }}</span></td>
                    <td class="right"><span class="amount">{{ r.montant_total | nb:'F' }}</span></td>
                    <td><span class="badge" [ngClass]="statutBadge(r.statut)">{{ statutLabel(r.statut) }}</span></td>
                    <td class="right" (click)="$event.stopPropagation()">
                      <div class="row-actions">
                        <button class="icon-btn" data-tip="Voir le détail" (click)="ouvrirDetail(r)"><tb-icon name="eye" /></button>
                        @if (r.peut_etre_annulee && auth.isAdminOrSupport()) {
                          <button class="icon-btn danger" data-tip="Annuler" (click)="ouvrirAnnuler(r)"><tb-icon name="x-circle" /></button>
                        }
                      </div>
                    </td>
                  </tr>
                } @empty {
                  <tr><td colspan="7"><div class="empty-state"><div class="empty-icon"><tb-icon name="ticket" [size]="26" /></div>
                    <h3>Aucune réservation</h3><p>Modifiez les filtres.</p></div></td></tr>
                }
              }
            </tbody>
          </table>
        </div>
        <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
      </div>
    </div>

    @if (selected(); as r) {
      <div class="drawer-backdrop" (click)="closeDetail()"></div>
      <aside class="drawer">
        <div class="drawer-header">
          <div><div class="mono text-muted">{{ r.reference }}</div>
            <div class="modal-title">{{ r.trajet_info.depart }} → {{ r.trajet_info.arrivee }}</div>
            <div class="cell-sub">{{ r.trajet_info.heure_depart | date:'EEEE d MMMM yyyy, HH:mm' }} · {{ r.trajet_info.compagnie }}</div></div>
          <button class="modal-close" (click)="closeDetail()"><tb-icon name="x" /></button>
        </div>
        <div class="drawer-body">
          <div class="resume">
            <div><span>Statut</span><span class="badge" [ngClass]="statutBadge(r.statut)">{{ statutLabel(r.statut) }}</span></div>
            <div><span>Montant</span><b>{{ r.montant_total | nb:'FCFA' }}</b></div>
            <div><span>Réservée le</span><b>{{ r.created_at | date:'d MMM yyyy, HH:mm' }}</b></div>
            @if (r.montant_rembourse) { <div><span>Remboursé</span><b>{{ r.montant_rembourse | nb:'FCFA' }}</b></div> }
          </div>
          <div>
            <div class="section-titre">Payeur</div>
            <div class="payeur"><div class="avatar">{{ initiales(r.user_info?.nom_complet) }}</div>
              <div><b>{{ r.user_info?.nom_complet }}</b><div class="cell-sub">{{ r.user_info?.telephone }} · {{ r.email_payeur || r.user_info?.email }}</div></div></div>
          </div>
          <div>
            <div class="section-titre">Billets ({{ detail()?.passagers?.length ?? r.nb_passagers }})</div>
            @if (detailLoading()) { <div class="loading-row"><span class="spinner"></span></div> }
            @for (p of detail()?.passagers ?? []; track p.id) {
              <div class="billet">
                <div class="siege">{{ p.siege_numero }}</div>
                <div class="qui"><b>{{ p.prenom }} {{ p.nom }}</b><span class="mono">{{ p.billet?.reference_billet }}</span></div>
                @if (p.billet && !p.billet.est_valide) {
                  <span class="badge badge-success">À bord</span>
                } @else if (p.billet && r.statut === 'confirmee' && (auth.isAdminOrSupport() || auth.isTransporteur())) {
                  <button class="btn btn-outline btn-sm" (click)="validerBillet(r.id, p.id)"><tb-icon name="check" [size]="14" /> Embarquer</button>
                } @else { <span class="badge badge-neutral">Non embarqué</span> }
              </div>
            }
          </div>
        </div>
        <div class="drawer-footer">
          @if (r.peut_etre_annulee && auth.isAdminOrSupport()) {
            <button class="btn btn-danger" (click)="ouvrirAnnuler(r); closeDetail()"><tb-icon name="x-circle" [size]="16" /> Annuler la réservation</button>
          }
          <span style="flex:1"></span>
          <button class="btn btn-ghost" (click)="closeDetail()">Fermer</button>
        </div>
      </aside>
    }

    @if (resAnnuler(); as r) {
      <div class="modal-backdrop" (click)="resAnnuler.set(null)">
        <div class="modal" style="max-width:460px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div><div class="modal-title">Annuler la réservation</div><div class="cell-sub mono">{{ r.reference }}</div></div>
            <button class="modal-close" (click)="resAnnuler.set(null)"><tb-icon name="x" /></button></div>
          <div class="modal-body">
            <div class="info-box">Remboursement prévu : <b>{{ r.montant_remboursable | nb:'FCFA' }}</b> (selon le délai avant le départ).</div>
            <div class="form-group"><label class="form-label">Motif</label>
              <textarea class="form-control" rows="3" [(ngModel)]="motifAnnulation" placeholder="Ex. : demande du client"></textarea></div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="resAnnuler.set(null)">Retour</button>
            <button class="btn btn-danger-solid btn" (click)="confirmerAnnulation()">Confirmer l'annulation</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .resume{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
    .resume > div{background:var(--surface-2);border-radius:12px;padding:12px 14px;display:flex;flex-direction:column;gap:6px;font-size:13px;}
    .resume span:first-child{color:var(--text-2);font-size:12px;}
    .resume b{font-size:15px;}
    .payeur{display:flex;align-items:center;gap:12px;margin-top:10px;}
    .billet{display:flex;align-items:center;gap:12px;padding:10px 12px;border:1px solid var(--border);border-radius:12px;margin-top:8px;}
    .siege{width:42px;height:42px;border-radius:10px;background:var(--primary-light);color:var(--primary);font-weight:800;display:flex;align-items:center;justify-content:center;}
    .qui{flex:1;display:flex;flex-direction:column;min-width:0;}
    .qui span{font-size:12px;color:var(--text-2);}
  `]
})
export class ReservationsComponent implements OnInit {
  auth    = inject(AuthService);
  private api   = inject(ApiService);
  private toast = inject(ToastService);

  reservations  = signal<Reservation[]>([]);
  total         = signal(0);
  page          = signal(1);
  loading       = signal(false);
  selected      = signal<Reservation | null>(null);
  detail        = signal<Reservation | null>(null);
  detailLoading = signal(false);
  resAnnuler    = signal<Reservation | null>(null);
  motifAnnulation = '';
  search = ''; filtreStatut = ''; filtreDate = '';
  readonly statuts = [
    { code: '', label: 'Toutes' }, { code: 'confirmee', label: 'Confirmées' },
    { code: 'en_attente', label: 'En attente' }, { code: 'annulee', label: 'Annulées' },
  ];
  initiales(nom?: string): string { return (nom ?? '').split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase(); }
  readonly pageSize = 20;
  search$ = new Subject<string>();

  ngOnInit(): void {
    this.search$.pipe(debounceTime(400), distinctUntilChanged())
      .subscribe(() => { this.page.set(1); this.load(); });
    this.load();
  }

  onFiltreChange(): void { this.page.set(1); this.load(); }
  onPage(p: number): void { this.page.set(p); this.load(); }

  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = { page: String(this.page()) };
    if (this.search)       p['search']  = this.search;
    if (this.filtreStatut) p['statut']  = this.filtreStatut;
    if (this.filtreDate)   p['date']    = this.filtreDate;
    this.api.getReservations(p).subscribe({
      next: res => { this.reservations.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }

  ouvrirDetail(r: Reservation): void {
    this.selected.set(r); this.detail.set(null); this.detailLoading.set(true);
    this.api.getReservation(r.id).subscribe({
      next: res => { this.detail.set(res.data); this.detailLoading.set(false); },
      error: () => this.detailLoading.set(false)
    });
  }

  ouvrirBillets(r: Reservation): void {
    // Ouvre le détail avec focus sur les billets
    this.ouvrirDetail(r);
  }

  closeDetail(): void { this.selected.set(null); this.detail.set(null); }

  validerBillet(reservationId: string, passagerId: string): void {
    this.api.validerQr(reservationId, passagerId).subscribe({
      next: (res: any) => {
        this.toast.success('Billet validé — ' + (res.data?.reference_billet ?? ''));
        this.ouvrirDetail(this.selected()!);
      },
      error: (err: any) => this.toast.error(err?.error?.message ?? 'Erreur QR.')
    });
  }

  ouvrirAnnuler(r: Reservation): void { this.resAnnuler.set(r); this.motifAnnulation = ''; }

  confirmerAnnulation(): void {
    const r = this.resAnnuler();
    if (!r) return;
    this.api.annulerReservation(r.id, this.motifAnnulation).subscribe({
      next: () => { this.toast.success('Réservation annulée.'); this.resAnnuler.set(null); this.load(); },
      error: (err: any) => this.toast.error(err?.error?.message ?? "Erreur lors de l'annulation.")
    });
  }

  exportCsv(): void {
    const csv = ['Référence,Départ,Arrivée,Passagers,Montant,Email payeur,Statut,Date',
      ...this.reservations().map(r =>
        [r.reference, r.trajet_info.depart, r.trajet_info.arrivee,
         r.nb_passagers, r.montant_total, r.email_payeur, r.statut, r.created_at].join(',')
      )].join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    Object.assign(document.createElement('a'), { href: url, download: 'reservations.csv' }).click();
    URL.revokeObjectURL(url);
  }

  statutLabel(s: string): string {
    const m: Record<string,string> = {
      en_attente:'En attente', confirmee:'Confirmée',
      annulee:'Annulée', expiree:'Expirée', remboursee:'Remboursée'
    };
    return m[s] ?? s;
  }
  statutBadge(s: string): string {
    const m: Record<string,string> = {
      en_attente:'badge-warning', confirmee:'badge-success',
      annulee:'badge-error', expiree:'badge-neutral', remboursee:'badge-info'
    };
    return m[s] ?? 'badge-neutral';
  }
}
