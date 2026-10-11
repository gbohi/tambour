import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of, catchError } from 'rxjs';
import { ApiService, messageErreur } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { IconComponent } from '../../shared/components/icon/icon.component';

@Component({
  selector: 'tb-connexion',
  standalone: true,
  imports: [FormsModule, IconComponent],
  template: `
    <div class="page">
      <div class="boite carte">
        <div class="segment">
          <button [class.actif]="mode() === 'connexion'" (click)="changer('connexion')">Se connecter</button>
          <button [class.actif]="mode() === 'inscription'" (click)="changer('inscription')">Créer un compte</button>
        </div>

        @if (mode() === 'connexion') {
          <form (ngSubmit)="seConnecter()" class="form">
            <div><h1>Bon retour !</h1><p class="muted">Retrouvez vos billets et vos points fidélité.</p></div>
            <div class="champ"><label>Email</label><input class="entree" type="email" name="email" [(ngModel)]="email" autocomplete="email" required></div>
            <div class="champ"><label>Mot de passe</label><input class="entree" type="password" name="mdp" [(ngModel)]="motDePasse" autocomplete="current-password" required></div>
            @if (erreur()) { <div class="alerte erreur"><tb-icon name="alert" [size]="18" /> {{ erreur() }}</div> }
            <button class="btn btn-primaire btn-lg btn-bloc" [disabled]="envoi()">
              @if (envoi()) { <span class="spinner blanc"></span> } @else { Se connecter }
            </button>
          </form>
        } @else {
          <form (ngSubmit)="sInscrire()" class="form">
            <div><h1>Bienvenue à bord</h1><p class="muted">Réservez plus vite et cumulez des points à chaque voyage.</p></div>
            <div class="ligne-champs">
              <div class="champ"><label>Prénom</label><input class="entree" name="prenom" [(ngModel)]="ins.prenom" autocomplete="given-name" required></div>
              <div class="champ"><label>Nom</label><input class="entree" name="nom" [(ngModel)]="ins.nom" autocomplete="family-name" required></div>
            </div>
            <div class="champ"><label>Téléphone</label><input class="entree" type="tel" name="tel" [(ngModel)]="ins.telephone" placeholder="07 00 00 00 00" autocomplete="tel" required></div>
            <div class="champ"><label>Email</label><input class="entree" type="email" name="email2" [(ngModel)]="ins.email" autocomplete="email" required></div>
            <div class="champ"><label>Mot de passe</label><input class="entree" type="password" name="mdp2" [(ngModel)]="ins.password" autocomplete="new-password" required>
              <span class="aide">8 caractères minimum, pas uniquement des chiffres.</span></div>
            <div class="champ parrain">
              <label><tb-icon name="gift" [size]="16" /> Code de parrainage <span class="hint">(facultatif)</span></label>
              <input class="entree mono" name="code" [(ngModel)]="ins.code_parrainage" (ngModelChange)="code$.next($event)" placeholder="Ex. : TB7K2QX9" maxlength="12">
              @if (parrain()) { <span class="ok"><tb-icon name="check-circle" [size]="16" /> Parrainé par {{ parrain() }} : vous recevrez {{ pointsBienvenue() }} points de bienvenue.</span> }
              @else if (codeInvalide()) { <span class="erreur-champ">Code introuvable : vérifiez-le ou laissez vide.</span> }
            </div>
            @if (erreur()) { <div class="alerte erreur"><tb-icon name="alert" [size]="18" /> {{ erreur() }}</div> }
            <button class="btn btn-primaire btn-lg btn-bloc" [disabled]="envoi()">
              @if (envoi()) { <span class="spinner blanc"></span> } @else { Créer mon compte }
            </button>
            <p class="cgu">En créant un compte, vous acceptez les conditions d'utilisation et la politique de confidentialité de TamBour.</p>
          </form>
        }
      </div>
    </div>
  `,
  styles: [`
    .page{min-height:calc(100vh - 72px);display:flex;align-items:center;justify-content:center;padding:40px 16px;
      background:radial-gradient(800px 400px at 100% 0,rgba(25,195,125,.12),transparent 60%),radial-gradient(600px 300px at 0 100%,rgba(245,166,35,.12),transparent 60%);}
    .boite{width:100%;max-width:480px;padding:32px;display:flex;flex-direction:column;gap:24px;box-shadow:var(--ombre-2);}
    @media (max-width:520px){.boite{padding:22px;}}
    .segment{align-self:stretch;display:grid;grid-template-columns:1fr 1fr;}
    .form{display:flex;flex-direction:column;gap:16px;}
    h1{font-size:28px;font-weight:800;letter-spacing:-.03em;}
    .parrain label{display:flex;align-items:center;gap:6px;}
    .parrain input{text-transform:uppercase;letter-spacing:.1em;}
    .ok{display:flex;align-items:center;gap:6px;font-size:13px;color:var(--vert);font-weight:600;}
    .cgu{font-size:12px;color:var(--texte-3);text-align:center;}
  `],
})
export class ConnexionComponent implements OnInit {
  private auth = inject(AuthService);
  private api = inject(ApiService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);

