import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login-page">
      <!-- Branding -->
      <div class="login-brand">
        <div class="brand-content">
          <div class="brand-logo"><span class="ly">Tam</span><span class="lb">Bour</span></div>
          <h1 class="brand-title">Espace Administration</h1>
          <p class="brand-sub">Gérez vos trajets, voyageurs et paiements depuis un seul tableau de bord.</p>
          <div class="brand-stats">
            <div class="bst"><div class="bst-v">8</div><div class="bst-l">Villes desservies</div></div>
            <div class="bst"><div class="bst-v">30+</div><div class="bst-l">Trajets/jour</div></div>
            <div class="bst"><div class="bst-v">15K+</div><div class="bst-l">Voyageurs</div></div>
          </div>
        </div>
        <div class="circles">
          <div class="c c1"></div><div class="c c2"></div><div class="c c3"></div>
        </div>
      </div>

      <!-- Formulaire -->
      <div class="login-form-panel">
        <div class="login-form-wrap">
          <div class="form-header">
            <h2>Connexion</h2>
            <p>Entrez vos identifiants pour accéder au dashboard.</p>
          </div>
          @if (erreur()) {
            <div class="alert-error">&#9888; {{ erreur() }}</div>
          }
          <form (ngSubmit)="login()">
            <div class="form-group">
              <label class="form-label">Adresse email</label>
              <input type="email" class="form-control" [(ngModel)]="email" name="email"
                placeholder="admin@tambour.ci" required autocomplete="email">
            </div>
            <div class="form-group" style="margin-top:14px">
              <label class="form-label">Mot de passe</label>
              <div style="position:relative">
                <input [type]="showPwd() ? 'text' : 'password'" class="form-control"
                  [(ngModel)]="password" name="password" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;"
                  required autocomplete="current-password" style="padding-right:40px">
                <button type="button" style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;font-size:16px"
                  (click)="showPwd.set(!showPwd())">{{ showPwd() ? '👁' : '🙈' }}</button>
              </div>
            </div>
            <button type="submit" class="btn btn-primary w-full" style="margin-top:24px;height:48px;width:100%"
              [disabled]="loading()">
              @if (loading()) { &#9203; Connexion… } @else { Se connecter }
            </button>
          </form>
          <!-- Info rôles -->
          <div class="roles-info">
            <div class="ri-title">Accès selon rôle</div>
            <div class="ri-row"><span class="ri-badge ri-admin">Admin</span><span>Dashboard complet + gestion totale</span></div>
            <div class="ri-row"><span class="ri-badge ri-support">Support</span><span>Voyageurs, trajets, réservations</span></div>
            <div class="ri-row"><span class="ri-badge ri-transport">Transporteur</span><span>Ses trajets et réservations uniquement</span></div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .login-page{display:flex;height:100vh;}
    .login-brand{width:480px;background:var(--sidebar-bg);position:relative;overflow:hidden;display:flex;align-items:center;justify-content:center;padding:48px;flex-shrink:0;}
    .brand-content{position:relative;z-index:2;}
    .brand-logo{font-size:52px;font-weight:900;line-height:1;margin-bottom:24px;}
    .ly{color:#fff;} .lb{color:#F5A623;}
    .brand-title{font-size:26px;font-weight:800;color:#fff;margin-bottom:14px;line-height:1.3;}
    .brand-sub{font-size:14px;color:rgba(255,255,255,0.6);line-height:1.7;margin-bottom:40px;}
    .brand-stats{display:flex;gap:24px;}
    .bst{text-align:center;}
    .bst-v{font-size:28px;font-weight:800;color:#F5A623;}
    .bst-l{font-size:11px;color:rgba(255,255,255,0.5);margin-top:4px;}
    .circles{position:absolute;inset:0;pointer-events:none;}
    .c{position:absolute;border-radius:50%;border:1px solid rgba(255,255,255,0.04);}
    .c1{width:400px;height:400px;top:-100px;right:-150px;}
    .c2{width:240px;height:240px;bottom:40px;right:-60px;border-color:rgba(10,124,78,0.2);}
    .c3{width:120px;height:120px;bottom:160px;left:32px;border-color:rgba(245,166,35,0.2);}
    .login-form-panel{flex:1;display:flex;align-items:center;justify-content:center;padding:40px;background:var(--bg);overflow-y:auto;}
    .login-form-wrap{width:100%;max-width:420px;}
    .form-header{margin-bottom:28px;}
    .form-header h2{font-size:26px;font-weight:800;color:var(--text-1);}
    .form-header p{font-size:14px;color:var(--text-2);margin-top:6px;}
    .alert-error{display:flex;align-items:center;gap:8px;background:var(--error-bg);border:1px solid rgba(217,64,64,0.2);border-radius:10px;padding:12px 14px;color:var(--error);font-size:13px;margin-bottom:16px;}
    .roles-info{margin-top:28px;padding:16px;background:var(--surface-2);border-radius:12px;}
    .ri-title{font-size:11px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:0.5px;margin-bottom:10px;}
    .ri-row{display:flex;align-items:center;gap:10px;font-size:12px;color:var(--text-2);margin-bottom:8px;}
    .ri-badge{padding:2px 8px;border-radius:20px;font-size:10px;font-weight:700;width:80px;text-align:center;flex-shrink:0;}
    .ri-admin{background:var(--primary-light);color:var(--primary);}
    .ri-support{background:var(--info-bg);color:var(--info);}
    .ri-transport{background:var(--gold-light);color:var(--gold);}
  `]
})
export class LoginComponent {
  private auth   = inject(AuthService);
  private router = inject(Router);
  private toast  = inject(ToastService);

  email   = '';
  password = '';
  erreur  = signal<string | null>(null);
  loading = this.auth.loading;
  showPwd = signal(false);

  login(): void {
    if (!this.email || !this.password) { this.erreur.set('Veuillez remplir tous les champs.'); return; }
    this.erreur.set(null);
    this.auth.login({ email: this.email, password: this.password }).subscribe({
      next: res => {
        this.toast.success("Bienvenue " + res.data.user.prenom + " !");
        this.router.navigate(res.data.user.role === 'transporteur' ? ['/trajets'] : ['/dashboard']);
      },
      error: err => {
        const msg: string = err?.error?.message ?? "Email ou mot de passe incorrect.";
        this.erreur.set(msg);
      }
    });
  }
}
