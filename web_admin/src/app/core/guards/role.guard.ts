import { inject } from '@angular/core';
import { CanActivateFn, ActivatedRouteSnapshot, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { UserRole } from '../models/user.model';

export const roleGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const auth  = inject(AuthService);
  const router = inject(Router);
  if (!auth.isAuthenticated()) return router.createUrlTree(['/auth/login']);
  const roles: UserRole[] = route.data['roles'] ?? [];
  if (roles.length === 0) return true;
  const r = auth.role();
  if (r && roles.includes(r)) return true;
  return router.createUrlTree(auth.isTransporteur() ? ['/trajets'] : ['/dashboard']);
};
