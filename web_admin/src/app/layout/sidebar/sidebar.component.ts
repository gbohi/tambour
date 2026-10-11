import { Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { UiService } from '../../core/services/ui.service';
import { IconComponent } from '../../shared/components/icon/icon.component';

interface NavItem { label: string; icon: string; path: string; roles?: string[]; }
interface NavSection { titre: string; items: NavItem[]; }

const SECTIONS: NavSection[] = [
  { titre: 'Pilotage', items: [
    { label: 'Tableau de bord', icon: 'dashboard', path: '/dashboard', roles: ['admin', 'support'] },
    { label: 'Rapports',        icon: 'chart',     path: '/rapports',  roles: ['admin'] },
  ]},
  { titre: 'Exploitation', items: [
    { label: 'Trajets',       icon: 'route',    path: '/trajets',       roles: ['admin', 'support', 'transporteur'] },
    { label: 'Réservations',  icon: 'ticket',   path: '/reservations',  roles: ['admin', 'support', 'transporteur'] },
    { label: 'Chauffeurs',    icon: 'steering', path: '/chauffeurs',    roles: ['admin', 'support'] },
    { label: 'Compagnies',    icon: 'building', path: '/transporteurs', roles: ['admin'] },
    { label: 'Gares',         icon: 'map-pin',  path: '/gares',         roles: ['admin'] },
  ]},
  { titre: 'Clients', items: [
    { label: 'Voyageurs',      icon: 'users',   path: '/voyageurs',     roles: ['admin', 'support'] },
    { label: 'Support client', icon: 'headset', path: '/support',       roles: ['admin', 'support'] },
    { label: 'Notifications',  icon: 'bell',    path: '/notifications', roles: ['admin', 'support'] },
  ]},
  { titre: 'Finances', items: [
    { label: 'Paiements', icon: 'wallet', path: '/paiements', roles: ['admin'] },
  ]},
];

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, IconComponent],
  template: `
    @if (ui.menuOuvert()) { <div class="voile" (click)="ui.fermerMenu()"></div> }
    <aside class="sidebar" [class.ouvert]="ui.menuOuvert()">
      <a routerLink="/dashboard" class="marque" (click)="ui.fermerMenu()">
        <span class="logo"><tb-icon name="bus" [size]="20" [stroke]="2.2" /></span>
        <span class="nom">Tam<b>Bour</b></span>
        <span class="tag">Admin</span>
      </a>

      <nav class="nav">
        @for (s of sections(); track s.titre) {
          <div class="section">{{ s.titre }}</div>
          @for (item of s.items; track item.path) {
            <a [routerLink]="item.path" routerLinkActive="active" class="item" (click)="ui.fermerMenu()">
              <tb-icon [name]="item.icon" [size]="18" />
              <span>{{ item.label }}</span>
            </a>
          }
        }
      </nav>

      <div class="pied">
        <a routerLink="/profil" routerLinkActive="active" class="compte" (click)="ui.fermerMenu()">
          <div class="avatar gold">{{ auth.user()?.initiales }}</div>
          <div class="qui">
            <span class="n">{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</span>
            <span class="r">{{ roleLabel() }}</span>
          </div>
        </a>
        <button class="icon-btn danger" data-tip="Déconnexion" (click)="auth.logout()">
          <tb-icon name="logout" [size]="18" />
        </button>
      </div>
    </aside>
  `,
  styles: [`
    .sidebar{position:fixed;inset:0 auto 0 0;width:var(--sidebar-w);background:var(--surface);border-right:1px solid var(--border);
      display:flex;flex-direction:column;z-index:100;transition:transform .25s cubic-bezier(.2,.8,.2,1);}
    .marque{display:flex;align-items:center;gap:10px;padding:20px 20px 18px;text-decoration:none;color:var(--text-1);}
    .logo{width:36px;height:36px;border-radius:11px;background:linear-gradient(135deg,var(--primary),#13A86E);color:#fff;
      display:flex;align-items:center;justify-content:center;box-shadow:0 6px 14px -4px rgba(10,124,78,.55);}
    .nom{font-size:20px;font-weight:800;letter-spacing:-.02em;}
    .nom b{color:var(--gold);font-weight:800;}
    .tag{margin-left:auto;font-size:11px;font-weight:700;color:var(--primary);background:var(--primary-light);padding:3px 8px;border-radius:6px;}
    .nav{flex:1;overflow-y:auto;padding:4px 12px 12px;display:flex;flex-direction:column;gap:2px;}
    .section{font-size:11px;font-weight:700;color:var(--text-3);text-transform:uppercase;letter-spacing:.08em;padding:16px 12px 6px;}
    .item{position:relative;display:flex;align-items:center;gap:12px;height:40px;padding:0 12px;border-radius:10px;color:var(--text-2);
      text-decoration:none;font-size:14px;font-weight:500;transition:background .15s,color .15s;}
    .item:hover{background:var(--surface-2);color:var(--text-1);}
    .item.active{background:var(--primary-light);color:var(--primary);font-weight:700;}
    .item.active::before{content:'';position:absolute;left:-12px;top:9px;bottom:9px;width:3px;border-radius:0 3px 3px 0;background:var(--primary);}
    .pied{display:flex;align-items:center;gap:6px;padding:12px;border-top:1px solid var(--divider);}
    .compte{flex:1;display:flex;align-items:center;gap:10px;padding:8px;border-radius:12px;text-decoration:none;color:var(--text-1);min-width:0;}
    .compte:hover,.compte.active{background:var(--surface-2);}
    .qui{display:flex;flex-direction:column;min-width:0;}
    .qui .n{font-size:13px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .qui .r{font-size:12px;color:var(--text-2);}
    .voile{display:none;}
    @media (max-width:1024px){
      .sidebar{transform:translateX(-100%);box-shadow:var(--shadow-lg);}
      .sidebar.ouvert{transform:none;}
      .voile{display:block;position:fixed;inset:0;background:rgba(15,27,23,.35);z-index:99;animation:fadeIn .2s;}
    }
  `]
})
export class SidebarComponent {
  auth = inject(AuthService);
  ui = inject(UiService);

  sections = computed(() => {
    const role = this.auth.role() ?? '';
    return SECTIONS
      .map(s => ({ ...s, items: s.items.filter(i => !i.roles || i.roles.includes(role)) }))
      .filter(s => s.items.length > 0);
  });

  roleLabel(): string {
    return ({ admin: 'Administrateur', support: 'Support client', transporteur: 'Compagnie' } as Record<string, string>)[this.auth.role() ?? ''] ?? '';
  }
}
