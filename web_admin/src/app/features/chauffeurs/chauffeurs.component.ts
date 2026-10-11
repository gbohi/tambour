import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { User } from '../../core/models/user.model';
import { Trajet } from '../../core/models/transport.model';

@Component({
  selector: 'app-chauffeurs',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Chauffeurs</h1>
          <p class="page-subtitle">Comptes de l'application chauffeur : scan des billets et clôture des trajets.</p></div>
        @if (auth.isAdmin()) {
          <button class="btn btn-primary" (click)="ouvrirCreation()"><tb-icon name="user-plus" [size]="18" /> Nouveau chauffeur</button>
        }
      </div>

      <div class="grille">
        <div class="table-card">
          <div class="toolbar">
            <div class="search-box">
              <span class="search-icon"><tb-icon name="search" [size]="16" /></span>
              <input class="form-control" placeholder="Nom, téléphone…" [(ngModel)]="recherche">
            </div>
            <span class="spacer"></span>
            <span class="text-muted">{{ filtres().length | nb }} chauffeur{{ filtres().length > 1 ? 's' : '' }}</span>
          </div>
          <div class="table-container">
            <table>
              <thead><tr><th>Chauffeur</th><th>Contact</th><th>Statut</th><th>Depuis</th></tr></thead>
              <tbody>
                @for (c of filtres(); track c.id) {
                  <tr class="clickable" [class.selection]="choisi()?.id === c.id" (click)="choisir(c)">
                    <td><div class="cell-flex"><div class="avatar">{{ c.initiales }}</div>
                      <div><div class="cell-main">{{ c.nom_complet }}</div><div class="cell-sub">{{ c.email }}</div></div></div></td>
                    <td>{{ c.telephone || '—' }}</td>
                    <td><span class="badge" [ngClass]="c.is_active === false ? 'badge-error' : 'badge-success'">{{ c.is_active === false ? 'Désactivé' : 'Actif' }}</span></td>
                    <td class="text-muted">{{ c.date_inscription | date:'d MMM yyyy' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="4"><div class="empty-state"><div class="empty-icon"><tb-icon name="steering" [size]="26" /></div>
                    <h3>Aucun chauffeur</h3><p>Créez un compte pour chaque chauffeur : il se connecte avec l'application TamBour.</p></div></td></tr>
                }
              </tbody>
            </table>
          </div>
        </div>

        <div class="card fiche">
          @if (choisi(); as c) {
            <div class="tete">
              <div class="avatar avatar-lg">{{ c.initiales }}</div>
              <div><div class="card-title">{{ c.nom_complet }}</div><div class="cell-sub">{{ c.telephone || c.email }}</div></div>
            </div>
            <div class="sous-titre">Prochains trajets</div>
            @for (t of trajets(); track t.id) {
              <div class="trajet">
                <div class="date"><b>{{ t.heure_depart | date:'HH:mm' }}</b><span>{{ t.heure_depart | date:'EEE d' }}</span></div>
                <div><div class="route">{{ t.depart_nom }} → {{ t.arrivee_nom }}</div>
                  <div class="cell-sub">{{ t.bus_immatriculation }} · {{ t.places_total - t.places_disponibles }} passagers</div></div>
              </div>
            } @empty {
              <p class="text-muted">Aucun trajet à venir. Affectez-en depuis la page <a routerLink="/trajets">Trajets</a>.</p>
            }
            @if (auth.isAdmin()) {
              <button class="btn btn-ghost btn-sm" style="margin-top:12px" (click)="basculerActif(c)">
                {{ c.is_active === false ? 'Réactiver le compte' : 'Désactiver le compte' }}
              </button>
            }
          } @else {
            <div class="empty-state"><div class="empty-icon"><tb-icon name="user" [size]="26" /></div>
              <p>Sélectionnez un chauffeur pour voir ses prochains trajets.</p></div>
          }
        </div>
      </div>
    </div>

    @if (creation()) {
      <div class="modal-backdrop" (click)="creation.set(false)">
        <div class="modal" style="max-width:520px" (click)="$event.stopPropagation()">
          <div class="modal-header"><div><div class="modal-title">Nouveau chauffeur</div>
            <div class="cell-sub">Il pourra se connecter à l'application avec cet email et ce mot de passe.</div></div>
            <button class="modal-close" (click)="creation.set(false)"><tb-icon name="x" /></button></div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group"><label class="form-label">Prénom</label><input class="form-control" [(ngModel)]="form.prenom"></div>
              <div class="form-group"><label class="form-label">Nom</label><input class="form-control" [(ngModel)]="form.nom"></div>
            </div>
            <div class="form-group"><label class="form-label">Téléphone</label><input class="form-control" [(ngModel)]="form.telephone" placeholder="07 00 00 00 00"></div>
            <div class="form-group"><label class="form-label">Email (identifiant)</label><input class="form-control" type="email" [(ngModel)]="form.email"></div>
            <div class="form-group"><label class="form-label">Mot de passe provisoire</label>
              <div class="mdp"><input class="form-control mono" [(ngModel)]="form.password">
                <button class="btn btn-ghost" (click)="genererMdp()"><tb-icon name="refresh" [size]="16" /> Générer</button></div>
              <span class="form-hint">8 caractères minimum. Communiquez-le au chauffeur.</span></div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="creation.set(false)">Annuler</button>
            <button class="btn btn-primary" [disabled]="envoi()" (click)="creer()">Créer le compte</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .grille{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(300px,1fr);gap:20px;align-items:start;}
    @media (max-width:1100px){.grille{grid-template-columns:1fr;}}
    tr.selection td{background:var(--primary-light) !important;}
    .fiche{position:sticky;top:0;}
    .tete{display:flex;align-items:center;gap:14px;margin-bottom:20px;}
    .sous-titre{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--text-3);margin-bottom:10px;}
    .trajet{display:flex;gap:14px;align-items:center;padding:10px 0;border-bottom:1px solid var(--divider);}
    .date{display:flex;flex-direction:column;align-items:center;min-width:56px;padding:6px;border-radius:10px;background:var(--surface-2);}
    .date b{font-size:15px;} .date span{font-size:11px;color:var(--text-2);}
    .mdp{display:flex;gap:8px;}
  `]
})
export class ChauffeursComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private toast = inject(ToastService);

  chauffeurs = signal<User[]>([]);
  choisi = signal<User | null>(null);
  trajets = signal<Trajet[]>([]);
  creation = signal(false);
  envoi = signal(false);
  recherche = '';
  form = { prenom: '', nom: '', telephone: '', email: '', password: '' };

  filtres(): User[] {
    const q = this.recherche.toLowerCase().trim();
    return q ? this.chauffeurs().filter(c => `${c.nom_complet} ${c.telephone} ${c.email}`.toLowerCase().includes(q)) : this.chauffeurs();
  }

  ngOnInit(): void { this.charger(); }

  charger(): void {
    this.api.getUtilisateurs({ role: 'chauffeur', page_size: 100 }).subscribe({
      next: r => this.chauffeurs.set(r.data.results),
      error: () => this.toast.error('Impossible de charger les chauffeurs.'),
    });
  }

  choisir(c: User): void {
    this.choisi.set(c);
    this.trajets.set([]);
    this.api.getTrajets({ chauffeur: c.id, a_venir: 'true', ordering: 'heure_depart', page_size: 8 }).subscribe({
      next: r => this.trajets.set(r.data.results), error: () => {},
    });
  }

  ouvrirCreation(): void {
    this.form = { prenom: '', nom: '', telephone: '', email: '', password: '' };
    this.genererMdp();
    this.creation.set(true);
  }

  genererMdp(): void {
    const a = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    this.form.password = Array.from(crypto.getRandomValues(new Uint32Array(10)), n => a[n % a.length]).join('');
  }

  creer(): void {
    this.envoi.set(true);
    this.api.creerUtilisateur({ ...this.form, role: 'chauffeur' }).subscribe({
      next: r => {
        this.envoi.set(false); this.creation.set(false);
        this.toast.success(`Compte créé pour ${r.data.nom_complet}.`);
        this.charger(); this.choisir(r.data);
      },
      error: e => { this.envoi.set(false); this.toast.error(e?.error?.message ?? 'Création impossible.'); },
    });
  }

  basculerActif(c: User): void {
    const actif = c.is_active === false;
    this.api.toggleUserActif(c.id, actif).subscribe({
      next: () => { this.toast.success(actif ? 'Compte réactivé.' : 'Compte désactivé.'); this.charger(); this.choisi.set({ ...c, is_active: actif }); },
      error: () => this.toast.error('Action impossible.'),
    });
  }
}
