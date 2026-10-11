import { Injectable } from '@angular/core';

export interface Point { lat: number; lng: number; }

export interface Itineraire {
  points: [number, number][];
  distanceMetres: number;
  dureeVoitureS: number;
  /** Vrai si le calcul routier a échoué : trajet à vol d'oiseau. */
  estimation: boolean;
}

export function distanceLabel(m: number): string {
  return m >= 1000 ? `${(m / 1000).toFixed(m >= 10000 ? 0 : 1).replace('.', ',')} km` : `${Math.round(m)} m`;
}

export function dureeLabel(s: number): string {
  const min = Math.max(1, Math.round(s / 60));
  if (min < 60) return `${min} min`;
  const h = Math.floor(min / 60), r = min % 60;
  return r ? `${h} h ${String(r).padStart(2, '0')}` : `${h} h`;
}

/** Position de l'utilisateur et itinéraire routier (OSRM, gratuit, sans clé), comme dans l'app mobile. */
@Injectable({ providedIn: 'root' })
export class ItineraireService {
  positionActuelle(): Promise<Point> {
    return new Promise((ok, ko) => {
      if (!('geolocation' in navigator)) { ko(new Error("Votre navigateur ne permet pas la géolocalisation.")); return; }
      navigator.geolocation.getCurrentPosition(
        p => ok({ lat: p.coords.latitude, lng: p.coords.longitude }),
        e => ko(new Error(e.code === e.PERMISSION_DENIED
          ? 'Autorisez l\'accès à votre position pour être guidé jusqu\'à la gare.'
          : 'Position introuvable. Réessayez dans un instant.')),
        { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 });
    });
  }

  async calculer(depart: Point, arrivee: Point): Promise<Itineraire> {
    try {
      const url = `https://router.project-osrm.org/route/v1/driving/${depart.lng},${depart.lat};${arrivee.lng},${arrivee.lat}?overview=full&geometries=geojson`;
      const ctrl = new AbortController();
      const minuteur = setTimeout(() => ctrl.abort(), 12000);
      const res = await fetch(url, { signal: ctrl.signal });
      clearTimeout(minuteur);
      const json = await res.json();
      const route = json?.routes?.[0];
      if (!route) throw new Error('aucune route');
      return {
        points: (route.geometry.coordinates as [number, number][]).map(([lng, lat]) => [lat, lng]),
        distanceMetres: route.distance, dureeVoitureS: route.duration, estimation: false,
      };
    } catch {
      // Repli : ligne droite, distance routière estimée (+30 %) à 40 km/h en ville.
      const d = this.haversine(depart, arrivee) * 1.3;
      return { points: [[depart.lat, depart.lng], [arrivee.lat, arrivee.lng]], distanceMetres: d, dureeVoitureS: d / (40 / 3.6), estimation: true };
    }
  }

  private haversine(a: Point, b: Point): number {
    const R = 6371000, rad = (x: number) => x * Math.PI / 180;
    const dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(h));
  }
}
