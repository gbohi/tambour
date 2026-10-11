import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { Notif } from '../../core/models/reservation.model';

interface Template { icon: string; label: string; titre: string; message: string; }

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Notifications</h1><p class="page-subtitle">{{ nbNonLues() | nb }} non lue{{ nbNonLues() > 1 ? 's' : '' }}</p></div>
        <button class="btn btn-secondary" (click)="marquerToutes()" [disabled]="nbNonLues() === 0"><tb-icon name="check" [size]="16" /> Tout marquer comme lu</button>
      </div>
      <div class="nl">
        <div class="table-card">
          <div class="toolbar">
            <select class="form-control" [(ngModel)]="filtreType" (change)="load()">
              <option value="">Tous les types</option><option value="confirmation">Confirmations</option><option value="rappel">Rappels</option>
              <option value="retard">Retards</option><option value="promotion">Promotions</option><option value="info">Informations</option>
            </select>
            <label class="case"><input type="checkbox" [(ngModel)]="nonLues" (change)="load()"> Non lues uniquement</label>
          </div>
          @if (loading()) {
            <div class="loading-row"><span class="spinner"></span></div>
          } @else {
            @for (n of notifs(); track n.id) {
              <div class="ni" [class.unread]="!n.lue" (click)="marquerLue(n)">
                <div class="ni-ico" [ngClass]="'t-' + n.type_notif"><tb-icon [name]="typeIcone(n.type_notif)" [size]="18" /></div>
                <div class="ni-corps">
                  <div class="ni-titre">{{ n.titre }} @if (!n.lue) { <i class="point"></i> }</div>
                  <div class="ni-msg">{{ n.message }}</div>
                  <div class="ni-meta"><span class="chip">{{ n.type_label }}</span><span>{{ n.created_at | date:'d MMM, HH:mm' }}</span></div>
                </div>
              </div>
            } @empty {
              <div class="empty-state"><div class="empty-icon"><tb-icon name="bell" [size]="26" /></div><h3>Aucune notification</h3></div>
            }
          }
        </div>

        <div class="card envoi">
          <div class="card-header"><div><div class="card-title">Envoyer une notification</div><div class="card-subtitle">Push et SMS aux voyageurs</div></div></div>
          <div class="modal-body" style="padding:0">
            <div class="modeles">
              @for (t of templates; track t.label) {
                <button class="chip-btn" (click)="applyTpl(t)"><tb-icon [name]="t.icon" [size]="15" /> {{ t.label }}</button>
              }
            </div>
            <div class="form-group"><label class="form-label">Titre</label><input type="text" class="form-control" [(ngModel)]="envoi.titre" placeholder="Titre de la notification"></div>
            <div class="form-group"><label class="form-label">Message</label><textarea class="form-control" [(ngModel)]="envoi.message" rows="4" placeholder="Contenu…"></textarea>
              <span class="form-hint">{{ envoi.message.length }} caractères{{ envoi.message.length > 160 ? ' (2 SMS)' : '' }}</span></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Type</label>
                <select class="form-control" [(ngModel)]="envoi.type_notif"><option value="info">Information</option><option value="promotion">Promotion</option>
                  <option value="retard">Retard</option><option value="rappel">Rappel</option></select></div>
              <div class="form-group"><label class="form-label">Destinataires</label>
                <select class="form-control" [(ngModel)]="envoi.cibles"><option value="all">Tous les voyageurs</option>
                  <option value="active">Voyageurs actifs</option><option value="inactive">Voyageurs inactifs</option></select></div>
            </div>
            <button class="btn btn-primary btn-block" (click)="envoyer()" [disabled]="!envoi.titre || !envoi.message || envoiLoading()">
              @if (envoiLoading()) { <span class="spinner" style="width:16px;height:16px;border-color:rgba(255,255,255,.4);border-top-color:#fff"></span> Envoi… }
              @else { <tb-icon name="send" [size]="16" /> Envoyer }
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .nl{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(320px,1fr);gap:20px;align-items:start;}
    @media (max-width:1100px){.nl{grid-template-columns:1fr;}}
    .case{display:inline-flex;align-items:center;gap:8px;font-size:14px;color:var(--text-2);cursor:pointer;}
    .case input{accent-color:var(--primary);width:16px;height:16px;}
    .ni{display:flex;gap:14px;padding:14px 16px;border-bottom:1px solid var(--divider);cursor:pointer;transition:background .12s;}
    .ni:hover{background:#FAFCFB;}
    .ni.unread{background:#F7FBF9;}
    .ni-ico{width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0;background:var(--surface-2);color:var(--text-2);}
    .t-confirmation,.t-paiement{background:var(--success-bg);color:var(--success);} .t-rappel{background:var(--info-bg);color:var(--info);}
    .t-retard{background:var(--warning-bg);color:var(--warning);} .t-promotion{background:var(--gold-light);color:var(--gold-dark);}
    .t-annulation{background:var(--error-bg);color:var(--error);}
    .ni-corps{flex:1;min-width:0;}
    .ni-titre{font-weight:700;display:flex;align-items:center;gap:8px;}
    .point{width:8px;height:8px;border-radius:50%;background:var(--primary);}
    .ni-msg{font-size:13px;color:var(--text-2);margin-top:3px;line-height:1.5;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;}
    .ni-meta{display:flex;align-items:center;gap:10px;margin-top:8px;font-size:12px;color:var(--text-3);}
    .envoi{position:sticky;top:0;}
    .modeles{display:flex;flex-wrap:wrap;gap:8px;}
    .chip-btn{display:inline-flex;align-items:center;gap:6px;height:32px;padding:0 12px;border-radius:999px;border:1px solid var(--border);background:var(--surface);font-size:13px;font-weight:600;color:var(--text-2);cursor:pointer;}
    .chip-btn:hover{border-color:var(--primary);color:var(--primary);background:var(--primary-light);}
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
    { icon: 'gift', label: 'Offre spéciale', titre: 'Offre exclusive TamBour !', message: '-20 % sur tous les trajets ce week-end. Réservez maintenant !' },
    { icon: 'alert', label: 'Perturbations', titre: 'Perturbations sur le réseau', message: 'Des retards sont à prévoir. Merci de votre compréhension.' },
    { icon: 'bell', label: 'Rappel voyage', titre: 'Votre voyage approche', message: 'Rappel : votre trajet est prévu demain. Soyez à la gare 30 min avant le départ.' },
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
  typeIcone(t: string): string { return ({ confirmation: 'check-circle', rappel: 'bell', retard: 'clock', promotion: 'gift', info: 'info', paiement: 'card', annulation: 'x-circle' } as Record<string, string>)[t] ?? 'bell'; }
}
