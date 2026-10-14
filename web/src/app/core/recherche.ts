/** Utilitaires de date (format AAAA-MM-JJ, sans décalage de fuseau). */
export function isoJour(d: Date): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}
export function aujourdhui(): string { return isoJour(new Date()); }
export function demain(): string { const d = new Date(); d.setDate(d.getDate() + 1); return isoJour(d); }
export function decaler(iso: string, jours: number): string { const d = new Date(iso + 'T12:00:00'); d.setDate(d.getDate() + jours); return isoJour(d); }
export function libelleJour(iso: string): string {
  const aujourdhui = isoJour(new Date());
  if (iso === aujourdhui) return "Aujourd'hui";
  if (iso === decaler(aujourdhui, 1)) return 'Demain';
  const s = new Intl.DateTimeFormat('fr-FR', { weekday: 'short', day: 'numeric', month: 'short' }).format(new Date(iso + 'T12:00:00'));
  return s.charAt(0).toUpperCase() + s.slice(1);
}
