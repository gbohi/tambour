import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../core/api.service';
import { LignePopulaire } from '../../core/models';
import { aujourdhui } from '../../core/recherche';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

@Component({
  selector: 'tb-destinations',
  standalone: true,
  imports: [IconComponent, NombrePipe],
  template: `
    <section class="tete">
      <div class="conteneur">
        <span class="surtitre">Destinations</span>
        <h1 class="titre-section">{{ vers() ? 'Car pour ' + vers() : 'Toutes nos lignes' }}</h1>
        <p class="intro">Choisissez une ligne pour voir les départs de demain.</p>
        @if (vers()) { <button class="puce-vers" (click)="toutes()">Vers {{ vers() }} <tb-icon name="x" [size]="14" /></button> }
        <div class="recherche"><tb-icon name="search" [size]="18" />
          <input class="entree" placeholder="Rechercher une ville…" [value]="filtre()" (input)="filtre.set($any($event.target).value)"></div>
      </div>
    </section>
    <div class="conteneur corps">
      @for (groupe of parDepart(); track groupe.ville) {
        <h2>Au départ de {{ groupe.ville }}</h2>
        <div class="grille">
          @for (l of groupe.lignes; track l.id) {
            <button class="ligne" (click)="voir(l)">
              <div class="haut"><b>{{ l.arrivee }}</b>@if (l.est_populaire) { <span class="pastille or">Populaire</span> }</div>
              <div class="bas">
                <span class="muted">@if (l.duree_label) { {{ l.duree_label }} · }{{ l.trajets_par_jour ? l.trajets_par_jour + ' départs/jour' : 'Départs réguliers' }}</span>
                <span class="prix">@if (l.prix_min) { <small>dès</small> {{ l.prix_min | nb:'F' }} }</span>
              </div>
            </button>
          }
        </div>
      } @empty {
        <div class="vide"><div class="icone-vide"><tb-icon name="route" [size]="28" /></div><h3>Aucune ligne trouvée</h3></div>
      }
    </div>
  `,
  styles: [`
    .puce-vers{align-self:flex-start;display:inline-flex;align-items:center;gap:6px;margin-top:12px;border:none;border-radius:999px;padding:8px 14px;background:var(--or);color:var(--encre);font-weight:700;cursor:pointer;}
    .tete{background:#fff;border-bottom:1px solid var(--bord);padding:56px 0 32px;}
    .recherche{position:relative;max-width:420px;margin-top:24px;}
    .recherche tb-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--texte-3);}
    .recherche .entree{padding-left:42px;}
    .corps{padding-top:32px;padding-bottom:40px;}
    h2{font-size:22px;font-weight:800;margin:24px 0 14px;}
    .grille{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:14px;}
    .ligne{display:flex;flex-direction:column;gap:20px;text-align:left;padding:20px;border-radius:var(--r-lg);border:1px solid var(--bord);background:#fff;cursor:pointer;transition:all .2s;}
    .ligne:hover{transform:translateY(-3px);box-shadow:var(--ombre-2);border-color:transparent;}
    .haut{display:flex;justify-content:space-between;align-items:center;gap:10px;}
    .haut b{font-size:20px;font-weight:800;}
    .bas{display:flex;justify-content:space-between;align-items:flex-end;gap:10px;font-size:14px;}
    .prix{font-size:20px;font-weight:900;color:var(--vert);white-space:nowrap;}
    .prix small{font-size:12px;color:var(--texte-3);font-weight:600;}
  `],
})
export class DestinationsComponent implements OnInit {
  private api = inject(ApiService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  vers = signal('');
  lignes = signal<LignePopulaire[]>([]);
  filtre = signal('');
  parDepart = computed(() => {
    const q = this.filtre().toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
    const vers = this.vers();
    const groupes = new Map<string, LignePopulaire[]>();
    this.lignes()
      .filter(l => !vers || l.arrivee === vers)
      .filter(l => !q || `${l.depart} ${l.arrivee}`.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').includes(q))
      .forEach(l => groupes.set(l.depart, [...(groupes.get(l.depart) ?? []), l]));
    return [...groupes.entries()].map(([ville, lignes]) => ({ ville, lignes })).sort((a, b) => b.lignes.length - a.lignes.length);
  });
  ngOnInit(): void {
    this.api.lignesPopulaires().subscribe(l => this.lignes.set(l));
    this.route.queryParamMap.subscribe(q => this.vers.set(q.get('ville') ?? ''));
  }
  toutes(): void { this.router.navigate(['/destinations']); }
  voir(l: LignePopulaire): void {
    this.router.navigate(['/recherche'], { queryParams: { depart: l.depart_id, arrivee: l.arrivee_id, date: aujourdhui(), passagers: 1 } });
  }
}
