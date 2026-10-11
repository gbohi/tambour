import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

export const connecteGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AuthService);
  return auth.connecte() ? true : inject(Router).createUrlTree(['/connexion'], { queryParams: { retour: state.url } });
};
