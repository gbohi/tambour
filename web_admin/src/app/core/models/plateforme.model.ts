/** Frais de service et réglages de la plateforme (singleton côté serveur). */
export type ModeFrais = 'par_reservation' | 'par_passager' | 'pourcentage';
export interface ParametresPlateforme {
  frais_service_mode: ModeFrais;
  frais_service_valeur: number;
  frais_service_minimum: number;
  frais_remboursables: boolean;
  libelle_frais?: string;
  updated_at?: string;
}

export type ActionBanniere = 'aucune' | 'recherche' | 'page' | 'lien';
export type PageBanniere = '' | 'fidelite' | 'gares' | 'lignes' | 'aide';

/** Visuel du carrousel d'accueil (application et site). */
export interface Banniere {
  id: number;
  titre: string; sous_titre: string;
  image_url: string | null;
  couleur_fond: string; texte_bouton: string;
  action: ActionBanniere;
  depart: string | null; depart_nom?: string;
  arrivee: string | null; arrivee_nom?: string;
  page: PageBanniere; lien: string;
  ordre: number; est_active: boolean;
  debut: string | null; fin: string | null;
  created_at?: string;
}
