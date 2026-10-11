import { Routes } from '@angular/router';
import { authGuard }   from './core/guards/auth.guard';
import { roleGuard }   from './core/guards/role.guard';
import { noAuthGuard } from './core/guards/no-auth.guard';

export const routes: Routes = [
  { path: 'auth', canActivate: [noAuthGuard], children: [
    { path: 'login', loadComponent: () => import('./features/auth/login/login.component').then(m => m.LoginComponent) }
  ]},
  { path: '', canActivate: [authGuard],
    loadComponent: () => import('./layout/layout.component').then(m => m.LayoutComponent),
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard',     canActivate: [roleGuard], data: { roles: ['admin','support'] },
        loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent) },
      { path: 'voyageurs',     canActivate: [roleGuard], data: { roles: ['admin','support'] },
        loadComponent: () => import('./features/voyageurs/voyageurs.component').then(m => m.VoyageursComponent) },
      { path: 'transporteurs', canActivate: [roleGuard], data: { roles: ['admin'] },
        loadComponent: () => import('./features/transporteurs/transporteurs.component').then(m => m.TransporteursComponent) },
      { path: 'trajets',       canActivate: [roleGuard], data: { roles: ['admin','support','transporteur'] },
        loadComponent: () => import('./features/trajets/trajets.component').then(m => m.TrajetsComponent) },
      { path: 'reservations',  canActivate: [roleGuard], data: { roles: ['admin','support','transporteur'] },
        loadComponent: () => import('./features/reservations/reservations.component').then(m => m.ReservationsComponent) },
      { path: 'paiements',     canActivate: [roleGuard], data: { roles: ['admin'] },
        loadComponent: () => import('./features/paiements/paiements.component').then(m => m.PaiementsComponent) },
      { path: 'notifications', canActivate: [roleGuard], data: { roles: ['admin','support'] },
        loadComponent: () => import('./features/notifications/notifications.component').then(m => m.NotificationsComponent) },
      { path: 'chauffeurs',    canActivate: [roleGuard], data: { roles: ['admin','support'] },
        loadComponent: () => import('./features/chauffeurs/chauffeurs.component').then(m => m.ChauffeursComponent) },
      { path: 'support',       canActivate: [roleGuard], data: { roles: ['admin','support'] },
        loadComponent: () => import('./features/support/support.component').then(m => m.SupportComponent) },
      { path: 'gares',         canActivate: [roleGuard], data: { roles: ['admin'] },
        loadComponent: () => import('./features/gares/gares.component').then(m => m.GaresComponent) },
      { path: 'rapports',      canActivate: [roleGuard], data: { roles: ['admin'] },
        loadComponent: () => import('./features/rapports/rapports.component').then(m => m.RapportsComponent) },
      { path: 'profil', loadComponent: () => import('./features/profil/profil.component').then(m => m.ProfilComponent) },
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
