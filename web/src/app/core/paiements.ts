import { MethodePaiement } from './models';

export interface InfoMethode {
  code: MethodePaiement;
  label: string;
  court: string;
  detail: string;
  /** Logo officiel (assets/paiements) ; absent pour la carte bancaire. */
  logo?: string;
}

/** Moyens de paiement proposés, dans l'ordre d'affichage. */
export const METHODES_PAIEMENT: InfoMethode[] = [
  { code: 'orange_money', label: 'Orange Money', court: 'Orange Money', detail: 'Validation par code sur votre téléphone', logo: 'assets/paiements/orange_money.png' },
  { code: 'wave', label: 'Wave', court: 'Wave', detail: "Confirmez dans l'application Wave", logo: 'assets/paiements/wave.png' },
  { code: 'mtn_momo', label: 'MTN Mobile Money', court: 'MTN MoMo', detail: 'Validation par code sur votre téléphone', logo: 'assets/paiements/mtn_momo.png' },
  { code: 'moov_money', label: 'Moov Money', court: 'Moov Money', detail: 'Validation par code sur votre téléphone', logo: 'assets/paiements/moov_money.png' },
  { code: 'carte', label: 'Carte bancaire', court: 'Carte', detail: 'Visa, Mastercard — paiement sécurisé' },
];

export const MOBILE_MONEY = METHODES_PAIEMENT.filter(m => m.logo);
