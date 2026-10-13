import { AfterViewInit, Component, ElementRef, OnDestroy, ViewChild, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import * as L from 'leaflet';
import { ApiService, messageErreur } from '../../core/api.service';
import { Suivi } from '../../core/models';
import { duree, ilYa } from '../../core/suivi';
import { IconComponent } from '../../shared/components/icon/icon.component';

/** Suivi du car en temps réel : carte, temps restant, heure d'arrivée. Actualisé toutes les 15 s. */
@Component({
  selector: 'tb-suivi',
  standalone: true,
  imports: [DatePipe, DecimalPipe, RouterLink, IconComponent],
  template: `
    <div class="disposition">
      <aside class="panneau">
        <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }" class="retour"><tb-icon name="arrow-left" [size]="16" /> Mes billets</a>
        @if (suivi(); as s) {
          <div class="trajet"><b>{{ s.trajet.depart }}</b><tb-icon name="arrow-right" [size]="18" /><b>{{ s.trajet.arrivee }}</b></div>
          <p class="muted">{{ s.trajet.compagnie }}@if (s.trajet.bus_immatriculation) { · car {{ s.trajet.bus_immatriculation }} } · départ {{ s.trajet.heure_depart | date:'EEE d MMM, HH:mm' }}</p>

          <section class="eta" [class.vert]="enRoute()">
            <span class="etiquette">
              @if (enRoute()) { <i class="direct"></i> En direct } @else { {{ s.trajet.statut_label }} }
              @if (s.trajet.retard_minutes && s.phase !== 'arrive') { <span class="retard">+{{ s.trajet.retard_minutes }} min</span> }
            </span>
            <h1>{{ titre() }}</h1>
            <p>{{ sousTitre() }}</p>
            <div class="barre"><div class="rempli" [style.width.%]="s.progression"></div>
              <span class="car" [style.left]="'calc(' + s.progression + '% - 16px)'"><tb-icon name="bus" [size]="16" [stroke]="2.4" /></span></div>
            <div class="extremites"><span>{{ s.trajet.depart }}</span><b>{{ s.progression }} %</b><span>{{ s.trajet.arrivee }}</span></div>
          </section>

          <div class="infos">
            <div><small>Distance restante</small><b>{{ s.distance_restante_km != null ? (s.distance_restante_km | number:'1.0-0') + ' km' : '—' }}</b></div>
            <div><small>Horaire prévu</small><b>{{ s.trajet.heure_arrivee_prevue | date:'HH:mm' }}</b></div>
            <div><small>Vitesse</small><b>{{ s.position?.vitesse_kmh != null && s.source === 'gps' ? (s.position!.vitesse_kmh! | number:'1.0-0') + ' km/h' : '—' }}</b></div>
          </div>
          <p class="source" [class.gps]="s.source === 'gps'"><i></i>{{ source() }}</p>
          @if (erreur()) { <p class="alerte erreur"><tb-icon name="alert" [size]="16" /> Connexion instable : dernières informations affichées.</p> }
        } @else if (erreur()) {
          <div class="carte vide"><div class="icone-vide"><tb-icon name="alert" [size]="26" /></div><h3>Suivi indisponible</h3><p>{{ erreur() }}</p>
            <button class="btn btn-primaire btn-sm" (click)="charger()">Réessayer</button></div>
        } @else {
          <div class="squelette" style="height:320px;border-radius:20px;margin-top:16px"></div>
        }
      </aside>
      <div class="carte-zone"><div #carte class="carte-leaflet"></div>
        <button class="recentrer" (click)="recadrer()" title="Recentrer"><tb-icon name="locate" [size]="20" /></button></div>
    </div>
  `,
  styles: [`
    .disposition{display:grid;grid-template-columns:420px 1fr;height:calc(100vh - 72px);}
    @media (max-width:900px){.disposition{grid-template-columns:1fr;grid-template-rows:auto auto;height:auto;}.carte-zone{order:-1;height:52vh;}}
    .panneau{overflow-y:auto;background:#fff;border-right:1px solid var(--bord);padding:24px;display:flex;flex-direction:column;gap:14px;}
    .retour{display:inline-flex;align-items:center;gap:6px;color:var(--vert);font-weight:700;font-size:14px;}
    .trajet{display:flex;align-items:center;gap:10px;font-size:24px;font-weight:800;letter-spacing:-.02em;}
    .trajet tb-icon{color:var(--or);}
    .muted{font-size:14px;margin-top:-8px;}
    .eta{border-radius:var(--r-xl);padding:22px;background:var(--surface-2);display:flex;flex-direction:column;gap:6px;}
    .eta.vert{background:linear-gradient(150deg,var(--vert-900),var(--vert));color:#fff;}
    .etiquette{display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;opacity:.9;}
    .direct{width:9px;height:9px;border-radius:50%;background:#4ADE80;box-shadow:0 0 0 0 rgba(74,222,128,.6);animation:pouls 1.6s infinite;}
    @keyframes pouls{70%{box-shadow:0 0 0 10px rgba(74,222,128,0)}100%{box-shadow:0 0 0 0 rgba(74,222,128,0)}}
    .retard{background:var(--or);color:var(--encre);border-radius:999px;padding:2px 8px;text-transform:none;letter-spacing:0;}
    .eta h1{font-size:32px;font-weight:900;letter-spacing:-.03em;line-height:1.1;}
    .eta p{opacity:.85;}
    .barre{position:relative;height:8px;border-radius:4px;background:rgba(127,127,127,.25);margin:18px 0 6px;}
    .rempli{height:100%;border-radius:4px;background:var(--or);transition:width .6s;}
    .car{position:absolute;top:50%;transform:translateY(-50%);width:32px;height:32px;border-radius:50%;background:#fff;color:var(--vert);
      display:flex;align-items:center;justify-content:center;box-shadow:var(--ombre-2);transition:left .6s;}
    .extremites{display:flex;justify-content:space-between;font-size:13px;font-weight:600;opacity:.85;}
    .infos{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;}
    .infos div{border:1px solid var(--bord);border-radius:var(--r);padding:12px;display:flex;flex-direction:column;}
    .infos small{font-size:12px;color:var(--texte-3);font-weight:600;}
    .infos b{font-size:17px;}
    .source{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--texte-2);}
    .source i{width:8px;height:8px;border-radius:50%;background:var(--texte-3);}
    .source.gps i{background:#22C55E;}
    .carte-zone{position:relative;}
    .carte-leaflet{position:absolute;inset:0;}
    .recentrer{position:absolute;top:14px;right:14px;z-index:500;width:44px;height:44px;border-radius:50%;border:none;background:#fff;
      box-shadow:var(--ombre-2);color:var(--vert);cursor:pointer;display:flex;align-items:center;justify-content:center;}
  `],
})
export class SuiviComponent implements AfterViewInit, OnDestroy {
  @ViewChild('carte') private conteneur!: ElementRef<HTMLDivElement>;
  private api = inject(ApiService);
  private trajetId = inject(ActivatedRoute).snapshot.paramMap.get('trajetId') ?? '';
  private carte?: L.Map;
  private couches?: L.LayerGroup;
  private marqueurCar?: L.Marker;
  private minuteur?: ReturnType<typeof setTimeout>;
  private premierCadrage = true;
  private ferme = false;

  suivi = signal<Suivi | null>(null);
  erreur = signal('');
  enRoute = computed(() => ['en_route', 'arrivee_imminente'].includes(this.suivi()?.phase ?? ''));
  titre = computed(() => {
    const s = this.suivi(); if (!s) return '';
    switch (s.phase) {
      case 'a_venir': return s.depart_dans_minutes ? `Départ dans ${duree(s.depart_dans_minutes)}` : 'Départ imminent';
      case 'arrivee_imminente': return 'Arrivée imminente';
      case 'arrive': return `Arrivé à ${s.trajet.arrivee}`;
      case 'annule': return 'Trajet annulé';
      default: return `Arrivée dans ${duree(s.minutes_restantes ?? 0)}`;
    }
  });
  sousTitre = computed(() => {
    const s = this.suivi(); if (!s) return '';
    const h = (iso: string | null) => iso ? new Date(iso).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : '';
    if (s.phase === 'a_venir') return `Arrivée prévue à ${s.trajet.arrivee} vers ${h(s.arrivee_estimee)}`;
    if (s.phase === 'arrive') return `à ${h(s.arrivee_estimee)}`;
    if (s.phase === 'annule') return 'Consultez vos billets pour le remboursement.';
    return `à ${s.trajet.arrivee}, vers ${h(s.arrivee_estimee)}`;
  });
  source = computed(() => {
    const s = this.suivi(); if (!s) return '';
    if (s.source === 'gps' && s.position) return `Position GPS du car ${ilYa(s.position.il_y_a_secondes)} · actualisation automatique`;
    if (this.enRoute()) return "Estimation selon l'horaire : la position du car n'est pas disponible pour le moment.";
    return s.phase === 'a_venir' ? 'Le suivi en direct commence au départ du car.' : 'Suivi terminé.';
  });

  ngAfterViewInit(): void {
    this.carte = L.map(this.conteneur.nativeElement, { zoomControl: true }).setView([7.54, -5.55], 7);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      { maxZoom: 19, attribution: '&copy; OpenStreetMap &copy; CARTO' }).addTo(this.carte);
    this.couches = L.layerGroup().addTo(this.carte);
    this.charger();
  }

  charger(): void {
    clearTimeout(this.minuteur);
    this.api.suivi(this.trajetId).subscribe({
      next: s => { this.suivi.set(s); this.erreur.set(''); this.dessiner(s); this.planifier(s); },
      error: e => { this.erreur.set(messageErreur(e, 'Suivi indisponible pour le moment.')); this.planifier(this.suivi()); },
    });
  }

  private planifier(s: Suivi | null): void {
    if (this.ferme || (s && ['arrive', 'annule'].includes(s.phase))) return;
    const enRoute = !s || ['en_route', 'arrivee_imminente'].includes(s.phase);
    this.minuteur = setTimeout(() => this.charger(), (enRoute ? (s?.rafraichir_dans_secondes ?? 15) : 60) * 1000);
  }

  private dessiner(s: Suivi): void {
    if (!this.carte || !this.couches) return;
    this.couches.clearLayers();
    const dep = s.point_depart, arr = s.point_arrivee;
    if (dep && arr) {
      L.polyline([[dep.latitude, dep.longitude], [arr.latitude, arr.longitude]],
        { color: '#0F4A3B', weight: 3, opacity: .35, dashArray: '6 10' }).addTo(this.couches);
    }
    if (s.trace && s.trace.length > 1) {
      L.polyline(s.trace, { color: '#fff', weight: 9, opacity: .9 }).addTo(this.couches);
      L.polyline(s.trace, { color: '#2E8466', weight: 5 }).addTo(this.couches);
    }
    if (dep) L.marker([dep.latitude, dep.longitude], { title: dep.nom, icon: L.divIcon({ className: '', iconSize: [20, 20], iconAnchor: [10, 10],
      html: '<div class="marqueur-depart"></div>' }) }).addTo(this.couches);
    if (arr) L.marker([arr.latitude, arr.longitude], { title: arr.nom, icon: L.divIcon({ className: '', iconSize: [34, 34], iconAnchor: [17, 34],
      html: `<div class="marqueur-gare principale"><span>${arr.ville[0]}</span></div>` }) }).addTo(this.couches);
    if (s.position) {
      this.marqueurCar = L.marker([s.position.latitude, s.position.longitude], { title: 'Le car', zIndexOffset: 1000,
        icon: L.divIcon({ className: '', iconSize: [44, 44], iconAnchor: [22, 22],
          html: `<div class="marqueur-car${s.source === 'gps' ? '' : ' estime'}"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 6v6M15 6v6M2 12h19.6M18 18h3s.5-1.7.8-2.8c.1-.4.2-.8.2-1.2 0-.4-.1-.8-.2-1.2l-1.4-5C20.1 6.8 19.1 6 18 6H4a2 2 0 0 0-2 2v10h3"/><circle cx="7" cy="18" r="2"/><path d="M9 18h5"/><circle cx="16" cy="18" r="2"/></svg></div>` }) }).addTo(this.couches);
    }
    if (this.premierCadrage) { this.premierCadrage = false; this.recadrer(); }
  }

  recadrer(): void {
    const s = this.suivi(); if (!s || !this.carte) return;
    const pts: L.LatLngExpression[] = [];
    if (s.point_depart) pts.push([s.point_depart.latitude, s.point_depart.longitude]);
    if (s.point_arrivee) pts.push([s.point_arrivee.latitude, s.point_arrivee.longitude]);
    if (s.position) pts.push([s.position.latitude, s.position.longitude]);
    if (pts.length > 1) this.carte.fitBounds(L.latLngBounds(pts), { padding: [50, 50] });
    else if (pts.length === 1) this.carte.setView(pts[0], 11);
  }

  ngOnDestroy(): void { this.ferme = true; clearTimeout(this.minuteur); this.carte?.remove(); }
}
