import { Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../core/services/auth.service';

interface NavItem { label: string; icon: string; path: string; roles?: string[]; }

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  template: `
    <aside class="sidebar">
      <div class="sb-logo">
        <div class="logo-mark"><span class="ly">Tam</span><span class="lb">Bour</span></div>
        <div class="logo-sub">Administration</div>
      </div>
      <div class="sb-role">
        <div class="role-dot"></div>
        <span>{{ roleLabel() }}</span>
      </div>
      <nav class="sb-nav">
        @for (item of visibleItems(); track item.path) {
          <a [routerLink]="item.path" routerLinkActive="active" class="nav-item">
            <span class="nav-icon">{{ item.icon }}</span>
            <span class="nav-label">{{ item.label }}</span>
          </a>
        }
      </nav>
      <div class="sb-footer">
        <a routerLink="/profil" class="nav-item">
          <div class="av-sm">{{ auth.user()?.initiales }}</div>
          <div class="nav-user">
            <span class="nav-label">{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</span>
            <span class="nav-email">{{ auth.user()?.email }}</span>
          </div>
        </a>
        <button class="btn-logout" (click)="auth.logout()">&#9166; Déconnexion</button>
      </div>
    </aside>
  `,
  styles: [`
    .sidebar{position:fixed;top:0;left:0;width:var(--sidebar-w);height:100vh;background:var(--sidebar-bg);display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,0.05);z-index:100;overflow-y:auto;}
    .sb-logo{padding:24px 20px 16px;border-bottom:1px solid rgba(255,255,255,0.06);}
    .logo-mark{font-size:26px;font-weight:900;line-height:1;}
    .ly{color:#fff;} .lb{color:#F5A623;}
    .logo-sub{font-size:10px;color:rgba(255,255,255,0.4);margin-top:2px;letter-spacing:1.5px;text-transform:uppercase;}
    .sb-role{display:flex;align-items:center;gap:8px;padding:10px 20px;margin:8px 12px;background:rgba(10,124,78,0.15);border-radius:8px;font-size:11px;font-weight:600;color:#0A7C4E;border:1px solid rgba(10,124,78,0.25);}
    .role-dot{width:6px;height:6px;border-radius:50%;background:#0A7C4E;flex-shrink:0;}
    .sb-nav{flex:1;padding:8px 12px;display:flex;flex-direction:column;gap:2px;}
    .nav-item{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:10px;color:rgba(255,255,255,0.65);text-decoration:none;font-size:13px;font-weight:500;cursor:pointer;transition:all 0.15s;}
    .nav-item:hover{background:rgba(255,255,255,0.06);color:#fff;}
    .nav-item.active{background:rgba(10,124,78,0.25);color:#fff;border:1px solid rgba(10,124,78,0.3);}
    .nav-icon{font-size:16px;flex-shrink:0;width:20px;text-align:center;}
    .nav-label{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .sb-footer{padding:12px;border-top:1px solid rgba(255,255,255,0.06);}
    .av-sm{width:32px;height:32px;border-radius:50%;background:#F5A623;color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0;}
    .nav-user{display:flex;flex-direction:column;overflow:hidden;}
    .nav-email{font-size:10px;color:rgba(255,255,255,0.4);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .btn-logout{width:100%;margin-top:8px;background:rgba(217,64,64,0.12);color:#D94040;border:none;border-radius:8px;padding:8px;font-size:12px;font-weight:600;cursor:pointer;font-family:'Outfit',sans-serif;transition:background 0.15s;}
    .btn-logout:hover{background:rgba(217,64,64,0.2);}
  `]
})
export class SidebarComponent {
  auth = inject(AuthService);
  private readonly ALL: NavItem[] = [
    { label: 'Tableau de bord', icon: '📊', path: '/dashboard',     roles: ['admin','support'] },
    { label: 'Voyageurs',       icon: '👥', path: '/voyageurs',     roles: ['admin','support'] },
    { label: 'Transporteurs',   icon: '🚌', path: '/transporteurs', roles: ['admin'] },
    { label: 'Trajets',         icon: '🗺️', path: '/trajets',       roles: ['admin','support','transporteur'] },
    { label: 'Réservations',    icon: '🎫', path: '/reservations',  roles: ['admin','support','transporteur'] },
    { label: 'Paiements',       icon: '💳', path: '/paiements',     roles: ['admin'] },
    { label: 'Notifications',   icon: '🔔', path: '/notifications', roles: ['admin','support'] },
    { label: 'Gares',           icon: '📍', path: '/gares',         roles: ['admin'] },
    { label: 'Rapports',        icon: '📈', path: '/rapports',      roles: ['admin'] },
    { label: 'Mon profil',      icon: '⚙️', path: '/profil' },
  ];
  visibleItems(): NavItem[] {
    const role = this.auth.role();
    return this.ALL.filter(i => !i.roles || (role ? i.roles.includes(role) : false));
  }
  roleLabel(): string {
    const r = this.auth.role();
    if (r === 'admin') return 'Administrateur';
    if (r === 'support') return 'Support';
    if (r === 'transporteur') return 'Transporteur';
    if (r === 'voyageur') return 'Voyageur';
    return 'Invité';
  }
}
