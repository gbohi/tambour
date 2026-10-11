import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-profil',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent, NombrePipe],
  template: `
    <div class="page" style="max-width:700px">
      <div class="card" style="display:flex;align-items:center;gap:20px;padding:24px">
        <div class="avatar avatar-lg" style="background:var(--gold)">{{ auth.user()?.initiales }}</div>
        <div style="flex:1">
          <div style="font-size:20px;font-weight:800">{{ auth.user()?.nom_complet }}</div>
          <div style="color:var(--text-2);font-size:13px">{{ auth.user()?.email }}</div>
          <div style="margin-top:6px">
            <span class="badge badge-primary">{{ roleLabel() }}</span>
            @if (auth.user()?.is_verified) { <span class="badge badge-success" style="margin-left:4px">Vérifié</span> }
          </div>
        </div>
        <div style="text-align:right">
          <div style="font-size:28px;font-weight:800;color:var(--gold)">{{ auth.user()?.points_fidelite }}</div>
          <div style="font-size:11px;color:var(--text-2)">points fidélité</div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-title" style="margin-bottom:18px">Modifier le profil</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
          <div class="form-group"><label class="form-label">Prénom</label><input type="text" class="form-control" [(ngModel)]="form.prenom"></div>
          <div class="form-group"><label class="form-label">Nom</label><input type="text" class="form-control" [(ngModel)]="form.nom"></div>
          <div class="form-group"><label class="form-label">Email</label><input type="email" class="form-control" [(ngModel)]="form.email"></div>
          <div class="form-group"><label class="form-label">Téléphone</label><input type="tel" class="form-control" [(ngModel)]="form.telephone"></div>
        </div>
        <h4 style="margin:18px 0 12px;color:var(--text-2)">Notifications</h4>
        <div style="display:flex;flex-direction:column;gap:10px">
          <label class="pref-row"><input type="checkbox" [(ngModel)]="form.notif_sms"><div><strong>SMS</strong><div style="font-size:12px;color:var(--text-2)">Confirmations et rappels</div></div></label>
          <label class="pref-row"><input type="checkbox" [(ngModel)]="form.notif_email"><div><strong>Email</strong><div style="font-size:12px;color:var(--text-2)">Notifications par email</div></div></label>
          <label class="pref-row"><input type="checkbox" [(ngModel)]="form.notif_promotions"><div><strong>Promotions</strong><div style="font-size:12px;color:var(--text-2)">Offres et réductions</div></div></label>
        </div>
        <button class="btn btn-primary" style="margin-top:20px" (click)="sauvegarder()" [disabled]="loading()">
          @if (loading()) { Enregistrement… } @else { Enregistrer }
        </button>
      </div>

      <div class="card">
        <h3 class="card-title" style="margin-bottom:18px">Changer le mot de passe</h3>
        @if (mdpErreur()) {
          <div style="background:var(--error-bg);border:1px solid rgba(217,64,64,0.2);border-radius:10px;padding:10px 14px;color:var(--error);font-size:13px;margin-bottom:12px">{{ mdpErreur() }}</div>
        }
        <div style="display:flex;flex-direction:column;gap:12px">
          <div class="form-group"><label class="form-label">Mot de passe actuel</label><input type="password" class="form-control" [(ngModel)]="mdp.actuel"></div>
          <div class="form-group"><label class="form-label">Nouveau mot de passe</label><input type="password" class="form-control" [(ngModel)]="mdp.nouveau"></div>
          <div class="form-group"><label class="form-label">Confirmer</label><input type="password" class="form-control" [(ngModel)]="mdp.confirmation"></div>
        </div>
        <button class="btn btn-outline" style="margin-top:16px" (click)="changerMdp()" [disabled]="mdpLoading()">
          @if (mdpLoading()) { Modification… } @else { Modifier le mot de passe }
        </button>
      </div>

      <div class="card">
        <h3 class="card-title" style="margin-bottom:14px">Informations du compte</h3>
        <div class="info-row"><span class="info-label">Rôle</span><span class="info-value"><span class="badge badge-primary">{{ roleLabel() }}</span></span></div>
        <div class="info-row"><span class="info-label">Membre depuis</span><span class="info-value">{{ auth.user()?.date_inscription | date:'dd MMMM yyyy' }}</span></div>
        <div class="info-row"><span class="info-label">Identifiant</span><span class="info-value" style="font-size:11px;font-family:monospace">{{ auth.user()?.id }}</span></div>
      </div>
    </div>
  `,
  styles: [`.pref-row{display:flex;align-items:flex-start;gap:12px;cursor:pointer;padding:10px 12px;border-radius:10px;transition:background 0.15s;} .pref-row:hover{background:var(--surface-2);} .pref-row input[type="checkbox"]{width:16px;height:16px;margin-top:2px;flex-shrink:0;accent-color:var(--primary);}`]
})
export class ProfilComponent implements OnInit {
  auth    = inject(AuthService);
  private toast = inject(ToastService);
  loading    = signal(false);
  mdpLoading = signal(false);
  mdpErreur  = signal<string | null>(null);
  form = { prenom:'', nom:'', email:'', telephone:'', notif_sms:true, notif_email:true, notif_promotions:true };
  mdp  = { actuel:'', nouveau:'', confirmation:'' };

  ngOnInit(): void {
    const u = this.auth.user();
    if (u) this.form = { prenom:u.prenom, nom:u.nom, email:u.email, telephone:u.telephone, notif_sms:u.notif_sms, notif_email:u.notif_email, notif_promotions:u.notif_promotions };
  }
  sauvegarder(): void {
    this.loading.set(true);
    this.auth.updateProfile(this.form).subscribe({
      next: () => { this.toast.success('Profil mis a jour.'); this.loading.set(false); },
      error: () => { this.toast.error('Erreur lors de la mise a jour.'); this.loading.set(false); }
    });
  }
  changerMdp(): void {
    this.mdpErreur.set(null);
    if (this.mdp.nouveau !== this.mdp.confirmation) { this.mdpErreur.set('Les mots de passe ne correspondent pas.'); return; }
    if (this.mdp.nouveau.length < 8) { this.mdpErreur.set('Minimum 8 caractères.'); return; }
    this.mdpLoading.set(true);
    this.auth.changePassword({ mot_de_passe_actuel:this.mdp.actuel, nouveau_mot_de_passe:this.mdp.nouveau, confirmation:this.mdp.confirmation }).subscribe({
      next: () => { this.toast.success('Mot de passe modifie.'); this.mdp = { actuel:'', nouveau:'', confirmation:'' }; this.mdpLoading.set(false); },
      error: (err: { error?: { message?: string } }) => { this.mdpErreur.set(err?.error?.message ?? 'Mot de passe actuel incorrect.'); this.mdpLoading.set(false); }
    });
  }
  roleLabel(): string {
    const r = this.auth.role();
    if (r === 'admin') return 'Administrateur';
    if (r === 'support') return 'Support';
    if (r === 'transporteur') return 'Transporteur';
    if (r === 'voyageur') return 'Voyageur';
    return '';
  }
}
