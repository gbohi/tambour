export interface Passager {
  id: string;
  prenom: string;
  nom: string;
  telephone: string;
  email: string;            // facultatif
  siege_numero: string;
  ordre: number;
  billet?: Billet;          // billet individuel
}

export interface Billet {
  id: string;
  reference_billet: string; // ex: TB20260608001-P1
  numero: number;
  qr_data: string;
  est_valide: boolean;
  utilise_le?: string;
  created_at: string;
}

export interface Reservation {
  id: string;
  reference: string;
  trajet: string;
  trajet_info: {
    id: string; depart: string; arrivee: string;
    heure_depart: string; compagnie: string; prix_fcfa: number;
  };
  user?: string;
  user_info?: { nom_complet: string; email: string; telephone: string };
  statut: 'en_attente' | 'confirmee' | 'annulee' | 'expiree' | 'remboursee';
  montant_billets: number;   // prix des billets
  frais_service: number;     // frais de service (paramétrés dans l'admin)
  montant_total: number;     // TTC = billets + frais
  montant_rembourse: number;
  nb_passagers: number;
  email_payeur: string;
  peut_etre_annulee: boolean;
  montant_remboursable: number;
  passagers?: Passager[];
  notes: string;
  expire_at?: string;
  created_at: string;
  updated_at: string;
}

export interface Paiement {
  id: string; reference: string; methode: string; methode_label: string;
  montant: number; montant_rembourse: number; telephone: string;
  statut: 'initie' | 'en_attente' | 'succes' | 'echec' | 'rembourse' | 'annule';
  statut_label: string; reference_operateur: string;
  url_paiement: string; message_erreur: string;
  created_at: string; confirme_le?: string;
}

export interface Versement {
  id: string; transporteur: string; transporteur_nom: string;
  periode_debut: string; periode_fin: string;
  montant_brut: number; montant_commission: number; montant_net: number;
  statut: 'en_attente' | 'traite' | 'annule';
  traite_le?: string; created_at: string;
}

export interface NotifResponse {
  results: Notif[]; count: number; nb_non_lues: number;
}

export interface Notif {
  id: string; type_notif: string; type_label: string; canal: string;
  titre: string; message: string; lue: boolean;
  lue_le?: string; created_at: string;
}
