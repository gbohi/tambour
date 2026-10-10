import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import {
  Reclamation, StatutReclamation, MessageSupport, StatutMessage, AvisApplication,
} from '../../core/models/support.model';

type Onglet = 'reclamations' | 'messages' | 'avis';

const STATUTS_RECLAMATION: { code: StatutReclamation; label: string; badge: string }[] = [
  { code: 'ouverte',  label: 'Ouverte',  badge: 'badge-warning' },
  { code: 'en_cours', label: 'En cours', badge: 'badge-info' },
  { code: 'resolue',  label: 'Résolue',  badge: 'badge-success' },
  { code: 'rejetee',  label: 'Rejetée',  badge: 'badge-error' },
];
const STATUTS_MESSAGE: { code: StatutMessage; label: string; badge: string }[] = [
  { code: 'nouveau',  label: 'Nouveau',  badge: 'badge-warning' },
  { code: 'en_cours', label: 'En cours', badge: 'badge-info' },
  { code: 'traite',   label: 'Traité',   badge: 'badge-success' },
];

@Component({
  selector: 'app-support',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1 class="page-title">Support client</h1>
          <p class="page-subtitle">Réclamations, messages et avis des voyageurs</p>
        </div>
      </div>

      <div class="stats-grid">
        @for (s of statutsReclamation; track s.code) {
          <div class="stat-card clickable" (click)="onglet.set('reclamations'); filtreReclamation = s.code; chargerReclamations()">
            <div><div class="stat-value">{{ statsReclamations()[s.code] ?? 0 }}</div>
            <div class="stat-label">Réclamations {{ s.label.toLowerCase() }}s</div></div>
          </div>
        }
        <div class="stat-card clickable" (click)="onglet.set('avis')">
          <div><div class="stat-value">⭐ {{ moyenneAvis() | number:'1.1-1' }}</div>
          <div class="stat-label">{{ totalAvis() }} avis sur l'application</div></div>
        </div>
      </div>

      <div class="tabs">
        <button [class.active]="onglet() === 'reclamations'" (click)="onglet.set('reclamations')">Réclamations</button>
        <button [class.active]="onglet() === 'messages'" (click)="onglet.set('messages')">
          Messages @if (nbNouveaux() > 0) { <span class="badge badge-warning">{{ nbNouveaux() }}</span> }
        </button>
        <button [class.active]="onglet() === 'avis'" (click)="onglet.set('avis')">Avis sur l'app</button>
      </div>

      @switch (onglet()) {
        @case ('reclamations') {
          <div class="filters">
            <select class="form-control" style="width:auto" [(ngModel)]="filtreReclamation" (change)="chargerReclamations()">
              <option value="">Tous les statuts</option>
              @for (s of statutsReclamation; track s.code) { <option [value]="s.code">{{ s.label }}</option> }
            </select>
          </div>
          <div class="table-card"><div class="table-container">
            <table>
              <thead><tr><th>Référence</th><th>Voyageur</th><th>Motif</th><th>Objet</th><th>Réservation</th><th>Statut</th><th>Date</th></tr></thead>
              <tbody>
                @for (r of reclamations(); track r.id) {
                  <tr class="clickable" (click)="ouvrirReclamation(r)">
                    <td style="font-weight:600">{{ r.reference }}</td>
                    <td><div style="font-weight:600">{{ r.user_nom }}</div><div class="text-hint" style="font-size:11px">{{ r.user_email }}</div></td>
                    <td>{{ r.categorie_label }}</td>
                    <td>{{ r.sujet }}</td>
                    <td>{{ r.reference_reservation || '—' }}</td>
                    <td><span class="badge" [ngClass]="badgeReclamation(r.statut)">{{ r.statut_label }}</span></td>
                    <td>{{ r.created_at | date:'dd/MM/yyyy HH:mm' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="7"><div class="empty-state">{{ chargement() ? 'Chargement…' : 'Aucune réclamation' }}</div></td></tr>
                }
              </tbody>
            </table>
          </div></div>
        }
        @case ('messages') {
          <div class="filters">
            <select class="form-control" style="width:auto" [(ngModel)]="filtreMessage" (change)="chargerMessages()">
              <option value="">Tous les statuts</option>
              @for (s of statutsMessage; track s.code) { <option [value]="s.code">{{ s.label }}</option> }
            </select>
          </div>
          <div class="table-card"><div class="table-container">
            <table>
              <thead><tr><th>Expéditeur</th><th>Contact</th><th>Sujet</th><th>Statut</th><th>Date</th></tr></thead>
              <tbody>
                @for (m of messages(); track m.id) {
                  <tr class="clickable" (click)="ouvrirMessage(m)">
                    <td style="font-weight:600">{{ m.nom }}</td>
                    <td><div>{{ m.email }}</div><div class="text-hint" style="font-size:11px">{{ m.telephone }}</div></td>
                    <td>{{ m.sujet }}</td>
                    <td><span class="badge" [ngClass]="badgeMessage(m.statut)">{{ m.statut_label }}</span></td>
                    <td>{{ m.created_at | date:'dd/MM/yyyy HH:mm' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="5"><div class="empty-state">{{ chargement() ? 'Chargement…' : 'Aucun message' }}</div></td></tr>
                }
              </tbody>
            </table>
          </div></div>
        }
        @case ('avis') {
          <div class="card" style="margin-bottom:16px">
            <div class="repartition">
              @for (n of [5,4,3,2,1]; track n) {
                <div class="rep-ligne">
                  <span style="width:36px">{{ n }} ★</span>
                  <div class="rep-barre"><div class="rep-plein" [style.width.%]="pourcentage(n)"></div></div>
                  <span class="text-hint" style="width:40px;text-align:right">{{ repartition()[n] ?? 0 }}</span>
                </div>
              }
            </div>
          </div>
          <div class="table-card"><div class="table-container">
            <table>
              <thead><tr><th>Voyageur</th><th>Note</th><th>Commentaire</th><th>Plateforme</th><th>Date</th></tr></thead>
              <tbody>
                @for (a of avis(); track a.id) {
                  <tr>
                    <td style="font-weight:600">{{ a.user_nom }}</td>
                    <td style="color:#F5A623;white-space:nowrap">{{ etoiles(a.note) }}</td>
                    <td>{{ a.commentaire || '—' }}</td>
                    <td>{{ a.plateforme || '—' }} {{ a.version_app }}</td>
                    <td>{{ a.updated_at | date:'dd/MM/yyyy' }}</td>
                  </tr>
                } @empty {
                  <tr><td colspan="5"><div class="empty-state">Aucun avis pour le moment</div></td></tr>
                }
              </tbody>
            </table>
          </div></div>
        }
      }
    </div>

    @if (reclamation(); as r) {
      <div class="modal-backdrop" (click)="reclamation.set(null)">
        <div class="modal" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div><div class="modal-title">{{ r.reference }} — {{ r.sujet }}</div>
              <div style="font-size:13px;color:var(--text-2)">{{ r.categorie_label }} · {{ r.created_at | date:'dd/MM/yyyy HH:mm' }}</div></div>
            <button class="modal-close" (click)="reclamation.set(null)">&#215;</button>
          </div>
          <div class="modal-body">
            <div class="info-row"><span class="info-label">Voyageur</span><span class="info-value">{{ r.user_nom }} · {{ r.user_email }} · {{ r.user_telephone }}</span></div>
            <div class="info-row"><span class="info-label">Réservation</span><span class="info-value">{{ r.reference_reservation || '—' }}</span></div>
            <p style="white-space:pre-wrap;margin:16px 0">{{ r.description }}</p>
            <div class="form-group">
              <label class="form-label">Statut</label>
              <select class="form-control" [(ngModel)]="edition.statut">
                @for (s of statutsReclamation; track s.code) { <option [value]="s.code">{{ s.label }}</option> }
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Réponse au voyageur (visible dans l'application)</label>
              <textarea class="form-control" rows="4" [(ngModel)]="edition.reponse"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="reclamation.set(null)">Annuler</button>
            <button class="btn btn-primary" [disabled]="enregistrement()" (click)="enregistrerReclamation(r)">Enregistrer</button>
          </div>
        </div>
      </div>
    }

    @if (message(); as m) {
      <div class="modal-backdrop" (click)="message.set(null)">
        <div class="modal" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div><div class="modal-title">{{ m.sujet }}</div>
              <div style="font-size:13px;color:var(--text-2)">{{ m.nom }} · {{ m.created_at | date:'dd/MM/yyyy HH:mm' }}</div></div>
            <button class="modal-close" (click)="message.set(null)">&#215;</button>
          </div>
          <div class="modal-body">
            <div class="info-row"><span class="info-label">Contact</span><span class="info-value">{{ m.email || '—' }} · {{ m.telephone || '—' }}</span></div>
            <p style="white-space:pre-wrap;margin:16px 0">{{ m.message }}</p>
            <div class="form-group">
              <label class="form-label">Statut</label>
              <select class="form-control" [(ngModel)]="edition.statut">
                @for (s of statutsMessage; track s.code) { <option [value]="s.code">{{ s.label }}</option> }
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Notes / réponse envoyée</label>
              <textarea class="form-control" rows="3" [(ngModel)]="edition.reponse"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="message.set(null)">Annuler</button>
            <button class="btn btn-primary" [disabled]="enregistrement()" (click)="enregistrerMessage(m)">Enregistrer</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .stats-grid{margin-bottom:20px;}
    .clickable{cursor:pointer;}
    .tabs{display:flex;gap:4px;border-bottom:1px solid var(--border);margin-bottom:16px;}
    .tabs button{background:none;border:none;padding:10px 16px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;color:var(--text-2);cursor:pointer;border-bottom:2px solid transparent;display:flex;gap:6px;align-items:center;}
    .tabs button.active{color:var(--primary,#0A7C4E);border-bottom-color:var(--primary,#0A7C4E);}
    .repartition{display:flex;flex-direction:column;gap:8px;padding:4px;}
    .rep-ligne{display:flex;align-items:center;gap:10px;font-size:13px;}
    .rep-barre{flex:1;height:8px;background:var(--border);border-radius:4px;overflow:hidden;}
    .rep-plein{height:100%;background:#F5A623;border-radius:4px;}
    textarea.form-control{resize:vertical;font-family:'Outfit',sans-serif;}
  `]
})
export class SupportComponent implements OnInit {
  private api = inject(ApiService);
  private toast = inject(ToastService);

  readonly statutsReclamation = STATUTS_RECLAMATION;
  readonly statutsMessage = STATUTS_MESSAGE;

  onglet = signal<Onglet>('reclamations');
  chargement = signal(false);
  enregistrement = signal(false);

  reclamations = signal<Reclamation[]>([]);
  statsReclamations = signal<Partial<Record<StatutReclamation, number>>>({});
  messages = signal<MessageSupport[]>([]);
  nbNouveaux = signal(0);
  avis = signal<AvisApplication[]>([]);
  moyenneAvis = signal(0);
  totalAvis = signal(0);
  repartition = signal<Record<string, number>>({});

  reclamation = signal<Reclamation | null>(null);
  message = signal<MessageSupport | null>(null);
  edition: { statut: string; reponse: string } = { statut: '', reponse: '' };

  filtreReclamation = '';
  filtreMessage = '';

  private maxRepartition = computed(() => Math.max(1, ...Object.values(this.repartition())));

  ngOnInit(): void {
    this.chargerReclamations();
    this.chargerMessages();
    this.chargerAvis();
  }

  chargerReclamations(): void {
    this.chargement.set(true);
    this.api.getReclamations({ statut: this.filtreReclamation }).subscribe({
      next: r => { this.reclamations.set(r.data.results); this.statsReclamations.set(r.data.stats); this.chargement.set(false); },
      error: () => { this.chargement.set(false); this.toast.error('Impossible de charger les réclamations'); },
    });
  }

  chargerMessages(): void {
    this.api.getMessagesSupport({ statut: this.filtreMessage }).subscribe({
      next: r => { this.messages.set(r.data.results); this.nbNouveaux.set(r.data.nb_nouveaux); },
      error: () => this.toast.error('Impossible de charger les messages'),
    });
  }

  chargerAvis(): void {
    this.api.getAvisApplication().subscribe({
      next: r => {
        this.avis.set(r.data.results); this.moyenneAvis.set(r.data.moyenne);
        this.totalAvis.set(r.data.total); this.repartition.set(r.data.repartition);
      },
      error: () => this.toast.error('Impossible de charger les avis'),
    });
  }

  ouvrirReclamation(r: Reclamation): void {
    this.edition = { statut: r.statut, reponse: r.reponse };
    this.reclamation.set(r);
  }

  ouvrirMessage(m: MessageSupport): void {
    this.edition = { statut: m.statut, reponse: m.reponse };
    this.message.set(m);
  }

  enregistrerReclamation(r: Reclamation): void {
    this.enregistrement.set(true);
    this.api.updateReclamation(r.id, {
      statut: this.edition.statut as StatutReclamation, reponse: this.edition.reponse,
    }).subscribe({
      next: () => {
        this.enregistrement.set(false); this.reclamation.set(null);
        this.toast.success(`Réclamation ${r.reference} mise à jour`);
        this.chargerReclamations();
      },
      error: () => { this.enregistrement.set(false); this.toast.error('Échec de la mise à jour'); },
    });
  }

  enregistrerMessage(m: MessageSupport): void {
    this.enregistrement.set(true);
    this.api.updateMessageSupport(m.id, {
      statut: this.edition.statut as StatutMessage, reponse: this.edition.reponse,
    }).subscribe({
      next: () => {
        this.enregistrement.set(false); this.message.set(null);
        this.toast.success('Message mis à jour');
        this.chargerMessages();
      },
      error: () => { this.enregistrement.set(false); this.toast.error('Échec de la mise à jour'); },
    });
  }

  badgeReclamation(s: StatutReclamation): string {
    return STATUTS_RECLAMATION.find(x => x.code === s)?.badge ?? 'badge-neutral';
  }
  badgeMessage(s: StatutMessage): string {
    return STATUTS_MESSAGE.find(x => x.code === s)?.badge ?? 'badge-neutral';
  }
  etoiles(n: number): string { return '★'.repeat(n) + '☆'.repeat(5 - n); }
  pourcentage(n: number): number { return ((this.repartition()[n] ?? 0) / this.maxRepartition()) * 100; }
}