  mode = signal<'connexion' | 'inscription'>('connexion');
  envoi = signal(false);
  erreur = signal('');
  parrain = signal('');
  pointsBienvenue = signal(0);
  codeInvalide = signal(false);
  code$ = new Subject<string>();
  email = ''; motDePasse = '';
  ins = { prenom: '', nom: '', telephone: '', email: '', password: '', code_parrainage: '' };

  ngOnInit(): void {
    const q = this.route.snapshot.queryParamMap;
    if (q.get('mode') === 'inscription') this.mode.set('inscription');
    const code = q.get('code');
    if (code) { this.mode.set('inscription'); this.ins.code_parrainage = code.toUpperCase(); setTimeout(() => this.code$.next(code)); }
    this.code$.pipe(
      debounceTime(350), distinctUntilChanged(),
      switchMap(c => c.trim().length >= 8 ? this.api.verifierParrain(c.trim().toUpperCase()).pipe(catchError(() => of(null))) : of(undefined)),
    ).subscribe(r => {
      this.parrain.set(r?.parrain_prenom ?? '');
      this.pointsBienvenue.set(r?.points_filleul ?? 0);
      this.codeInvalide.set(r === null);
    });
  }

  changer(m: 'connexion' | 'inscription'): void { this.mode.set(m); this.erreur.set(''); }

  seConnecter(): void {
    if (!this.email || !this.motDePasse) { this.erreur.set('Saisissez votre email et votre mot de passe.'); return; }
    this.envoi.set(true); this.erreur.set('');
    this.auth.connexion(this.email.trim(), this.motDePasse).subscribe({
      next: u => { this.toast.succes(`Bonjour ${u.prenom} !`); this.redirection(); },
      error: e => { this.envoi.set(false); this.erreur.set(messageErreur(e, 'Email ou mot de passe incorrect.')); },
    });
  }

  sInscrire(): void {
    const d = this.ins;
    if (!d.prenom || !d.nom || !d.email || !d.telephone || !d.password) { this.erreur.set('Tous les champs sont requis (sauf le code de parrainage).'); return; }
    this.envoi.set(true); this.erreur.set('');
    this.auth.inscription({ ...d, email: d.email.trim(), telephone: d.telephone.replace(/\s/g, ''),
      code_parrainage: d.code_parrainage.trim().toUpperCase() || undefined }).subscribe({
      next: u => { this.toast.succes(`Bienvenue ${u.prenom} ! Votre compte est créé.`); this.redirection(); },
      error: e => { this.envoi.set(false); this.erreur.set(messageErreur(e, 'Inscription impossible. Vérifiez vos informations.')); },
    });
  }

  private redirection(): void {
    const retour = this.route.snapshot.queryParamMap.get('retour');
    this.router.navigateByUrl(retour && retour.startsWith('/') ? retour : '/compte');
  }
}
