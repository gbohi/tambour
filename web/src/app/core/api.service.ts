import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  ApiResponse, Page, Ville, Trajet, Suivi, LignePopulaire, Gare, Reservation, Fidelite, CategorieFAQ,
  InfosContact, PassagerSaisie, MethodePaiement, User, Devis, Banniere,
} from './models';

/** Accès à l'API TamBour (toutes les réponses sont enveloppées dans { success, data }). */
@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private readonly api = environment.apiUrl;

  private get<T>(chemin: string, params?: Record<string, string | number | boolean | undefined>): Observable<T> {
    let p = new HttpParams();
    Object.entries(params ?? {}).forEach(([k, v]) => { if (v !== undefined && v !== '') p = p.set(k, String(v)); });
    return this.http.get<ApiResponse<T>>(`${this.api}${chemin}`, { params: p }).pipe(map(r => r.data));
  }
  private post<T>(chemin: string, corps: unknown): Observable<ApiResponse<T>> {
    return this.http.post<ApiResponse<T>>(`${this.api}${chemin}`, corps);
  }

  // ── Catalogue ──────────────────────────────────────────────────────────────
  villes(): Observable<Ville[]> { return this.get<Page<Ville>>('/villes/', { page_size: 200 }).pipe(map(p => p.results)); }
  lignesPopulaires(): Observable<LignePopulaire[]> { return this.get<{ results: LignePopulaire[] }>('/lignes/populaires/').pipe(map(r => r.results)); }
  gares(): Observable<Gare[]> { return this.get<Page<Gare>>('/gares/', { page_size: 200 }).pipe(map(p => p.results)); }
  departsGare(id: string): Observable<Trajet[]> { return this.get<{ results: Trajet[] }>(`/gares/${id}/departs/`).pipe(map(r => r.results)); }
  trajet(id: string): Observable<Trajet> { return this.get<Trajet>(`/trajets/${id}/`); }
  devis(trajetId: string, passagers: number): Observable<Devis> { return this.get<Devis>('/reservations/devis/', { trajet_id: trajetId, passagers }); }
  bannieres(): Observable<Banniere[]> { return this.get<{ results: Banniere[] }>('/bannieres/').pipe(map(r => r.results)); }
  rechercher(c: { depart: string; arrivee: string; date: string; passagers: number; tri?: string; classe?: string }): Observable<Trajet[]> {
    return this.post<{ results: Trajet[] }>('/trajets/recherche/', c).pipe(map(r => r.data.results));
  }

  // ── Réservation & paiement ─────────────────────────────────────────────────
  reserver(trajetId: string, passagers: PassagerSaisie[], emailPayeur: string): Observable<Reservation> {
    return this.post<Reservation>('/reservations/', { trajet_id: trajetId, passagers, email_payeur: emailPayeur }).pipe(map(r => r.data));
  }
  payer(reservationId: string, methode: MethodePaiement, telephone: string): Observable<{ simulation?: boolean; url_paiement: string; message: string }> {
    return this.post<{ simulation?: boolean; url_paiement: string; message: string }>('/paiements/initier/',
      { reservation_id: reservationId, methode, telephone }).pipe(map(r => r.data));
  }
  mesReservations(): Observable<Reservation[]> { return this.get<Reservation[]>('/reservations/'); }
  reservation(id: string): Observable<Reservation> { return this.get<Reservation>(`/reservations/${id}/`); }
  suivi(trajetId: string): Observable<Suivi> { return this.get<Suivi>(`/trajets/${trajetId}/suivi/`); }
  annulerReservation(id: string, motif: string): Observable<ApiResponse<unknown>> { return this.post(`/reservations/${id}/annuler/`, { motif }); }
  noterTrajet(reservationId: string, note: number, commentaire: string, criteres: Record<string, number>): Observable<ApiResponse<unknown>> {
    return this.post('/avis/', { reservation_id: reservationId, note, commentaire, ...criteres });
  }

  // ── Compte ─────────────────────────────────────────────────────────────────
  fidelite(): Observable<Fidelite> { return this.get<Fidelite>('/auth/fidelite/'); }
  verifierParrain(code: string): Observable<{ parrain_prenom: string; points_filleul: number }> {
    return this.get('/auth/parrainage/verifier/', { code });
  }
  majProfil(data: Partial<User>): Observable<User> {
    return this.http.patch<ApiResponse<User>>(`${this.api}/auth/me/`, data).pipe(map(r => r.data));
  }

  // ── Aide ───────────────────────────────────────────────────────────────────
  faq(): Observable<CategorieFAQ[]> { return this.get<{ categories: CategorieFAQ[] }>('/support/faq/').pipe(map(r => r.categories)); }
  contact(): Observable<InfosContact> { return this.get<InfosContact>('/support/contact/'); }
  envoyerMessage(m: { nom?: string; email?: string; telephone?: string; sujet: string; message: string }): Observable<ApiResponse<unknown>> {
    return this.post('/support/contact/', m);
  }
  reclamer(r: { categorie: string; sujet: string; description: string; reference_reservation: string }): Observable<ApiResponse<unknown>> {
    return this.post('/support/reclamations/', r);
  }
}

/** Premier message d'erreur lisible renvoyé par l'API. */
export function messageErreur(e: unknown, defaut = 'Une erreur est survenue. Réessayez.'): string {
  const err = (e as { error?: { message?: string; errors?: Record<string, unknown> } })?.error;
  const errors = err?.errors;
  if (errors && typeof errors === 'object') {
    for (const v of Object.values(errors)) {
      if (Array.isArray(v) && typeof v[0] === 'string') return v[0];
      if (v && typeof v === 'object') for (const w of Object.values(v as object)) if (Array.isArray(w) && typeof w[0] === 'string') return w[0];
    }
  }
  return err?.message && err.message !== 'Donnees invalides.' ? err.message : defaut;
}
