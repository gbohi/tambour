import { Routes } from '@angular/router';
import { connecteGuard } from './core/auth.guard';

export const routes: Routes = [
  { path: '', loadComponent: () => import('./pages/accueil/accueil.component').then(m => m.AccueilComponent), title: "TamBour — Billets de car en Côte d'Ivoire" },
  { path: 'recherche', loadComponent: () => import('./pages/recherche/recherche.component').then(m => m.RechercheComponent), title: 'Résultats — TamBour' },
  { path: 'reservation/:trajetId', loadComponent: () => import('./pages/reservation/reservation.component').then(m => m.ReservationComponent), title: 'Réservation — TamBour' },
  { path: 'billets/:id', canActivate: [connecteGuard], loadComponent: () => import('./pages/confirmation/confirmation.component').then(m => m.ConfirmationComponent), title: 'Vos billets — TamBour' },
  { path: 'connexion', loadComponent: () => import('./pages/connexion/connexion.component').then(m => m.ConnexionComponent), title: 'Connexion — TamBour' },
  { path: 'compte', canActivate: [connecteGuard], loadComponent: () => import('./pages/compte/compte.component').then(m => m.CompteComponent), title: 'Mon compte — TamBour' },
  { path: 'gares', loadComponent: () => import('./pages/gares/gares.component').then(m => m.GaresComponent), title: 'Gares — TamBour' },
  { path: 'destinations', loadComponent: () => import('./pages/destinations/destinations.component').then(m => m.DestinationsComponent), title: 'Destinations — TamBour' },
  { path: 'aide', loadComponent: () => import('./pages/aide/aide.component').then(m => m.AideComponent), title: "Centre d'aide — TamBour" },
  { path: '**', redirectTo: '' },
];
