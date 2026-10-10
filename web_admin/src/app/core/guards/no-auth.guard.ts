import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const noAuthGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  if (!auth.isAuthenticated()) return true;
  const role = auth.role();
  return inject(Router).createUrlTree(role === 'transporteur' ? ['/trajets'] : ['/dashboard']);
};
