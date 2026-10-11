import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, tap } from 'rxjs';
import { environment } from '../../environments/environment';
import { ApiResponse, User } from './models';

const CLE_ACCES = 'tb_access', CLE_RAFRAICHIR = 'tb_refresh', CLE_USER = 'tb_user';

function lire(cle: string): string | null { try { return localStorage.getItem(cle); } catch { return null; } }
function ecrire(cle: string, v: string | null): void { try { v === null ? localStorage.removeItem(cle) : localStorage.setItem(cle, v); } catch { /* stockage indisponible */ } }

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private readonly api = environment.apiUrl;
  private _user = signal<User | null>((() => { try { return JSON.parse(lire(CLE_USER) ?? 'null'); } catch { return null; } })());
  readonly user = this._user.asReadonly();
  readonly connecte = computed(() => this._user() !== null);

  get jeton(): string | null { return lire(CLE_ACCES); }
  get jetonRafraichissement(): string | null { return lire(CLE_RAFRAICHIR); }

  connexion(email: string, password: string): Observable<User> {
    return this.http.post<ApiResponse<{ access: string; refresh: string; user: User }>>(`${this.api}/auth/token/`, { email, password })
      .pipe(map(r => r.data), tap(d => this.ouvrirSession(d.access, d.refresh, d.user)), map(d => d.user));
  }

  inscription(d: { prenom: string; nom: string; email: string; telephone: string; password: string; code_parrainage?: string }): Observable<User> {
    return this.http.post<ApiResponse<{ access: string; refresh: string; user: User }>>(`${this.api}/auth/register/`,
      { ...d, password_confirm: d.password })
      .pipe(map(r => r.data), tap(x => this.ouvrirSession(x.access, x.refresh, x.user)), map(x => x.user));
  }

  rafraichirProfil(): void {
    if (!this.jeton) return;
    this.http.get<ApiResponse<User>>(`${this.api}/auth/me/`).subscribe({ next: r => this.majUser(r.data), error: () => {} });
  }

  rafraichirJeton(): Observable<string> {
    return this.http.post<{ access: string; refresh?: string }>(`${this.api}/auth/token/refresh/`, { refresh: this.jetonRafraichissement })
      .pipe(tap(r => { ecrire(CLE_ACCES, r.access); if (r.refresh) ecrire(CLE_RAFRAICHIR, r.refresh); }), map(r => r.access));
  }

  majUser(u: User): void { this._user.set(u); ecrire(CLE_USER, JSON.stringify(u)); }

  deconnexion(): void {
    ecrire(CLE_ACCES, null); ecrire(CLE_RAFRAICHIR, null); ecrire(CLE_USER, null);
    this._user.set(null);
  }

  private ouvrirSession(access: string, refresh: string, user: User): void {
    ecrire(CLE_ACCES, access); ecrire(CLE_RAFRAICHIR, refresh); this.majUser(user);
  }
}
