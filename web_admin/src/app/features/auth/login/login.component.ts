import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ToastService } from '../../../core/services/toast.service';
import { IconComponent } from '../../../shared/components/icon/icon.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent],
  template: `
    <div class="ecran">
      <section class="visuel">
        <div class="marque"><span class="logo"><tb-icon name="bus" [size]="22" [stroke]="2.2" /></span><span>Tam<b>Bour</b></span></div>
        <div class="accroche">
          <h1>Pilotez tout le réseau,<br>en temps réel.</h1>
          <p>Trajets, réservations, chauffeurs, paiements et service client : l'espace d'administration de TamBour.</p>
          <ul>
            <li><tb-icon name="route" [size]="18" /> Suivi des départs et du remplissage</li>
            <li><tb-icon name="steering" [size]="18" /> Affectation des chauffeurs</li>
            <li><tb-icon name="headset" [size]="18" /> Réclamations et messages clients</li>
          </ul>
        </div>
        <div class="pied">© {{ annee }} TamBour · Côte d'Ivoire</div>
      </section>

      <section class="formulaire">
        <form class="boite" (ngSubmit)="login()">
          <h2>Connexion</h2>
          <p class="sous">Accès réservé aux équipes TamBour et aux compagnies partenaires.</p>
          @if (erreur()) { <div class="alerte"><tb-icon name="alert" [size]="16" /> {{ erreur() }}</div> }
          <div class="form-group">
            <label class="form-label" for="email">Adresse email</label>
            <input id="email" type="email" class="form-control" [(ngModel)]="email" name="email" placeholder="vous@tambour.ci" required autocomplete="email">
          </div>
          <div class="form-group">
            <label class="form-label" for="mdp">Mot de passe</label>
            <div class="mdp">
              <input id="mdp" [type]="showPwd() ? 'text' : 'password'" class="form-control" [(ngModel)]="password" name="password"
                placeholder="Votre mot de passe" required autocomplete="current-password">
              <button type="button" class="icon-btn" (click)="showPwd.set(!showPwd())" [attr.aria-label]="showPwd() ? 'Masquer' : 'Afficher'">
                <tb-icon [name]="showPwd() ? 'eye' : 'lock'" [size]="16" />
              </button>
            </div>
          </div>
          <button type="submit" class="btn btn-primary btn-lg btn-block" [disabled]="loading()">
            @if (loading()) { <span class="spinner" style="width:18px;height:18px;border-color:rgba(255,255,255,.4);border-top-color:#fff"></span> Connexion… }
            @else { Se connecter <tb-icon name="arrow-right" [size]="18" /> }
          </button>
        </form>
      </section>
    </div>
  `,
  styles: [`
    .ecran{min-height:100vh;display:grid;grid-template-columns:1.1fr 1fr;background:var(--surface);}
    .visuel{position:relative;overflow:hidden;color:#fff;padding:40px 56px;display:flex;flex-direction:column;justify-content:space-between;
      background:radial-gradient(1200px 600px at -10% 110%,rgba(245,166,35,.35),transparent 60%),
                 radial-gradient(900px 500px at 110% -10%,rgba(19,168,110,.55),transparent 60%),
                 linear-gradient(160deg,#063D27 0%,#0A7C4E 60%,#0B8F59 100%);}
    .visuel::after{content:'';position:absolute;inset:0;background-image:radial-gradient(rgba(255,255,255,.08) 1px,transparent 1px);background-size:22px 22px;pointer-events:none;}
    .marque{display:flex;align-items:center;gap:10px;font-size:24px;font-weight:800;letter-spacing:-.02em;position:relative;z-index:1;}
    .marque b{color:var(--gold);}
    .logo{width:40px;height:40px;border-radius:12px;background:rgba(255,255,255,.14);display:flex;align-items:center;justify-content:center;backdrop-filter:blur(6px);}
    .accroche{position:relative;z-index:1;max-width:460px;}
    .accroche h1{font-size:40px;line-height:1.1;font-weight:800;letter-spacing:-.03em;margin-bottom:16px;}
    .accroche p{font-size:16px;opacity:.85;line-height:1.6;margin-bottom:28px;}
    .accroche ul{list-style:none;display:flex;flex-direction:column;gap:12px;}
    .accroche li{display:flex;align-items:center;gap:12px;font-weight:500;}
    .accroche li tb-icon{width:34px;height:34px;border-radius:10px;background:rgba(255,255,255,.14);display:inline-flex;align-items:center;justify-content:center;}
    .pied{font-size:13px;opacity:.7;position:relative;z-index:1;}
    .formulaire{display:flex;align-items:center;justify-content:center;padding:40px 24px;}
    .boite{width:100%;max-width:400px;display:flex;flex-direction:column;gap:18px;}
    .boite h2{font-size:28px;font-weight:800;letter-spacing:-.02em;}
    .sous{color:var(--text-2);margin-top:-10px;}
    .alerte{display:flex;align-items:center;gap:8px;background:var(--error-bg);color:var(--error);padding:12px 14px;border-radius:12px;font-size:13px;font-weight:500;}
    .mdp{position:relative;}
    .mdp .form-control{padding-right:48px;}
    .mdp .icon-btn{position:absolute;right:4px;top:4px;}
    @media (max-width:900px){.ecran{grid-template-columns:1fr;}.visuel{display:none;}}
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
  annee = new Date().getFullYear();

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
