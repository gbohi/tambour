import { AfterViewInit, Component, ElementRef, OnDestroy, ViewChild, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { Router } from '@angular/router';
import * as L from 'leaflet';
import { ApiService } from '../../core/api.service';
import { Gare, Trajet } from '../../core/models';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

@Component({
  selector: 'tb-gares',
  standalone: true,
  imports: [DatePipe, IconComponent, NombrePipe],
  template: `
    <div class="disposition">
      <aside class="panneau">
        <div class="tete">
          <h1>Nos gares</h1>
          <p class="muted">{{ gares().length }} gares dans {{ villes().length }} villes</p>
          <div class="recherche"><tb-icon name="search" [size]="18" />
            <input class="entree" placeholder="Ville ou gare…" [value]="filtre()" (input)="filtre.set($any($event.target).value)"></div>
        </div>
        @if (choisie(); as g) {
          <div class="fiche">
            <button class="retour" (click)="choisir(null)"><tb-icon name="arrow-left" [size]="16" /> Toutes les gares</button>
            <h2>{{ g.nom }}</h2>
            <p class="muted"><tb-icon name="map-pin" [size]="15" /> {{ g.adresse }}, {{ g.ville_nom }}</p>
            <div class="pastilles">
              <span class="pastille"><tb-icon name="clock" [size]="14" /> {{ g.heures_ouverture }}</span>
              @if (g.telephone) { <a class="pastille" [href]="'tel:' + g.telephone"><tb-icon name="phone" [size]="14" /> {{ g.telephone }}</a> }
            </div>
            <div class="boutons">
              <a class="btn btn-primaire btn-sm" target="_blank" rel="noopener"
                [href]="'https://www.google.com/maps/dir/?api=1&destination=' + g.latitude + ',' + g.longitude"><tb-icon name="route" [size]="16" /> Itinéraire</a>
            </div>
            <h3>Prochains départs</h3>
            @if (chargementDeparts()) { <div class="squelette" style="height:200px"></div> }
            @for (t of departs(); track t.id) {
              <button class="depart" (click)="reserver(t)">
                <div class="h"><b>{{ t.heure_depart | date:'HH:mm' }}</b><small>{{ t.heure_depart | date:'EEE d' }}</small></div>
                <div class="d"><b>{{ t.arrivee.nom }}</b><small>{{ t.compagnie }} · {{ t.duree_label }}</small></div>
                <span class="montant">{{ t.prix_actuel | nb:'F' }}</span>
              </button>
            } @empty { @if (!chargementDeparts()) { <p class="muted">Aucun départ dans les 7 prochains jours.</p> } }
          </div>
        } @else {
          <div class="liste">
            @for (g of filtrees(); track g.id) {
              <button class="gare" (click)="choisir(g)">
                <span class="pin" [class.principale]="g.est_principale"><tb-icon name="map-pin" [size]="18" /></span>
                <div><b>{{ g.nom }}</b><small>{{ g.ville_nom }} · {{ g.heures_ouverture }}</small></div>
                <tb-icon name="chevron-right" [size]="18" />
              </button>
            }
          </div>
        }
      </aside>
      <div class="carte-zone"><div #carte class="carte-leaflet"></div></div>
    </div>
  `,
  styles: [`
    .disposition{display:grid;grid-template-columns:420px 1fr;height:calc(100vh - 72px);}
    @media (max-width:900px){.disposition{grid-template-columns:1fr;grid-template-rows:45vh auto;height:auto;}.carte-zone{order:-1;}}
    .panneau{overflow-y:auto;background:#fff;border-right:1px solid var(--bord);}
    .tete{padding:28px 24px 16px;position:sticky;top:0;background:#fff;z-index:2;border-bottom:1px solid var(--bord);}
    h1{font-size:30px;font-weight:800;letter-spacing:-.03em;}
    .recherche{position:relative;margin-top:16px;}
    .recherche tb-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--texte-3);}
    .recherche .entree{padding-left:42px;height:48px;}
    .liste{padding:8px 12px 24px;}
    .gare{display:flex;align-items:center;gap:14px;width:100%;text-align:left;padding:14px 12px;border:none;background:none;border-radius:14px;cursor:pointer;}
    .gare:hover{background:var(--surface-2);}
    .gare div{flex:1;display:flex;flex-direction:column;}
    .gare small,.depart small{color:var(--texte-2);font-size:13px;}
    .pin{width:42px;height:42px;border-radius:13px;background:var(--vert-clair);color:var(--vert);display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .pin.principale{background:var(--or-clair);color:var(--or-fonce);}
    .fiche{padding:20px 24px 28px;display:flex;flex-direction:column;gap:12px;}
    .retour{align-self:flex-start;display:inline-flex;align-items:center;gap:6px;border:none;background:none;color:var(--vert);font-weight:700;cursor:pointer;}
    h2{font-size:24px;font-weight:800;}
    .fiche .muted{display:flex;gap:6px;align-items:flex-start;}
    .pastilles,.boutons{display:flex;gap:8px;flex-wrap:wrap;}
    h3{font-size:17px;margin-top:12px;}
    .depart{display:grid;grid-template-columns:60px 1fr auto;gap:12px;align-items:center;padding:12px;border:1px solid var(--bord);border-radius:14px;background:#fff;cursor:pointer;text-align:left;}
    .depart:hover{border-color:var(--vert);}
    .depart .h,.depart .d{display:flex;flex-direction:column;}
    .depart .h b{font-size:18px;}
    .carte-zone{position:relative;}
    .carte-leaflet{position:absolute;inset:0;}
    @media (max-width:900px){.carte-leaflet{position:relative;height:45vh;}}
  `],
})
export class GaresComponent implements AfterViewInit, OnDestroy {
  @ViewChild('carte') private conteneurCarte!: ElementRef<HTMLDivElement>;
  private api = inject(ApiService);
  private router = inject(Router);
  private carte?: L.Map;
  private marqueurs = new Map<string, L.Marker>();

  gares = signal<Gare[]>([]);
  choisie = signal<Gare | null>(null);
  departs = signal<Trajet[]>([]);
  chargementDeparts = signal(false);
  filtre = signal('');
  villes = computed(() => [...new Set(this.gares().map(g => g.ville_nom))]);
  filtrees = computed(() => {
    const q = this.filtre().toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
    return this.gares().filter(g => !q || `${g.nom} ${g.ville_nom}`.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').includes(q));
  });

  ngAfterViewInit(): void {
    this.carte = L.map(this.conteneurCarte.nativeElement, { zoomControl: true, scrollWheelZoom: true }).setView([7.54, -5.55], 7);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
      maxZoom: 19, attribution: '&copy; OpenStreetMap &copy; CARTO',
    }).addTo(this.carte);
    this.api.gares().subscribe(g => {
      this.gares.set(g);
      g.forEach(gare => {
        const icone = L.divIcon({ className: '', iconSize: [34, 34], iconAnchor: [17, 34],
          html: `<div class="marqueur-gare${gare.est_principale ? ' principale' : ''}"><span>${gare.ville_nom[0]}</span></div>` });
        const m = L.marker([+gare.latitude, +gare.longitude], { icon: icone, title: gare.nom }).addTo(this.carte!);
        m.on('click', () => this.choisir(gare));
        this.marqueurs.set(gare.id, m);
      });
      if (g.length) this.carte!.fitBounds(L.latLngBounds(g.map(x => [+x.latitude, +x.longitude] as [number, number])), { padding: [40, 40] });
    });
  }

  choisir(g: Gare | null): void {
    this.choisie.set(g);
    if (!g) return;
    this.carte?.flyTo([+g.latitude, +g.longitude], 14, { duration: .8 });
    this.chargementDeparts.set(true);
    this.departs.set([]);
    this.api.departsGare(g.id).subscribe({
      next: d => { this.departs.set(d.slice(0, 12)); this.chargementDeparts.set(false); },
      error: () => this.chargementDeparts.set(false),
    });
  }

  reserver(t: Trajet): void { this.router.navigate(['/reservation', t.id], { queryParams: { passagers: 1 } }); }

  ngOnDestroy(): void { this.carte?.remove(); }
}
