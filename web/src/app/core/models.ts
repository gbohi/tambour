export interface ApiResponse<T> { success: boolean; message: string; data: T; errors?: Record<string, unknown>; }
export interface Page<T> { count: number; next: string | null; previous: string | null; results: T[]; }

export interface Ville { id: string; nom: string; region: string; code_iata?: string; }

export interface Trajet {
  id: string;
  depart: Ville; arrivee: Ville;
  gare_depart: { id: string; nom: string } | null;
  depart_nom: string; arrivee_nom: string;
  heure_depart: string; heure_arrivee_estimee: string;
  prix_fcfa: number; prix_promo_fcfa: number | null; prix_actuel: number; est_en_promo: boolean;
  duree_label: string; compagnie: string; bus_immatriculation: string; bus_classe: 'standard' | 'confort' | 'vip';
  amenities: string[]; statut: string; retard_minutes: number;
  note_moyenne: string; nombre_avis: number; places_disponibles: number; places_total: number;
}

export interface LignePopulaire {
  id: string; depart: string; depart_id: string; arrivee: string; arrivee_id: string;
  duree_label: string | null; prix_min: number | null; trajets_par_jour: number; est_populaire: boolean; distance_km: number | null;
}

export interface Gare {
  id: string; nom: string; ville: string; ville_nom: string; adresse: string; latitude: string; longitude: string;
  telephone: string; heures_ouverture: string; est_principale: boolean; compagnies: string[]; lignes: string[];
}

export interface User {
  id: string; prenom: string; nom: string; nom_complet: string; initiales: string; email: string; telephone: string;
  role: string; is_verified: boolean; points_fidelite: number; nb_voyages: number; code_parrainage: string;
  notif_sms: boolean; notif_email: boolean; date_inscription: string;
}

export interface Billet { id: string; reference_billet: string; numero: number; qr_data: string; est_valide: boolean; utilise_le: string | null; }
export interface Passager { id: string; prenom: string; nom: string; telephone: string; email: string; siege_numero: string; ordre: number; billet?: Billet; }

export interface Reservation {
  id: string; reference: string; trajet: string;
  trajet_info: { id: string; depart: string; arrivee: string; heure_depart: string; heure_arrivee_estimee: string; compagnie: string; prix_fcfa: number; statut: string; };
  statut: 'en_attente' | 'confirmee' | 'annulee' | 'expiree' | 'remboursee';
  montant_total: number; montant_rembourse: number; nb_passagers: number; email_payeur: string;
  peut_etre_annulee: boolean; montant_remboursable: number; peut_etre_notee: boolean; avis_note: number | null;
  passagers: Passager[]; expire_at: string | null; created_at: string;
}

export interface MouvementPoints { id: string; points: number; motif: string; motif_label: string; description: string; created_at: string; }
export interface Fidelite {
  points: number; nb_voyages: number; code_parrainage: string; nb_filleuls: number; points_parrainage: number;
  points_parrain: number; points_filleul: number; lien_telechargement: string; message_partage: string; historique: MouvementPoints[];
}

export interface QuestionFAQ { id: number; categorie: string; question: string; reponse: string; }
export interface CategorieFAQ { code: string; label: string; questions: QuestionFAQ[]; }
export interface InfosContact { telephone: string; whatsapp: string; email: string; horaires: string; }

export interface PassagerSaisie { prenom: string; nom: string; telephone: string; email: string; }
export type MethodePaiement = 'orange_money' | 'mtn_momo' | 'moov_money' | 'wave' | 'carte';
