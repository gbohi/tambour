export type UserRole = 'admin' | 'support' | 'transporteur' | 'voyageur' | 'chauffeur';

export interface User {
  id: string;
  prenom: string;
  nom: string;
  nom_complet: string;
  initiales: string;
  email: string;
  telephone: string;
  avatar_url?: string;
  role: UserRole;
  is_verified: boolean;
  is_active?: boolean;
  points_fidelite: number;
  code_parrainage?: string;
  nb_voyages: number;
  notif_sms: boolean;
  notif_push: boolean;
  notif_email: boolean;
  notif_promotions: boolean;
  date_inscription: string;
  updated_at: string;
}

export interface AuthTokens { access: string; refresh: string; user: User; }
export interface LoginRequest { email: string; password: string; }
