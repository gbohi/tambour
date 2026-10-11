import { Component, HostListener, inject, signal } from '@angular/core';
import { RouterLink, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { AuthService } from '../../core/services/auth.service';
import { ApiService } from '../../core/services/api.service';
import { UiService } from '../../core/services/ui.service';
import { IconComponent } from '../../shared/components/icon/icon.component';

const TITRES: Record<string, string> = {
  '/dashboard': 'Tableau de bord', '/voyageurs': 'Voyageurs', '/transporteurs': 'Compagnies',
  '/trajets': 'Trajets', '/reservations': 'Réservations', '/paiements': 'Paiements',
  '/notifications': 'Notifications', '/gares': 'Gares', '/rapports': 'Rapports',
  '/profil': 'Mon profil', '/support': 'Support client', '/chauffeurs': 'Chauffeurs',
};

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [RouterLink, IconComponent],
  template: `
    <header class="topbar">
      <button class="icon-btn burger" (click)="ui.basculerMenu()" aria-label="Menu"><tb-icon name="menu" /></button>
      <div class="fil">
        <span class="racine">TamBour</span>
        <tb-icon name="chevron-right" [size]="14" />
        <span class="courant">{{ titre() }}</span>
      </div>
      <div class="droite">
        <span class="date">{{ aujourdhui }}</span>
        <a class="icon-btn" routerLink="/notifications" data-tip="Notifications">
          <tb-icon name="bell" />
          @if (nbNotifs() > 0) { <span class="pastille">{{ nbNotifs() > 9 ? '9+' : nbNotifs() }}</span> }
        </a>
        <div class="menu-user" (click)="$event.stopPropagation(); menuOuvert.set(!menuOuvert())">
          <div class="avatar gold">{{ auth.user()?.initiales }}</div>
          <tb-icon name="chevron-down" [size]="16" />
          @if (menuOuvert()) {
            <div class="dropdown" (click)="$event.stopPropagation()">
              <div class="dd-tete">
                <strong>{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</strong>
                <span>{{ auth.user()?.email }}</span>
              </div>
              <a routerLink="/profil" class="dd-item" (click)="menuOuvert.set(false)"><tb-icon name="user" [size]="16" /> Mon profil</a>
              <button class="dd-item danger" (click)="auth.logout()"><tb-icon name="logout" [size]="16" /> Déconnexion</button>
            </div>
          }
        </div>
      </div>
    </header>
  `,
  styles: [`
    .topbar{height:var(--topbar-h);flex-shrink:0;background:rgba(255,255,255,.85);backdrop-filter:saturate(180%) blur(12px);
      border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px;padding:0 32px;position:sticky;top:0;z-index:50;}
    .burger{display:none;}
    .fil{display:flex;align-items:center;gap:8px;color:var(--text-3);font-size:14px;min-width:0;}
    .fil .courant{color:var(--text-1);font-weight:700;white-space:nowrap;}
    .droite{margin-left:auto;display:flex;align-items:center;gap:8px;}
    .date{font-size:13px;color:var(--text-2);margin-right:6px;}
    a.icon-btn{text-decoration:none;}
    .pastille{position:absolute;top:3px;right:2px;min-width:16px;height:16px;padding:0 4px;background:var(--error);color:#fff;border-radius:8px;
      font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;border:2px solid #fff;}
    .menu-user{position:relative;display:flex;align-items:center;gap:6px;padding:4px 8px 4px 4px;border-radius:999px;cursor:pointer;color:var(--text-2);border:1px solid var(--border);background:var(--surface);}
    .menu-user:hover{background:var(--surface-2);}
    .menu-user .avatar{width:32px;height:32px;font-size:12px;}
    .dropdown{position:absolute;top:calc(100% + 8px);right:0;min-width:240px;background:var(--surface);border:1px solid var(--border);
      border-radius:14px;box-shadow:var(--shadow-md);overflow:hidden;z-index:200;padding:6px;animation:slideUp .15s ease;}
    .dd-tete{display:flex;flex-direction:column;padding:10px 12px 12px;border-bottom:1px solid var(--divider);margin-bottom:6px;}
    .dd-tete strong{font-size:14px;color:var(--text-1);}
    .dd-tete span{font-size:12px;color:var(--text-2);}
    .dd-item{display:flex;align-items:center;gap:10px;padding:9px 12px;font-size:14px;font-weight:500;cursor:pointer;width:100%;background:none;
      border:none;text-decoration:none;color:var(--text-1);border-radius:9px;}
    .dd-item:hover{background:var(--surface-2);}
    .dd-item.danger{color:var(--error);}
    @media (max-width:1024px){ .topbar{padding:0 16px;} .burger{display:inline-flex;} .date{display:none;} }
  `]
})
export class TopbarComponent {
  auth = inject(AuthService);
  ui = inject(UiService);
  private api = inject(ApiService);
  private router = inject(Router);
  menuOuvert = signal(false);
  nbNotifs = signal(0);
  titre = signal('Tableau de bord');
  aujourdhui = (d => d.charAt(0).toUpperCase() + d.slice(1))(
    new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' }).format(new Date()));

  constructor() {
    this.majTitre(this.router.url);
    this.router.events.pipe(filter(e => e instanceof NavigationEnd)).subscribe(e => {
      this.majTitre((e as NavigationEnd).urlAfterRedirects);
      this.menuOuvert.set(false);
    });
    this.api.getNotifications({ limit: '1' }).subscribe({
      next: res => this.nbNotifs.set(res.data.nb_non_lues ?? 0), error: () => {},
    });
  }

  @HostListener('document:click') fermer(): void { this.menuOuvert.set(false); }

  private majTitre(url: string): void {
    this.titre.set(TITRES['/' + (url.split('?')[0].split('/')[1] ?? '')] ?? 'TamBour Admin');
  }
}
