import { Component, HostListener, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive } from '@angular/router';
import { filter } from 'rxjs';
import { AuthService } from '../../core/auth.service';
import { IconComponent } from './icon/icon.component';
import { NombrePipe } from '../pipes/nombre.pipe';

@Component({
  selector: 'tb-entete',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, IconComponent, NombrePipe],
  template: `
    <header class="entete" [class.transparent]="transparent()" [class.ombre]="defile()">
      <div class="conteneur barre">
        <a routerLink="/" class="logo" aria-label="TamBour, accueil">
          <span class="pict"><tb-icon name="bus" [size]="20" [stroke]="2.3" /></span>
          <span class="nom">Tam<b>Bour</b></span>
        </a>
        <nav class="liens" [class.ouvert]="menu()">
          <a routerLink="/destinations" routerLinkActive="actif" (click)="menu.set(false)">Destinations</a>
          <a routerLink="/gares" routerLinkActive="actif" (click)="menu.set(false)">Gares</a>
          <a routerLink="/aide" routerLinkActive="actif" (click)="menu.set(false)">Aide</a>
          @if (auth.connecte()) {
            <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }" class="lien-mobile" (click)="menu.set(false)">Mes billets</a>
          } @else {
            <a routerLink="/connexion" class="lien-mobile" (click)="menu.set(false)">Se connecter</a>
          }
        </nav>
        <div class="droite">
          @if (auth.user(); as u) {
            <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }" class="btn btn-sm billets"><tb-icon name="ticket" [size]="18" /> Mes billets</a>
            <a routerLink="/compte" class="compte" title="Mon compte">
              <span class="points"><tb-icon name="star" [size]="14" /> {{ u.points_fidelite | nb }}</span>
              <span class="avatar">{{ u.initiales }}</span>
            </a>
          } @else {
            <a routerLink="/connexion" class="btn btn-sm connexion"><tb-icon name="user" [size]="18" /> Se connecter</a>
          }
          <button class="burger" (click)="menu.set(!menu())" aria-label="Menu"><tb-icon [name]="menu() ? 'x' : 'menu'" [size]="22" /></button>
        </div>
      </div>
    </header>
    @if (!transparent()) { <div class="espace"></div> }
  `,
  styles: [`
    .entete{position:fixed;top:0;left:0;right:0;z-index:500;background:rgba(255,255,255,.92);backdrop-filter:saturate(180%) blur(14px);
      border-bottom:1px solid transparent;transition:background .25s,border-color .25s,box-shadow .25s;}
    .entete.ombre{border-bottom-color:var(--bord);box-shadow:0 6px 20px -12px rgba(11,26,20,.25);}
    .entete.transparent:not(.ombre){background:transparent;backdrop-filter:none;}
    .espace{height:72px;}
    .barre{height:72px;display:flex;align-items:center;gap:28px;}
    .logo{display:flex;align-items:center;gap:10px;}
    .pict{width:38px;height:38px;border-radius:12px;background:linear-gradient(135deg,var(--vert),var(--vert-vif));color:#fff;display:flex;align-items:center;justify-content:center;
      box-shadow:0 8px 18px -6px rgba(10,124,78,.6);}
    .nom{font-size:23px;font-weight:800;letter-spacing:-.03em;color:var(--encre);}
    .nom b{color:var(--or);}
    .liens{display:flex;gap:6px;}
    .liens a{padding:8px 14px;border-radius:999px;font-weight:600;color:var(--texte-2);transition:background .15s,color .15s;}
    .liens a:hover{background:var(--surface-2);color:var(--texte);}
    .liens a.actif{color:var(--vert);}
    .lien-mobile{display:none;}
    .droite{margin-left:auto;display:flex;align-items:center;gap:10px;}
    .billets,.connexion{background:var(--surface-2);color:var(--texte);}
    .billets:hover,.connexion:hover{background:var(--vert-clair);color:var(--vert);}
    .compte{display:flex;align-items:center;gap:6px;padding:4px 4px 4px 12px;border-radius:999px;border:1px solid var(--bord);background:#fff;}
    .points{display:inline-flex;align-items:center;gap:4px;font-weight:700;font-size:14px;color:var(--or-fonce);}
    .avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,var(--or),#FFC766);color:var(--encre);font-weight:800;font-size:13px;display:flex;align-items:center;justify-content:center;}
    .burger{display:none;border:none;background:var(--surface-2);width:42px;height:42px;border-radius:12px;cursor:pointer;align-items:center;justify-content:center;}
    /* Sur le hero (page d'accueil, avant défilement) : texte blanc */
    .transparent:not(.ombre) .nom{color:#fff;}
    .transparent:not(.ombre) .liens a{color:rgba(255,255,255,.85);}
    .transparent:not(.ombre) .liens a:hover{background:rgba(255,255,255,.12);color:#fff;}
    .transparent:not(.ombre) .billets,.transparent:not(.ombre) .connexion{background:rgba(255,255,255,.14);color:#fff;}
    .transparent:not(.ombre) .compte{background:rgba(255,255,255,.12);border-color:rgba(255,255,255,.25);}
    .transparent:not(.ombre) .points{color:var(--or);}
    .transparent:not(.ombre) .burger{background:rgba(255,255,255,.14);color:#fff;}
    @media (max-width:860px){
      .burger{display:inline-flex;}
      .billets{display:none;}
      .liens{position:fixed;top:72px;left:0;right:0;flex-direction:column;background:#fff;padding:12px 16px 20px;border-bottom:1px solid var(--bord);
        box-shadow:var(--ombre-2);transform:translateY(-8px);opacity:0;pointer-events:none;transition:all .2s;}
      .liens.ouvert{transform:none;opacity:1;pointer-events:auto;}
      .liens a,.transparent:not(.ombre) .liens a{color:var(--texte);padding:14px 12px;font-size:17px;}
      .lien-mobile{display:block;}
      .connexion{display:none;}
    }
  `],
})
export class EnteteComponent {
  auth = inject(AuthService);
  private router = inject(Router);
  menu = signal(false);
  defile = signal(false);
  transparent = signal(true);

  constructor() {
    this.majTransparence(this.router.url);
    this.router.events.pipe(filter(e => e instanceof NavigationEnd)).subscribe(e => {
      this.majTransparence((e as NavigationEnd).urlAfterRedirects);
      this.menu.set(false);
    });
    if (this.auth.connecte()) this.auth.rafraichirProfil();
  }

  /** En-tête transparent uniquement sur l'accueil (posé sur le visuel). */
  private majTransparence(url: string): void { this.transparent.set(url.split('?')[0] === '/'); }

  @HostListener('window:scroll') onScroll(): void { this.defile.set(window.scrollY > 24 || this.menu()); }
}
