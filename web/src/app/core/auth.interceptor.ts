import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthService } from './auth.service';

/** Ajoute le jeton JWT et le renouvelle une fois en cas d'expiration (401). */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const avecJeton = (jeton: string | null) => jeton ? req.clone({ setHeaders: { Authorization: `Bearer ${jeton}` } }) : req;
  const estAuth = req.url.includes('/auth/token');
  return next(avecJeton(estAuth ? null : auth.jeton)).pipe(
    catchError((e: HttpErrorResponse) => {
      if (e.status !== 401 || estAuth || !auth.jetonRafraichissement) return throwError(() => e);
      return auth.rafraichirJeton().pipe(
        switchMap(jeton => next(avecJeton(jeton))),
        catchError(err => { auth.deconnexion(); return throwError(() => err); }),
      );
    }),
  );
};
