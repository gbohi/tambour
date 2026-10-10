import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { AuthService } from '../../core/services/auth.service';
import { ApiService } from '../../core/services/api.service';

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <header class="topbar">
      <h2 class="topbar-title">{{ pageTitle() }}</h2>
      <div class="topbar-right">
        <button class="topbar-btn" routerLink="/notifications">
          🔔
          @if (nbNotifs() > 0) { <span class="notif-dot">{{ nbNotifs() }}</span> }
        </button>
        <div class="user-menu" (click)="menuOpen.set(!menuOpen())">
          <div class="avatar">{{ auth.user()?.initiales }}</div>
          <div class="user-info">
            <span class="user-name">{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</span>
            <span class="user-role">{{ roleLabel() }}</span>
          </div>
          <span style="color:#aaa">&#9660;</span>
          @if (menuOpen()) {
            <div class="dropdown">
              <a routerLink="/profil" class="dd-item">&#9881; Mon profil</a>
              <div class="dd-sep"></div>
              <button class="dd-item danger" (click)="auth.logout()">&#9166; Déconnexion</button>
            </div>
          }
        </div>
      </div>
    </header>
  `,
  styles: [`
    .topbar{height:var(--topbar-h);background:var(--surface);border-bottom:0.5px solid var(--border);display:flex;align-items:center;justify-content:space-between;padding:0 28px;position:sticky;top:0;z-index:50;box-shadow:var(--shadow-sm);}
    .topbar-title{font-size:17px;font-weight:700;color:var(--text-1);}
    .topbar-right{display:flex;align-items:center;gap:8px;}
    .topbar-btn{position:relative;background:var(--surface-2);border:none;border-radius:10px;width:38px;height:38px;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;}
    .notif-dot{position:absolute;top:4px;right:4px;width:16px;height:16px;background:var(--error);color:#fff;border-radius:50%;font-size:9px;font-weight:700;display:flex;align-items:center;justify-content:center;}
    .user-menu{display:flex;align-items:center;gap:10px;padding:6px 12px;border-radius:12px;cursor:pointer;position:relative;transition:background 0.15s;}
    .user-menu:hover{background:var(--surface-2);}
    .avatar{width:34px;height:34px;border-radius:50%;background:var(--gold);color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;}
    .user-info{display:flex;flex-direction:column;}
    .user-name{font-size:13px;font-weight:600;line-height:1.2;}
    .user-role{font-size:11px;color:var(--text-2);}
    .dropdown{position:absolute;top:calc(100% + 6px);right:0;min-width:180px;background:var(--surface);border:0.5px solid var(--border);border-radius:12px;box-shadow:var(--shadow-md);overflow:hidden;z-index:200;}
    .dd-item{display:flex;align-items:center;gap:8px;padding:10px 16px;font-size:13px;font-weight:500;cursor:pointer;width:100%;background:none;border:none;font-family:'Outfit',sans-serif;text-decoration:none;color:var(--text-1);}
    .dd-item:hover{background:var(--surface-2);}
    .dd-item.danger{color:var(--error);}
    .dd-sep{height:0.5px;background:var(--divider);margin:4px 0;}
  `]
})
export class TopbarComponent {
  auth     = inject(AuthService);
  private api    = inject(ApiService);
  private router = inject(Router);
  menuOpen = signal(false);
  nbNotifs = signal(0);
  pageTitle = signal('TamBour Admin');

  private readonly TITLES: Record<string, string> = {
    '/dashboard': 'Tableau de bord', '/voyageurs': 'Voyageurs',
    '/transporteurs': 'Transporteurs', '/trajets': 'Trajets',
    '/reservations': 'Réservations', '/paiements': 'Paiements',
    '/notifications': 'Notifications', '/gares': 'Gares',
    '/rapports': 'Rapports & exports', '/profil': 'Mon profil',
    '/support': 'Support client',
  };

  constructor() {
    this.router.events.pipe(filter(e => e instanceof NavigationEnd)).subscribe((e: unknown) => {
      const nav = e as NavigationEnd;
      const seg = '/' + (nav.urlAfterRedirects.split('/')[1] ?? '');
      this.pageTitle.set(this.TITLES[seg] ?? 'TamBour Admin');
      this.menuOpen.set(false);
    });
    this.loadNotifs();
  }

  private loadNotifs(): void {
    this.api.getNotifications({ limit: '1' }).subscribe({
      next: res => this.nbNotifs.set(res.data.nb_non_lues ?? 0),
      error: () => {}
    });
  }

  roleLabel(): string {
    const r = this.auth.role();
    if (r === 'admin') return 'Admin';
    if (r === 'support') return 'Support';
    if (r === 'transporteur') return 'Transporteur';
    return '';
  }
}
