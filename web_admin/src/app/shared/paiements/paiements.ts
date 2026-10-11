/** Moyens de paiement : libellés, couleur du graphique et logo officiel (assets/paiements). */
export interface InfoMethode { code: string; label: string; court: string; couleur: string; logo?: string; }

export const METHODES_PAIEMENT: InfoMethode[] = [
  { code: 'orange_money', label: 'Orange Money', court: 'Orange', couleur: '#FF7900', logo: 'assets/paiements/orange_money.png' },
  { code: 'wave', label: 'Wave', court: 'Wave', couleur: '#1DC8F2', logo: 'assets/paiements/wave.png' },
  { code: 'mtn_momo', label: 'MTN MoMo', court: 'MTN', couleur: '#FFCB05', logo: 'assets/paiements/mtn_momo.png' },
  // Bleu Moov pour ne pas confondre avec l'orange d'Orange Money dans les graphiques
  { code: 'moov_money', label: 'Moov Money', court: 'Moov', couleur: '#0066B3', logo: 'assets/paiements/moov_money.png' },
  { code: 'carte', label: 'Carte bancaire', court: 'Carte', couleur: '#64748B' },
];

export function infoMethode(code: string): InfoMethode {
  return METHODES_PAIEMENT.find(m => m.code === code) ?? { code, label: code, court: code, couleur: '#0F4A3B' };
}
