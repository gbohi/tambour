export type StatutReclamation = 'ouverte' | 'en_cours' | 'resolue' | 'rejetee';
export type StatutMessage = 'nouveau' | 'en_cours' | 'traite';

export interface Reclamation {
  id: string;
  reference: string;
  categorie: string;
  categorie_label: string;
  sujet: string;
  description: string;
  reference_reservation: string;
  statut: StatutReclamation;
  statut_label: string;
  reponse: string;
  traitee_le: string | null;
  created_at: string;
  updated_at: string;
  user_nom: string;
  user_email: string;
  user_telephone: string;
}

export interface ReclamationsResponse {
  results: Reclamation[];
  stats: Record<StatutReclamation, number>;
}

export interface MessageSupport {
  id: string;
  nom: string;
  email: string;
  telephone: string;
  sujet: string;
  message: string;
  statut: StatutMessage;
  statut_label: string;
  reponse: string;
  created_at: string;
  user_email: string | null;
}

export interface MessagesResponse { results: MessageSupport[]; nb_nouveaux: number; }

export interface AvisApplication {
  id: string;
  note: number;
  commentaire: string;
  plateforme: string;
  version_app: string;
  user_nom: string;
  updated_at: string;
}

export interface AvisResponse {
  results: AvisApplication[];
  moyenne: number;
  total: number;
  repartition: Record<string, number>;
}
