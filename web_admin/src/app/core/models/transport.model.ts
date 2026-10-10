export interface Ville {
  id: string; nom: string; region: string; code_iata: string;
  latitude?: number; longitude?: number; est_active: boolean; ordre_affichage: number;
}

export interface Gare {
  id: string; nom: string; ville: string; ville_nom: string;
  adresse: string; latitude: number; longitude: number;
  telephone: string; heures_ouverture: string;
  est_principale: boolean; est_active: boolean;
  compagnies: string[]; lignes: string[];
}

export interface Transporteur {
  id: string; nom: string; email: string; telephone: string;
  adresse: string; rccm: string; taux_commission: string;
  note_moyenne: string; nombre_avis: number;
  est_actif: boolean; est_verifie: boolean; created_at: string;
}

export interface Trajet {
  id: string; ligne: string; depart_nom: string; arrivee_nom: string;
  depart_region: string; arrivee_region: string;
  heure_depart: string; heure_arrivee_estimee: string;
  prix_fcfa: number; prix_promo_fcfa?: number;
  prix_actuel: number; est_en_promo: boolean; duree_label: string;
  compagnie: string; bus_immatriculation: string; bus_classe: string;
  amenities: string[];
  statut: 'planifie' | 'en_cours' | 'termine' | 'annule' | 'retarde';
  retard_minutes: number; note_moyenne: string; nombre_avis: number;
  places_disponibles: number; places_total: number;
}

export interface DashboardStats {
  // KPI principaux
  reservations_today: number;
  reservations_week: number;
  chiffre_affaires_mois: number;
  total_voyageurs: number;
  nouveaux_voyageurs_semaine: number;
  trajets_today: number;
  trajets_planifies: number;
  paiements_en_attente: number;
  taux_remplissage_moyen: number;
  // Deltas optionnels (calculés côté backend)
  delta_reservations_hier?: number;
  delta_ca_mois_precedent?: number;
  // Graphiques
  reservations_par_jour: number[];
  top_lignes: Array<{ ligne: string; count: number }>;
  methodes_paiement: Array<{ methode: string; montant: number }>;
}
