import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { PaginationComponent } from '../../shared/components/pagination/pagination.component';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { Trajet } from '../../core/models/transport.model';
import { User } from '../../core/models/user.model';

type Periode = 'a_venir' | 'aujourdhui' | 'demain' | 'tous';

@Component({
  selector: 'app-trajets',
  standalone: true,
  imports: [CommonModule, FormsModule, PaginationComponent, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Trajets</h1><p class="page-subtitle">{{ total() | nb }} départs correspondant aux filtres</p></div>
        <div class="segmented">
          @for (p of periodes; track p.code) {
            <button [class.active]="periode === p.code" (click)="choisirPeriode(p.code)">{{ p.label }}</button>
          }
        </div>
      </div>

      <div class="table-card">
        <div class="toolbar">
          <div class="search-box">
            <span class="search-icon"><tb-icon name="search" [size]="16" /></span>
            <input type="text" class="form-control" placeholder="Ville ou compagnie…" [(ngModel)]="search" (ngModelChange)="search$.next($event)">
          </div>
          <select class="form-control" [(ngModel)]="filtreStatut" (change)="recharger()">
            <option value="">Tous les statuts</option>
            <option value="planifie">Planifié</option><option value="en_cours">En cours</option>
            <option value="retarde">Retardé</option><option value="termine">Terminé</option><option value="annule">Annulé</option>
          </select>
          <select class="form-control" [(ngModel)]="filtreClasse" (change)="recharger()">
            <option value="">Toutes les classes</option>
            <option value="standard">Standard</option><option value="confort">Confort</option><option value="vip">VIP</option>
          </select>
          <label class="case"><input type="checkbox" [(ngModel)]="sansChauffeur" (change)="recharger()"> Sans chauffeur</label>
          <span class="spacer"></span>
          @if (periode === 'tous') {
            <input type="date" class="form-control" [(ngModel)]="filtreDate" (change)="recharger()">
          }
        </div>

        <div class="table-container">
          <table>
            <thead><tr>
              <th>Départ</th><th>Trajet</th><th>Compagnie & car</th><th>Chauffeur</th>
              <th>Remplissage</th><th class="right">Prix</th><th>Statut</th>
              @if (peutGerer()) { <th class="right">Actions</th> }
            </tr></thead>
            <tbody>
              @if (chargement()) {
                <tr><td colspan="8"><div class="loading-row"><span class="spinner"></span></div></td></tr>
              } @else {
                @for (t of trajets(); track t.id) {
                  <tr>
                    <td><div class="heure">{{ t.heure_depart | date:'HH:mm' }}</div><div class="cell-sub">{{ t.heure_depart | date:'EEE d MMM' }}</div></td>
                    <td>
                      <div class="route">{{ t.depart_nom }} <span class="arrow"><tb-icon name="arrow-right" [size]="14" /></span> {{ t.arrivee_nom }}</div>
                      <div class="cell-sub">{{ t.duree_label }}@if (+t.note_moyenne > 0) { · <span class="text-gold">★ {{ t.note_moyenne }}</span> }</div>
                    </td>
                    <td>
                      <div class="cell-main">{{ t.compagnie }}</div>
                      <div class="cell-sub"><span class="mono">{{ t.bus_immatriculation }}</span> · <span [class]="'classe ' + t.bus_classe">{{ classeLabel(t.bus_classe) }}</span></div>
                    </td>
                    <td>
                      @if (t.chauffeur_nom) {
                        <button class="chauffeur" (click)="ouvrirAffectation(t)" [disabled]="!peutAffecter(t)">
                          <span class="avatar mini">{{ initiales(t.chauffeur_nom) }}</span>{{ t.chauffeur_nom }}
                        </button>
                      } @else if (peutAffecter(t)) {
                        <button class="btn btn-outline btn-sm" (click)="ouvrirAffectation(t)"><tb-icon name="plus" [size]="14" /> Affecter</button>
                      } @else { <span class="text-hint">—</span> }
                    </td>
                    <td style="min-width:130px">
                      <div class="progress" [class.warn]="remplissage(t) >= 85"><span [style.width.%]="remplissage(t)"></span></div>
                      <div class="cell-sub">{{ t.places_total - t.places_disponibles }} / {{ t.places_total }} places</div>
                    </td>
                    <td class="right">
                      <div class="amount">{{ t.prix_actuel | nb:'F' }}</div>
                      @if (t.est_en_promo) { <div class="cell-sub"><s>{{ t.prix_fcfa | nb }}</s> <span class="text-gold">promo</span></div> }
                    </td>
                    <td>
                      <span class="badge" [ngClass]="statutBadge(t.statut)">{{ statutLabel(t.statut) }}</span>
                      @if (t.retard_minutes > 0 && t.statut === 'retarde') { <div class="cell-sub">+{{ t.retard_minutes }} min</div> }
                    </td>
                    @if (peutGerer()) {
                      <td class="right">
                        <div class="row-actions">
                          @if (t.statut === 'planifie' || t.statut === 'retarde' || t.statut === 'en_cours') {
                            <button class="icon-btn" data-tip="Signaler un retard" (click)="ouvrirRetard(t)"><tb-icon name="clock" /></button>
                            <button class="icon-btn danger" data-tip="Annuler le trajet" (click)="ouvrirAnnulation(t)"><tb-icon name="x-circle" /></button>
                          }
                        </div>
                      </td>
                    }
                  </tr>
                } @empty {
                  <tr><td colspan="8"><div class="empty-state"><div class="empty-icon"><tb-icon name="route" [size]="26" /></div>
                    <h3>Aucun trajet</h3><p>Modifiez la période ou les filtres.</p></div></td></tr>
                }
              }
            </tbody>
          </table>
        </div>
        <app-pagination [page]="page()" [total]="total()" [pageSize]="pageSize" (pageChange)="allerPage($event)" />
      </div>
    </div>

    <!-- Affecter un chauffeur -->
    @if (trajetAffectation(); as t) {
      <div class="modal-backdrop" (click)="trajetAffectation.set(null)">
        <div class="modal" style="max-width:460px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div><div class="modal-title">Affecter un chauffeur</div>
              <div class="cell-sub">{{ t.depart_nom }} → {{ t.arrivee_nom }} · {{ t.heure_depart | date:'EEE d MMM, HH:mm' }}</div></div>
            <button class="modal-close" (click)="trajetAffectation.set(null)"><tb-icon name="x" /></button>
          </div>
          <div class="modal-body">
            @if (chauffeurs().length === 0) {
              <div class="info-box">Aucun compte chauffeur. Créez-en un depuis la page <b>Chauffeurs</b>.</div>
            }
            <div class="liste-choix">
              @for (c of chauffeurs(); track c.id) {
                <label class="choix" [class.actif]="chauffeurChoisi === c.id">
                  <input type="radio" name="chauffeur" [value]="c.id" [(ngModel)]="chauffeurChoisi">
                  <span class="avatar mini">{{ c.initiales }}</span>
                  <span><b>{{ c.nom_complet }}</b><small>{{ c.telephone || c.email }}</small></span>
                </label>
              }
            </div>
          </div>
          <div class="modal-footer">
            @if (t.chauffeur) { <button class="btn btn-danger" (click)="affecter(null)">Retirer</button> }
            <span style="flex:1"></span>
            <button class="btn btn-ghost" (click)="trajetAffectation.set(null)">Annuler</button>
            <button class="btn btn-primary" [disabled]="!chauffeurChoisi" (click)="affecter(chauffeurChoisi)">Affecter</button>
          </div>
        </div>
      </div>
    }

    <!-- Retard -->
    @if (trajetRetard(); as t) {
      <div class="modal-backdrop" (click)="trajetRetard.set(null)">
        <div class="modal" style="max-width:440px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div><div class="modal-title">Signaler un retard</div>
            <div class="cell-sub">{{ t.depart_nom }} → {{ t.arrivee_nom }} · départ {{ t.heure_depart | date:'HH:mm' }}</div></div>
            <button class="modal-close" (click)="trajetRetard.set(null)"><tb-icon name="x" /></button></div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Retard estimé</label>
              <div class="segmented">
                @for (m of [15, 30, 45, 60, 90]; track m) { <button [class.active]="retardMin === m" (click)="retardMin = m">{{ m }} min</button> }
              </div>
            </div>
            <p class="form-hint">Les voyageurs sont prévenus par SMS et notification.</p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="trajetRetard.set(null)">Annuler</button>
            <button class="btn btn-primary" (click)="confirmerRetard()">Signaler le retard</button>
          </div>
        </div>
      </div>
    }

    <!-- Annulation -->
    @if (trajetAnnulation(); as t) {
      <div class="modal-backdrop" (click)="trajetAnnulation.set(null)">
        <div class="modal" style="max-width:460px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div><div class="modal-title">Annuler ce trajet ?</div>
            <div class="cell-sub">{{ t.depart_nom }} → {{ t.arrivee_nom }} · {{ t.heure_depart | date:'EEE d MMM, HH:mm' }}</div></div>
            <button class="modal-close" (click)="trajetAnnulation.set(null)"><tb-icon name="x" /></button></div>
          <div class="modal-body">
            <div class="danger-box"><tb-icon name="alert" [size]="18" /> Action irréversible : les voyageurs sont prévenus et remboursés.</div>
            <div class="form-group">
              <label class="form-label">Motif (communiqué aux voyageurs)</label>
              <textarea class="form-control" [(ngModel)]="motifAnnulation" rows="3" placeholder="Ex. : panne mécanique"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="trajetAnnulation.set(null)">Retour</button>
            <button class="btn btn-danger-solid btn" (click)="confirmerAnnulation()" [disabled]="!motifAnnulation.trim()">Annuler le trajet</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .heure{font-size:16px;font-weight:800;font-variant-numeric:tabular-nums;}
    .case{display:inline-flex;align-items:center;gap:8px;font-size:14px;color:var(--text-2);cursor:pointer;}
    .case input{accent-color:var(--primary);width:16px;height:16px;}
    .classe{font-weight:600;}
    .classe.vip{color:var(--gold-dark);} .classe.confort{color:var(--primary);}
    .chauffeur{display:inline-flex;align-items:center;gap:8px;border:none;background:none;font-size:14px;font-weight:600;color:var(--text-1);cursor:pointer;padding:4px 8px 4px 4px;border-radius:999px;}
    .chauffeur:hover:not(:disabled){background:var(--surface-2);}
    .chauffeur:disabled{cursor:default;}
    .avatar.mini{width:28px;height:28px;font-size:11px;}
    .liste-choix{display:flex;flex-direction:column;gap:8px;max-height:340px;overflow-y:auto;}
    .choix{display:flex;align-items:center;gap:12px;padding:10px 12px;border:1px solid var(--border);border-radius:12px;cursor:pointer;}
    .choix:hover{background:var(--surface-2);}
    .choix.actif{border-color:var(--primary);background:var(--primary-light);}
    .choix input{display:none;}
    .choix span:last-child{display:flex;flex-direction:column;}
    .choix small{font-size:12px;color:var(--text-2);}
    .danger-box{display:flex;gap:10px;align-items:center;background:var(--error-bg);color:var(--error);padding:12px 14px;border-radius:12px;font-size:13px;font-weight:500;}
  `]
})
export class TrajetsComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private toast = inject(ToastService);

  readonly periodes: { code: Periode; label: string }[] = [
    { code: 'a_venir', label: 'À venir' }, { code: 'aujourdhui', label: "Aujourd'hui" },
    { code: 'demain', label: 'Demain' }, { code: 'tous', label: 'Tous' },
  ];
  trajets = signal<Trajet[]>([]);
  chauffeurs = signal<User[]>([]);
  total = signal(0); page = signal(1); chargement = signal(false);
  trajetRetard = signal<Trajet | null>(null);
  trajetAnnulation = signal<Trajet | null>(null);
  trajetAffectation = signal<Trajet | null>(null);
  periode: Periode = 'a_venir';
  search = ''; filtreStatut = ''; filtreDate = ''; filtreClasse = ''; sansChauffeur = false;
  retardMin = 30; motifAnnulation = ''; chauffeurChoisi: string | null = null;
  readonly pageSize = 20;
  search$ = new Subject<string>();

  ngOnInit(): void {
    this.search$.pipe(debounceTime(350), distinctUntilChanged()).subscribe(() => this.recharger());
    this.charger();
    if (this.auth.hasRole('admin', 'support')) {
      this.api.getUtilisateurs({ role: 'chauffeur', is_active: 'true', page_size: 100 }).subscribe({
        next: r => this.chauffeurs.set(r.data.results), error: () => {},
      });
    }
  }

  peutGerer(): boolean { return this.auth.hasRole('admin', 'support', 'transporteur'); }
  peutAffecter(t: Trajet): boolean {
    return this.auth.hasRole('admin', 'support') && ['planifie', 'retarde'].includes(t.statut);
  }
  choisirPeriode(p: Periode): void { this.periode = p; this.recharger(); }
  recharger(): void { this.page.set(1); this.charger(); }
  allerPage(p: number): void { this.page.set(p); this.charger(); }

  charger(): void {
    this.chargement.set(true);
    const p: Record<string, string> = { page: String(this.page()), ordering: 'heure_depart' };
    const jour = (decalage: number) => { const d = new Date(); d.setDate(d.getDate() + decalage); return d.toISOString().slice(0, 10); };
    if (this.periode === 'a_venir') p['a_venir'] = 'true';
    if (this.periode === 'aujourdhui') p['date'] = jour(0);
    if (this.periode === 'demain') p['date'] = jour(1);
    if (this.periode === 'tous') { p['ordering'] = '-heure_depart'; if (this.filtreDate) p['date'] = this.filtreDate; }
    if (this.search) p['search'] = this.search;
    if (this.filtreStatut) p['statut'] = this.filtreStatut;
    if (this.filtreClasse) p['classe'] = this.filtreClasse;
    if (this.sansChauffeur) p['sans_chauffeur'] = 'true';
    this.api.getTrajets(p).subscribe({
      next: r => { this.trajets.set(r.data.results); this.total.set(r.data.count); this.chargement.set(false); },
      error: () => { this.chargement.set(false); this.toast.error('Impossible de charger les trajets.'); },
    });
  }

  ouvrirAffectation(t: Trajet): void { this.chauffeurChoisi = t.chauffeur ?? null; this.trajetAffectation.set(t); }
  affecter(id: string | null): void {
    const t = this.trajetAffectation();
    if (!t) return;
    this.api.affecterChauffeur(t.id, id).subscribe({
      next: () => { this.toast.success(id ? 'Chauffeur affecté.' : 'Chauffeur retiré.'); this.trajetAffectation.set(null); this.charger(); },
      error: e => this.toast.error(e?.error?.message ?? 'Affectation impossible.'),
    });
  }
  ouvrirRetard(t: Trajet): void { this.retardMin = 30; this.trajetRetard.set(t); }
  ouvrirAnnulation(t: Trajet): void { this.motifAnnulation = ''; this.trajetAnnulation.set(t); }
  confirmerRetard(): void {
    const t = this.trajetRetard();
    if (!t) return;
    this.api.signalerRetard(t.id, this.retardMin).subscribe({
      next: () => { this.toast.success('Retard signalé aux voyageurs.'); this.trajetRetard.set(null); this.charger(); },
      error: () => this.toast.error('Erreur lors du signalement.'),
    });
  }
  confirmerAnnulation(): void {
    const t = this.trajetAnnulation();
    if (!t) return;
    this.api.annulerTrajet(t.id, this.motifAnnulation).subscribe({
      next: () => { this.toast.success('Trajet annulé.'); this.trajetAnnulation.set(null); this.charger(); },
      error: () => this.toast.error("Erreur lors de l'annulation."),
    });
  }

  remplissage(t: Trajet): number { return t.places_total ? Math.round((t.places_total - t.places_disponibles) / t.places_total * 100) : 0; }
  initiales(nom: string): string { return nom.split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase(); }
  classeLabel(c: string): string { return ({ vip: 'VIP', confort: 'Confort', standard: 'Standard' } as Record<string, string>)[c] ?? c; }
  statutLabel(s: string): string { return ({ planifie: 'Planifié', en_cours: 'En cours', termine: 'Terminé', annule: 'Annulé', retarde: 'Retardé' } as Record<string, string>)[s] ?? s; }
  statutBadge(s: string): string { return ({ planifie: 'badge-info', en_cours: 'badge-success', termine: 'badge-neutral', annule: 'badge-error', retarde: 'badge-warning' } as Record<string, string>)[s] ?? 'badge-neutral'; }
}
