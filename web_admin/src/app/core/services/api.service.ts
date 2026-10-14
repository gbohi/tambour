import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { ApiResponse, PaginatedResponse, PageParams } from '../models/api.model';
import { User } from '../models/user.model';
import { Ville, Gare, Transporteur, Trajet, DashboardStats } from '../models/transport.model';
import { Banniere, ParametresPlateforme } from '../models/plateforme.model';
import { Reservation, Paiement, NotifResponse, Versement } from '../models/reservation.model';
import {
  Reclamation, ReclamationsResponse, MessageSupport, MessagesResponse, AvisResponse,
} from '../models/support.model';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly API = environment.apiUrl;
  constructor(private http: HttpClient) {}

  private toParams(p?: PageParams): Record<string, string> {
    const out: Record<string, string> = {};
    if (p) Object.entries(p).forEach(([k, v]) => { if (v !== undefined && v !== '') out[k] = String(v); });
    return out;
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  getDashboardStats(): Observable<ApiResponse<DashboardStats>> {
    return this.http.get<ApiResponse<DashboardStats>>(`${this.API}/dashboard/stats/`);
  }

  // ── Utilisateurs ───────────────────────────────────────────────────────────
  getUtilisateurs(p?: PageParams): Observable<ApiResponse<PaginatedResponse<User>>> {
    return this.http.get<ApiResponse<PaginatedResponse<User>>>(`${this.API}/auth/users/`, { params: this.toParams(p) });
  }
  toggleUserActif(id: string, actif: boolean): Observable<ApiResponse<User>> {
    return this.http.patch<ApiResponse<User>>(`${this.API}/auth/users/${id}/`, { is_active: actif });
  }

  // ── Transporteurs ──────────────────────────────────────────────────────────
  getTransporteurs(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Transporteur>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Transporteur>>>(`${this.API}/transporteurs/`, { params: this.toParams(p) });
  }
  verifierTransporteur(id: string, verifie: boolean): Observable<ApiResponse<Transporteur>> {
    return this.http.patch<ApiResponse<Transporteur>>(`${this.API}/transporteurs/${id}/`, { est_verifie: verifie });
  }
  toggleTransporteurActif(id: string, actif: boolean): Observable<ApiResponse<Transporteur>> {
    return this.http.patch<ApiResponse<Transporteur>>(`${this.API}/transporteurs/${id}/`, { est_actif: actif });
  }

  // ── Villes & Gares ─────────────────────────────────────────────────────────
  getVilles(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Ville>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Ville>>>(`${this.API}/villes/`, { params: this.toParams(p) });
  }
  getGares(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Gare>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Gare>>>(`${this.API}/gares/`, { params: this.toParams(p) });
  }
  createGare(data: Partial<Gare>): Observable<ApiResponse<Gare>> {
    return this.http.post<ApiResponse<Gare>>(`${this.API}/gares/`, data);
  }
  updateGare(id: string, data: Partial<Gare>): Observable<ApiResponse<Gare>> {
    return this.http.patch<ApiResponse<Gare>>(`${this.API}/gares/${id}/`, data);
  }

  // ── Trajets ────────────────────────────────────────────────────────────────
  getTrajets(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Trajet>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Trajet>>>(`${this.API}/trajets/`, { params: this.toParams(p) });
  }
  getTrajet(id: string): Observable<ApiResponse<Trajet>> {
    return this.http.get<ApiResponse<Trajet>>(`${this.API}/trajets/${id}/`);
  }
  annulerTrajet(id: string, motif: string): Observable<ApiResponse<Trajet>> {
    return this.http.patch<ApiResponse<Trajet>>(`${this.API}/trajets/${id}/`, { statut: 'annule', motif_annulation: motif });
  }
  signalerRetard(id: string, minutes: number): Observable<ApiResponse<Trajet>> {
    return this.http.patch<ApiResponse<Trajet>>(`${this.API}/trajets/${id}/`, { retard_minutes: minutes, statut: 'retarde' });
  }

  // ── Réservations ───────────────────────────────────────────────────────────
  getReservations(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Reservation>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Reservation>>>(`${this.API}/reservations/`, { params: this.toParams(p) });
  }
  getReservation(id: string): Observable<ApiResponse<Reservation>> {
    return this.http.get<ApiResponse<Reservation>>(`${this.API}/reservations/${id}/`);
  }
  validerQr(id: string, passagerId: string): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(
      `${this.API}/reservations/${id}/valider-qr/`, { passager_id: passagerId });
  }

  // Récupérer tous les billets d'une réservation
  getBilletsReservation(id: string): Observable<ApiResponse<unknown>> {
    return this.http.get<ApiResponse<unknown>>(`${this.API}/reservations/${id}/billets/`);
  }
  annulerReservation(id: string, motif: string): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${this.API}/reservations/${id}/annuler/`, { motif });
  }

  // ── Paiements ──────────────────────────────────────────────────────────────
  getPaiements(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Paiement>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Paiement>>>(`${this.API}/paiements/`, { params: this.toParams(p) });
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  getNotifications(p?: PageParams): Observable<ApiResponse<NotifResponse>> {
    return this.http.get<ApiResponse<NotifResponse>>(`${this.API}/notifications/`, { params: this.toParams(p) });
  }
  marquerNotifLues(ids?: string[]): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${this.API}/notifications/lire/`, ids ? { notification_ids: ids } : {});
  }
  envoyerNotifBulk(data: { titre: string; message: string; type_notif: string; cibles: string[] }): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${this.API}/notifications/bulk/`, data);
  }

  // ── Rapports & Exports ─────────────────────────────────────────────────────
  getVersements(p?: PageParams): Observable<ApiResponse<PaginatedResponse<Versement>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Versement>>>(`${this.API}/paiements/versements/`, { params: this.toParams(p) });
  }

  // Export CSV depuis le backend — retourne un Blob
  exportCsv(type: string, dateDebut: string, dateFin: string): Observable<Blob> {
    return this.http.get(`${this.API}/rapports/export/`, {
      params: { type, date_debut: dateDebut, date_fin: dateFin },
      responseType: 'blob'
    });
  }

  // ── Support client ─────────────────────────────────────────────────────────
  getReclamations(p?: PageParams): Observable<ApiResponse<ReclamationsResponse>> {
    return this.http.get<ApiResponse<ReclamationsResponse>>(`${this.API}/support/reclamations/`, { params: this.toParams(p) });
  }
  updateReclamation(id: string, data: Partial<Reclamation>): Observable<ApiResponse<Reclamation>> {
    return this.http.patch<ApiResponse<Reclamation>>(`${this.API}/support/reclamations/${id}/`, data);
  }
  getMessagesSupport(p?: PageParams): Observable<ApiResponse<MessagesResponse>> {
    return this.http.get<ApiResponse<MessagesResponse>>(`${this.API}/support/messages/`, { params: this.toParams(p) });
  }
  updateMessageSupport(id: string, data: Partial<MessageSupport>): Observable<ApiResponse<MessageSupport>> {
    return this.http.patch<ApiResponse<MessageSupport>>(`${this.API}/support/messages/${id}/`, data);
  }
  getAvisApplication(): Observable<ApiResponse<AvisResponse>> {
    return this.http.get<ApiResponse<AvisResponse>>(`${this.API}/support/avis-app/`);
  }

  // ── Chauffeurs & comptes ───────────────────────────────────────────────────
  creerUtilisateur(data: { email: string; prenom: string; nom: string; telephone?: string; password: string; role: string }): Observable<ApiResponse<User>> {
    return this.http.post<ApiResponse<User>>(`${this.API}/auth/users/`, data);
  }
  affecterChauffeur(trajetId: string, chauffeurId: string | null): Observable<ApiResponse<Trajet>> {
    return this.http.patch<ApiResponse<Trajet>>(`${this.API}/trajets/${trajetId}/`, { chauffeur: chauffeurId });
  }

  // ── Plateforme : frais de service et bannières d'accueil ──────────────────
  getParametres(): Observable<ApiResponse<ParametresPlateforme>> {
    return this.http.get<ApiResponse<ParametresPlateforme>>(`${this.API}/admin/parametres/`);
  }
  updateParametres(data: Partial<ParametresPlateforme>): Observable<ApiResponse<ParametresPlateforme>> {
    return this.http.patch<ApiResponse<ParametresPlateforme>>(`${this.API}/admin/parametres/`, data);
  }
  getBannieres(): Observable<ApiResponse<PaginatedResponse<Banniere>>> {
    return this.http.get<ApiResponse<PaginatedResponse<Banniere>>>(`${this.API}/admin/bannieres/`, { params: { page_size: '100' } });
  }
  /** Envoi en multipart pour pouvoir joindre l'image. */
  enregistrerBanniere(id: number | null, data: FormData): Observable<ApiResponse<Banniere>> {
    return id
      ? this.http.patch<ApiResponse<Banniere>>(`${this.API}/admin/bannieres/${id}/`, data)
      : this.http.post<ApiResponse<Banniere>>(`${this.API}/admin/bannieres/`, data);
  }
  updateBanniere(id: number, data: Partial<Banniere>): Observable<ApiResponse<Banniere>> {
    return this.http.patch<ApiResponse<Banniere>>(`${this.API}/admin/bannieres/${id}/`, data);
  }
  deleteBanniere(id: number): Observable<unknown> {
    return this.http.delete(`${this.API}/admin/bannieres/${id}/`);
  }
}
