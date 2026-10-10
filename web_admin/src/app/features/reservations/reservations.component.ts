import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { Reservation, Passager, Billet } from '../../core/models/reservation.model';

@Component({
  selector: 'app-reservations',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Réservations</h1><p class="page-subtitle">{{ total() }} réservations</p></div>
        <button class="btn btn-ghost btn-sm" (click)="exportCsv()">&#128229; CSV</button>
      </div>
      <div class="filters">
        <div class="search-box">
          <span class="search-icon">&#128269;</span>
          <input type="text" class="form-control" placeholder="Référence, email..."
            [(ngModel)]="search" (ngModelChange)="search$.next($event)">
        </div>
        <select class="form-control" style="width:auto" [(ngModel)]="filtreStatut" (change)="onFiltreChange()">
          <option value="">Tous statuts</option>
          <option value="en_attente">En attente</option>
          <option value="confirmee">Confirmée</option>
          <option value="annulee">Annulée</option>
          <option value="expiree">Expirée</option>
          <option value="remboursee">Remboursée</option>
        </select>
        <input type="date" class="form-control" style="width:auto" [(ngModel)]="filtreDate" (change)="onFiltreChange()">
      </div>
      <div class="table-card">
        @if (loading()) {
          <div style="padding:48px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
        } @else {
          <div class="table-container">
            <table>
              <thead><tr>
                <th>Référence</th><th>Trajet</th><th>Passagers</th>
                <th>Montant</th><th>Statut</th><th>Date</th><th>Actions</th>
              </tr></thead>
              <tbody>
                @for (r of reservations(); track r.id) {
                  <tr class="clickable" (click)="ouvrirDetail(r)">
                    <td><code style="font-size:12px;background:var(--surface-2);padding:3px 7px;border-radius:5px;font-weight:700">{{ r.reference }}</code></td>
                    <td>
                      <div style="font-weight:600">{{ r.trajet_info.depart }} &#8594; {{ r.trajet_info.arrivee }}</div>
                      <div style="font-size:11px;color:var(--text-2)">{{ r.trajet_info.heure_depart | date:'dd/MM HH:mm' }}</div>
                    </td>
                    <td>
                      <span class="badge badge-neutral">{{ r.nb_passagers }} passager{{ r.nb_passagers > 1 ? 's' : '' }}</span>
                      <div style="font-size:10px;color:var(--text-3);margin-top:3px">{{ r.nb_passagers }} billet{{ r.nb_passagers > 1 ? 's' : '' }}</div>
                    </td>
                    <td><strong style="color:var(--primary)">{{ r.montant_total | number:'1.0-0' }} FCFA</strong></td>
                    <td><span class="badge" [ngClass]="statutBadge(r.statut)">{{ statutLabel(r.statut) }}</span></td>
                    <td style="color:var(--text-2)">{{ r.created_at | date:'dd/MM/yy HH:mm' }}</td>
                    <td (click)="$event.stopPropagation()">
                      <div style="display:flex;gap:4px">
                        <button class="btn btn-ghost btn-sm" (click)="ouvrirDetail(r)">&#128269; Détail</button>
                        @if (r.statut === 'confirmee') {
                          <button class="btn btn-outline btn-sm" (click)="ouvrirBillets(r)">&#127915; Billets</button>
                        }
                        @if (r.peut_etre_annulee && auth.isAdminOrSupport()) {
                          <button class="btn btn-danger btn-sm" (click)="ouvrirAnnuler(r)">&#10005;</button>
                        }
                      </div>
                    </td>
                  </tr>
                } @empty {
                  <tr><td colspan="7">
                    <div class="empty-state"><div class="empty-icon">&#127915;</div><h3>Aucune réservation</h3><p>Modifiez les filtres.</p></div>
                  </td></tr>
                }
              </tbody>
            </table>
          </div>
          <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="onPage($event)" />
        }
      </div>
    </div>

    <!-- Modal détail réservation -->
    @if (selected()) {
      <div class="modal-backdrop" (click)="closeDetail()">
        <div class="modal" style="max-width:600px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div>
              <div class="modal-title">{{ selected()!.reference }}</div>
              <span class="badge" [ngClass]="statutBadge(selected()!.statut)">{{ statutLabel(selected()!.statut) }}</span>
            </div>
            <button class="modal-close" (click)="closeDetail()">&#215;</button>
          </div>
          <div class="modal-body">
            <div class="info-box" style="margin-bottom:16px">
              <div style="font-weight:700;font-size:15px">{{ selected()!.trajet_info.depart }} &#8594; {{ selected()!.trajet_info.arrivee }}</div>
              <div style="font-size:12px;color:var(--primary);margin-top:4px">{{ selected()!.trajet_info.heure_depart | date:'dd MMMM yyyy HH:mm' }}</div>
            </div>

            <!-- Email payeur -->
            @if (selected()!.email_payeur) {
              <div style="background:var(--primary-light);border:1px solid rgba(10,124,78,0.15);border-radius:10px;padding:10px 14px;margin-bottom:14px;display:flex;align-items:center;gap:8px">
                <span>&#128231;</span>
                <span style="font-size:12px;color:var(--primary)">Billets envoyés à : <strong>{{ selected()!.email_payeur }}</strong></span>
              </div>
            }

            <!-- Liste passagers avec leurs billets -->
            @if (detailLoading()) {
              <div style="text-align:center;padding:16px;color:var(--text-2)">&#9203; Chargement des passagers…</div>
            } @else if (detail()?.passagers?.length) {
              <h4 style="font-size:11px;color:var(--text-2);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:10px">
                {{ detail()!.passagers!.length }} Passager{{ detail()!.passagers!.length > 1 ? 's' : '' }} — {{ detail()!.passagers!.length }} Billet{{ detail()!.passagers!.length > 1 ? 's' : '' }}
              </h4>
              @for (p of detail()!.passagers!; track p.id) {
                <div style="border:0.5px solid var(--border);border-radius:12px;padding:12px;margin-bottom:10px">
                  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
                    <div style="display:flex;align-items:center;gap:10px">
                      <div class="avatar" style="background:var(--primary)">{{ p.prenom[0] }}{{ p.nom[0] }}</div>
                      <div>
                        <div style="font-weight:700;font-size:14px">{{ p.prenom }} {{ p.nom }}</div>
                        <div style="font-size:11px;color:var(--text-2)">{{ p.telephone }}</div>
                        @if (p.email) {
                          <div style="font-size:11px;color:var(--text-3)">&#128231; {{ p.email }}</div>
                        }
                      </div>
                    </div>
                    <span class="badge badge-primary">Siège {{ p.siege_numero }}</span>
                  </div>
                  <!-- Billet individuel -->
                  @if (p.billet) {
                    <div style="background:var(--surface-2);border-radius:8px;padding:8px 12px;display:flex;align-items:center;justify-content:space-between">
                      <div>
                        <code style="font-size:11px;font-weight:700;color:var(--primary)">{{ p.billet.reference_billet }}</code>
                        @if (!p.billet.est_valide) {
                          <span class="badge badge-success" style="margin-left:6px;font-size:10px">&#10003; Utilisé</span>
                        } @else {
                          <span class="badge badge-warning" style="margin-left:6px;font-size:10px">En attente</span>
                        }
                      </div>
                      @if (auth.isAdminOrSupport() || auth.isTransporteur()) {
                        <button class="btn btn-ghost btn-sm"
                          [disabled]="!p.billet.est_valide"
                          (click)="validerBillet(selected()!.id, p.id)">
                          &#128241; Valider QR
                        </button>
                      }
                    </div>
                  }
                </div>
              }
            }

            <div class="info-row"><span class="info-label">Montant total</span><span class="info-value" style="color:var(--primary);font-size:16px">{{ selected()!.montant_total | number:'1.0-0' }} FCFA</span></div>
            <div class="info-row"><span class="info-label">Créée le</span><span class="info-value">{{ selected()!.created_at | date:'dd/MM/yyyy HH:mm' }}</span></div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="closeDetail()">Fermer</button>
            @if (selected()!.peut_etre_annulee && auth.isAdminOrSupport()) {
              <button class="btn btn-danger" (click)="ouvrirAnnuler(selected()!); closeDetail()">&#10005; Annuler</button>
            }
          </div>
        </div>
      </div>
    }

    <!-- Modal annulation -->
    @if (resAnnuler()) {
      <div class="modal-backdrop" (click)="resAnnuler.set(null)">
        <div class="modal" style="max-width:420px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div class="modal-title">Annuler {{ resAnnuler()!.reference }}</div><button class="modal-close" (click)="resAnnuler.set(null)">&#215;</button></div>
          <div class="modal-body">
            <div style="background:var(--warning-bg);border:1px solid rgba(245,166,35,0.3);border-radius:10px;padding:12px;color:var(--warning);font-size:13px;margin-bottom:16px">
              &#9888; Remboursement éligible : <strong>{{ resAnnuler()!.montant_remboursable | number:'1.0-0' }} FCFA</strong><br>
              <span style="font-size:11px">{{ resAnnuler()!.nb_passagers }} billet{{ resAnnuler()!.nb_passagers > 1 ? 's' : '' }} seront invalidés.</span>
            </div>
            <div class="form-group"><label class="form-label">Motif</label>
              <textarea class="form-control" [(ngModel)]="motifAnnulation" rows="3" placeholder="Motif…"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="resAnnuler.set(null)">Fermer</button>
            <button class="btn btn-danger" (click)="confirmerAnnulation()" [disabled]="!motifAnnulation.trim()">Confirmer</button>
          </div>
        </div>
      </div>
    }
  `
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
