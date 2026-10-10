import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { Notif } from '../../core/models/reservation.model';

interface Template { icon: string; label: string; titre: string; message: string; }

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Notifications</h1><p class="page-subtitle">{{ nbNonLues() }} non lue{{ nbNonLues() > 1 ? 's' : '' }}</p></div>
        <button class="btn btn-ghost btn-sm" (click)="marquerToutes()" [disabled]="nbNonLues() === 0">&#10003; Tout marquer lu</button>
      </div>
      <div class="nl">
        <!-- Liste -->
        <div>
          <div class="filters" style="margin-bottom:16px">
            <select class="form-control" style="width:auto" [(ngModel)]="filtreType" (change)="load()">
              <option value="">Tous les types</option>
              <option value="confirmation">Confirmation</option>
              <option value="rappel">Rappel</option>
              <option value="retard">Retard</option>
              <option value="promotion">Promotion</option>
              <option value="info">Info</option>
            </select>
            <label style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer">
              <input type="checkbox" [(ngModel)]="nonLues" (change)="load()"> Non lues uniquement
            </label>
          </div>
          @if (loading()) {
            <div style="padding:48px;text-align:center;color:var(--text-2)">&#9203; Chargement…</div>
          } @else {
            <div style="display:flex;flex-direction:column;gap:6px">
              @for (n of notifs(); track n.id) {
                <div class="ni" [class.unread]="!n.lue" (click)="marquerLue(n)">
                  <div class="ni-ico" [style.background]="typeBg(n.type_notif)">{{ typeIcon(n.type_notif) }}</div>
                  <div style="flex:1;min-width:0">
                    <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
                      <div style="font-size:13px" [style.fontWeight]="n.lue ? '500' : '700'">{{ n.titre }}</div>
                      @if (!n.lue) { <div style="width:8px;height:8px;border-radius:50%;background:var(--primary);flex-shrink:0;margin-top:4px"></div> }
                    </div>
                    <div style="font-size:12px;color:var(--text-2);margin-top:3px;line-height:1.5;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden">{{ n.message }}</div>
                    <div style="display:flex;gap:10px;margin-top:6px">
                      <span class="badge badge-neutral" style="font-size:10px">{{ n.type_label }}</span>
                      <span style="font-size:11px;color:var(--text-3)">{{ n.created_at | date:'dd/MM/yy HH:mm' }}</span>
                    </div>
                  </div>
                </div>
              } @empty {
                <div class="empty-state"><div class="empty-icon">🔔</div><h3>Aucune notification</h3></div>
              }
            </div>
          }
        </div>
        <!-- Panel envoi -->
        <div class="card" style="align-self:start">
          <div class="card-header"><h3 class="card-title">&#128226; Envoyer une notification</h3></div>
          <div style="display:flex;flex-direction:column;gap:14px">
            <div class="form-group"><label class="form-label">Titre</label>
              <input type="text" class="form-control" [(ngModel)]="envoi.titre" placeholder="Titre de la notification">
            </div>
            <div class="form-group"><label class="form-label">Message</label>
              <textarea class="form-control" [(ngModel)]="envoi.message" rows="4" placeholder="Contenu…"></textarea>
            </div>
            <div class="form-group"><label class="form-label">Type</label>
              <select class="form-control" [(ngModel)]="envoi.type_notif">
                <option value="info">&#8505; Information</option>
                <option value="promotion">&#127873; Promotion</option>
                <option value="retard">&#9888; Retard</option>
                <option value="rappel">&#128276; Rappel</option>
              </select>
            </div>
            <div class="form-group"><label class="form-label">Destinataires</label>
              <select class="form-control" [(ngModel)]="envoi.cibles">
                <option value="all">Tous les voyageurs</option>
                <option value="active">Voyageurs actifs</option>
                <option value="inactive">Voyageurs inactifs</option>
              </select>
            </div>
            <div>
              <div style="font-size:11px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:8px">Templates rapides</div>
              @for (t of templates; track t.label) {
                <button class="btn btn-ghost btn-sm" style="justify-content:flex-start;width:100%;margin-bottom:4px" (click)="applyTpl(t)">{{ t.icon }} {{ t.label }}</button>
              }
            </div>
            <button class="btn btn-primary" (click)="envoyer()" [disabled]="!envoi.titre || !envoi.message || envoiLoading()">
              @if (envoiLoading()) { &#9203; Envoi… } @else { &#128228; Envoyer }
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .nl{display:grid;grid-template-columns:1fr 380px;gap:20px;align-items:start;}
    @media(max-width:900px){.nl{grid-template-columns:1fr;}}
    .ni{display:flex;align-items:flex-start;gap:12px;padding:14px 16px;background:var(--surface);border:0.5px solid var(--border);border-radius:12px;cursor:pointer;transition:all 0.15s;}
    .ni:hover{border-color:var(--primary);}
    .ni.unread{background:var(--primary-light);border-color:rgba(10,124,78,0.2);}
    .ni-ico{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  `]
})
export class NotificationsComponent implements OnInit {
  private api   = inject(ApiService);
  private toast = inject(ToastService);

  notifs       = signal<Notif[]>([]);
  nbNonLues    = signal(0);
  loading      = signal(false);
  envoiLoading = signal(false);
  filtreType = ''; nonLues = false;

  envoi = { titre: '', message: '', type_notif: 'info', cibles: 'all' };

  readonly templates: Template[] = [
    { icon: '🎁', label: 'Offre spéciale', titre: 'Offre exclusive YoBus !', message: '-20% sur tous les trajets ce week-end. Reservez maintenant !' },
    { icon: '⚠️', label: 'Perturbations', titre: 'Perturbations sur le reseau', message: 'Des retards sont a prevoir. Merci de votre comprehension.' },
    { icon: '🔔', label: 'Rappel voyage', titre: 'Votre voyage approche', message: 'Rappel : trajet prevu demain. Soyez a la gare 30 min avant.' },
  ];

  ngOnInit() { this.load(); }
  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = { limit: '50' };
    if (this.filtreType) p['type']     = this.filtreType;
    if (this.nonLues)    p['non_lues'] = '1';
    this.api.getNotifications(p).subscribe({
      // res.data est typé NotifResponse — accès direct aux propriétés
      next: res => { this.notifs.set(res.data.results); this.nbNonLues.set(res.data.nb_non_lues); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  marquerLue(n: Notif): void {
    if (n.lue) return;
    this.api.marquerNotifLues([n.id]).subscribe({ next: () => { n.lue = true; this.nbNonLues.update(v => Math.max(0, v-1)); } });
  }
  marquerToutes(): void {
    this.api.marquerNotifLues().subscribe({
      next: () => { this.notifs.update(ns => ns.map(n => ({ ...n, lue: true }))); this.nbNonLues.set(0); this.toast.success('Toutes les notifications lues.'); }
    });
  }
  envoyer(): void {
    if (!this.envoi.titre.trim() || !this.envoi.message.trim()) return;
    this.envoiLoading.set(true);
    this.api.envoyerNotifBulk({ titre: this.envoi.titre, message: this.envoi.message, type_notif: this.envoi.type_notif, cibles: [this.envoi.cibles] }).subscribe({
      next: () => { this.toast.success('Notification envoyee.'); this.envoi = { titre:'', message:'', type_notif:'info', cibles:'all' }; this.envoiLoading.set(false); this.load(); },
      error: () => { this.toast.error("Erreur lors de l'envoi."); this.envoiLoading.set(false); }
    });
  }
  applyTpl(t: Template): void { this.envoi.titre = t.titre; this.envoi.message = t.message; }
  typeIcon(t: string): string { const m: Record<string,string> = { confirmation:'✓', rappel:'🔔', retard:'⚠️', promotion:'🎁', info:'ℹ️', paiement:'💳', annulation:'✕' }; return m[t] ?? '📢'; }
  typeBg(t: string): string { const m: Record<string,string> = { confirmation:'var(--success-bg)', rappel:'var(--info-bg)', retard:'var(--warning-bg)', promotion:'var(--gold-light)', info:'var(--surface-2)', paiement:'var(--primary-light)', annulation:'var(--error-bg)' }; return m[t] ?? 'var(--surface-2)'; }
}
