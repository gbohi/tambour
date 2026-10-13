import { Reservation } from './models';

/** Suivi en direct proposé quand le car roule, ou dans les 3 heures qui précèdent le départ. */
export function suiviDisponible(r: Reservation, maintenant = Date.now()): boolean {
  if (r.statut !== 'confirmee' || !r.trajet_info?.id) return false;
  if (r.trajet_info.statut === 'en_cours') return true;
  if (['termine', 'annule'].includes(r.trajet_info.statut)) return false;
  const depart = new Date(r.trajet_info.heure_depart).getTime();
  return depart - maintenant < 3 * 3600_000 && depart - maintenant > -12 * 3600_000;
}

/** « 1 h 25 », « 45 min », « 2 j 3 h » */
export function duree(minutes: number): string {
  if (minutes < 1) return "moins d'1 min";
  if (minutes < 60) return `${minutes} min`;
  const j = Math.floor(minutes / 1440), h = Math.floor((minutes % 1440) / 60), m = minutes % 60;
  if (j > 0) return h ? `${j} j ${h} h` : `${j} j`;
  return m ? `${h} h ${String(m).padStart(2, '0')}` : `${h} h`;
}

export function ilYa(secondes: number): string {
  return secondes < 60 ? `il y a ${secondes} s` : `il y a ${Math.floor(secondes / 60)} min`;
}
