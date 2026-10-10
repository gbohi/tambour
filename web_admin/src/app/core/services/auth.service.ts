import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { environment } from '@env/environment';
import { User, UserRole, LoginRequest, AuthTokens } from '../models/user.model';
import { ApiResponse } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly API = environment.apiUrl;
  private readonly ACCESS_KEY  = 'tambour_access';
  private readonly REFRESH_KEY = 'tambour_refresh';
  private readonly USER_KEY    = 'tambour_user';

  private _user    = signal<User | null>(this.loadUser());
  private _loading = signal(false);

  readonly user             = this._user.asReadonly();
  readonly loading          = this._loading.asReadonly();
  readonly isAuthenticated  = computed(() => !!this._user());
  readonly isAdmin          = computed(() => this._user()?.role === 'admin');
  readonly isAdminOrSupport = computed(() => ['admin','support'].includes(this._user()?.role ?? ''));
  readonly isTransporteur   = computed(() => this._user()?.role === 'transporteur');
  readonly role             = computed(() => this._user()?.role ?? null);

  constructor(private http: HttpClient, private router: Router) {}

  login(creds: LoginRequest): Observable<ApiResponse<AuthTokens>> {
    this._loading.set(true);
    return this.http.post<ApiResponse<AuthTokens>>(`${this.API}/auth/token/`, creds).pipe(
      tap(res => { this.save(res.data.access, res.data.refresh, res.data.user); this._loading.set(false); }),
      catchError(err => { this._loading.set(false); return throwError(() => err); })
    );
  }

  logout(): void {
    const refresh = localStorage.getItem(this.REFRESH_KEY);
    if (refresh) this.http.post(`${this.API}/auth/logout/`, { refresh }).subscribe();
    localStorage.removeItem(this.ACCESS_KEY);
    localStorage.removeItem(this.REFRESH_KEY);
    localStorage.removeItem(this.USER_KEY);
    this._user.set(null);
    this.router.navigate(['/auth/login']);
  }

  refreshToken(): Observable<{ access: string }> {
    const refresh = localStorage.getItem(this.REFRESH_KEY) ?? '';
    return this.http.post<{ access: string }>(`${this.API}/auth/token/refresh/`, { refresh }).pipe(
      tap(res => localStorage.setItem(this.ACCESS_KEY, res.access))
    );
  }

  getProfile(): Observable<ApiResponse<User>> {
    return this.http.get<ApiResponse<User>>(`${this.API}/auth/me/`).pipe(
      tap(res => { this._user.set(res.data); this.saveUser(res.data); })
    );
  }

  updateProfile(data: Partial<User>): Observable<ApiResponse<User>> {
    return this.http.patch<ApiResponse<User>>(`${this.API}/auth/me/`, data).pipe(
      tap(res => { this._user.set(res.data); this.saveUser(res.data); })
    );
  }

  changePassword(data: { mot_de_passe_actuel: string; nouveau_mot_de_passe: string; confirmation: string }): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${this.API}/auth/change-password/`, data);
  }

  hasRole(...roles: UserRole[]): boolean {
    const r = this._user()?.role;
    return r ? roles.includes(r) : false;
  }

  getAccessToken(): string | null { return localStorage.getItem(this.ACCESS_KEY); }

  private save(access: string, refresh: string, user: User): void {
    localStorage.setItem(this.ACCESS_KEY, access);
    localStorage.setItem(this.REFRESH_KEY, refresh);
    this.saveUser(user);
    this._user.set(user);
  }
  private saveUser(user: User): void { localStorage.setItem(this.USER_KEY, JSON.stringify(user)); }
  private loadUser(): User | null {
    try { return JSON.parse(localStorage.getItem(this.USER_KEY) ?? 'null'); }
    catch { return null; }
  }
}
