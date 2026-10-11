import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../core/api.service';
import { VillesService } from '../../core/villes.service';
import { Trajet, Ville } from '../../core/models';
import { decaler, isoJour, libelleJour } from '../../core/recherche';
import { FormulaireRechercheComponent } from '../../shared/components/formulaire-recherche.component';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

type Tri = 'horaire' | 'prix' | 'duree' | 'note';
const MOMENTS = [
  { code: 'matin', label: 'Matin', detail: '05h – 12h', de: 5, a: 12 },
  { code: 'aprem', label: 'Après-midi', detail: '12h – 18h', de: 12, a: 18 },
  { code: 'soir', label: 'Soir & nuit', detail: '18h – 05h', de: 18, a: 29 },
];
const EQUIPEMENTS: Record<string, { label: string; icone: string }> = {
  clim: { label: 'Climatisation', icone: 'snow' }, wifi: { label: 'Wi-Fi', icone: 'wifi' }, usb: { label: 'Prises USB', icone: 'plug' },
  siege_large: { label: 'Sièges larges', icone: 'seat' }, eau: { label: 'Eau offerte', icone: 'leaf' }, snack: { label: 'Collation', icone: 'gift' },
  toilet: { label: 'Toilettes', icone: 'info' },
};

@Component({
  selector: 'tb-recherche-page',
  standalone: true,
  imports: [DatePipe, FormulaireRechercheComponent, IconComponent, NombrePipe],
  template: `
    <section class="bandeau">
      <div class="conteneur">
        @if (pret()) {
          <tb-recherche [compact]="true" [departId]="departId()" [arriveeId]="arriveeId()" [dateInitiale]="date()" [passagersInitial]="passagers()" />
        }
      </div>
    </section>

    <div class="conteneur">
      <div class="dates">
        <button class="fleche" (click)="changerDate(decaler(date(), -1))" [disabled]="date() <= aujourdhui" aria-label="Jour précédent"><tb-icon name="chevron-left" /></button>
        @for (j of jours(); track j) {
          <button class="jour" [class.actif]="j === date()" (click)="changerDate(j)" [disabled]="j < aujourdhui">{{ libelle(j) }}</button>
        }
        <button class="fleche" (click)="changerDate(decaler(date(), 1))" aria-label="Jour suivant"><tb-icon name="chevron-right" /></button>
      </div>

      <div class="titre-resultats">
        <h1>{{ villeNom(departId()) }} <tb-icon name="arrow-right" [size]="24" /> {{ villeNom(arriveeId()) }}</h1>
        <p class="muted">{{ libelle(date()) }} · {{ passagers() }} passager{{ passagers() > 1 ? 's' : '' }}
          @if (!chargement()) { · <b>{{ affiches().length }} départ{{ affiches().length > 1 ? 's' : '' }}</b> }</p>
      </div>

      <div class="disposition">
        <aside class="filtres" [class.ouverts]="filtresOuverts()">
          <div class="filtres-tete"><b>Filtres</b>
            @if (nbFiltres()) { <button class="btn-texte" (click)="reinitialiser()">Effacer</button> }
            <button class="fermer" (click)="filtresOuverts.set(false)"><tb-icon name="x" /></button></div>
          <div class="groupe">
            <h4>Trier par</h4>
            @for (t of tris; track t.code) {
              <label class="radio"><input type="radio" name="tri" [checked]="tri() === t.code" (change)="tri.set(t.code)"> {{ t.label }}</label>
            }
          </div>
          <div class="groupe">
            <h4>Heure de départ</h4>
            @for (m of moments; track m.code) {
              <label class="case"><input type="checkbox" [checked]="momentsChoisis().has(m.code)" (change)="basculer(momentsChoisis, m.code)">
                <span>{{ m.label }}</span><small>{{ m.detail }}</small></label>
            }
          </div>
          <div class="groupe">
            <h4>Confort</h4>
            @for (c of classes; track c.code) {
              <label class="case"><input type="checkbox" [checked]="classesChoisies().has(c.code)" (change)="basculer(classesChoisies, c.code)">
                <span>{{ c.label }}</span></label>
            }
          </div>
          @if (compagnies().length > 1) {
            <div class="groupe">
              <h4>Compagnies</h4>
              @for (c of compagnies(); track c) {
                <label class="case"><input type="checkbox" [checked]="compagniesChoisies().has(c)" (change)="basculer(compagniesChoisies, c)"><span>{{ c }}</span></label>
              }
            </div>
          }
          <button class="btn btn-primaire btn-bloc voir" (click)="filtresOuverts.set(false)">Voir {{ affiches().length }} départs</button>
        </aside>

        <div class="liste">
          <button class="btn btn-blanc btn-sm bouton-filtres" (click)="filtresOuverts.set(true)">
            <tb-icon name="sliders" [size]="16" /> Filtres et tri @if (nbFiltres()) { ({{ nbFiltres() }}) }</button>

          @if (chargement()) {
            @for (i of [1,2,3,4]; track i) { <div class="squelette" style="height:170px;margin-bottom:14px;border-radius:20px"></div> }
          } @else if (erreur()) {
            <div class="carte vide"><div class="icone-vide"><tb-icon name="alert" [size]="28" /></div><h3>Recherche impossible</h3><p>{{ erreur() }}</p>
              <button class="btn btn-primaire btn-sm" (click)="charger()">Réessayer</button></div>
          } @else {
            @for (t of affiches(); track t.id; let i = $index) {
              <article class="trajet" [class.meilleur]="t.id === moinsCher()?.id && affiches().length > 1">
                @if (t.id === moinsCher()?.id && affiches().length > 1) { <span class="ruban">Le moins cher</span> }
                <div class="horaires">
                  <div class="point"><b>{{ t.heure_depart | date:'HH:mm' }}</b><span>{{ t.depart.nom }}</span>
                    @if (t.gare_depart) { <small>{{ t.gare_depart.nom }}</small> }</div>
                  <div class="duree"><span>{{ t.duree_label }}</span><i></i><small>Direct</small></div>
                  <div class="point"><b>{{ t.heure_arrivee_estimee | date:'HH:mm' }}</b><span>{{ t.arrivee.nom }}</span></div>
                </div>
                <div class="details">
                  <div class="compagnie">
                    <span class="logo-cie">{{ t.compagnie[0] }}</span>
                    <div><b>{{ t.compagnie }}</b>
                      <div class="sous">
                        <span class="classe" [class]="'classe ' + t.bus_classe">{{ classeLabel(t.bus_classe) }}</span>
                        @if (+t.note_moyenne > 0) { <span class="note"><tb-icon name="star" [size]="13" /> {{ t.note_moyenne }} <small>({{ t.nombre_avis }})</small></span> }
                      </div></div>
                  </div>
                  <div class="equipements">
                    @for (a of t.amenities.slice(0, 5); track a) { <span [title]="equip(a).label"><tb-icon [name]="equip(a).icone" [size]="16" /></span> }
                  </div>
                </div>
                <div class="achat">
                  <div class="prix">
                    @if (t.est_en_promo) { <s>{{ t.prix_fcfa * passagers() | nb:'F' }}</s> }
                    <b>{{ t.prix_actuel * passagers() | nb:'F' }}</b>
                    @if (passagers() > 1) { <small>{{ t.prix_actuel | nb:'F' }} / pers.</small> }
                  </div>
                  <span class="places" [class.peu]="t.places_disponibles <= 5">
                    {{ t.places_disponibles <= 5 ? 'Plus que ' + t.places_disponibles + ' places' : t.places_disponibles + ' places libres' }}</span>
                  <button class="btn btn-primaire" (click)="choisir(t)">Choisir <tb-icon name="arrow-right" [size]="18" /></button>
                </div>
              </article>
            } @empty {
              <div class="carte vide">
                <div class="icone-vide"><tb-icon name="route" [size]="28" /></div>
                <h3>Aucun départ ce jour-là</h3>
                <p>{{ trajets().length ? 'Aucun départ ne correspond à vos filtres.' : 'Essayez une autre date : les départs sont publiés 7 jours à l\\'avance.' }}</p>
                @if (trajets().length) { <button class="btn btn-contour btn-sm" (click)="reinitialiser()">Effacer les filtres</button> }
                @else { <button class="btn btn-primaire btn-sm" (click)="changerDate(decaler(date(), 1))">Voir le lendemain</button> }
              </div>
            }
          }
        </div>
      </div>
    </div>
  `,
  styles: [`
    .bandeau{background:linear-gradient(165deg,#072A21,#0F4A3B);padding:28px 0;}
    .dates{display:flex;gap:8px;align-items:center;margin:28px 0 8px;overflow-x:auto;padding-bottom:4px;}
    .jour{flex:1;min-width:110px;height:50px;border-radius:14px;border:1px solid var(--bord);background:#fff;font-weight:600;cursor:pointer;color:var(--texte-2);white-space:nowrap;}
    .jour:hover:not(:disabled){border-color:var(--vert);color:var(--vert);}
    .jour.actif{background:var(--encre);color:#fff;border-color:var(--encre);}
    .jour:disabled{opacity:.4;cursor:not-allowed;}
    .fleche{width:44px;height:50px;border-radius:14px;border:1px solid var(--bord);background:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .fleche:disabled{opacity:.4;}
    .titre-resultats{margin:24px 0;}
    .titre-resultats h1{display:flex;align-items:center;gap:12px;font-size:clamp(26px,3vw,34px);font-weight:800;letter-spacing:-.03em;flex-wrap:wrap;}
    .titre-resultats h1 tb-icon{color:var(--or);}
    .disposition{display:grid;grid-template-columns:270px 1fr;gap:28px;align-items:start;padding-bottom:40px;}
    .filtres{position:sticky;top:96px;background:#fff;border:1px solid var(--bord);border-radius:var(--r-lg);padding:20px;}
    .filtres-tete{display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;font-size:18px;}
    .fermer,.voir,.bouton-filtres{display:none;}
    .groupe{padding:16px 0;border-bottom:1px solid var(--bord);display:flex;flex-direction:column;gap:10px;}
    .groupe:last-of-type{border-bottom:none;}
    .groupe h4{font-size:13px;text-transform:uppercase;letter-spacing:.06em;color:var(--texte-3);}
    .radio,.case{display:flex;align-items:center;gap:10px;cursor:pointer;font-weight:500;}
    .radio input,.case input{accent-color:var(--vert);width:18px;height:18px;}
    .case small{margin-left:auto;color:var(--texte-3);font-size:13px;}
    .trajet{position:relative;display:grid;grid-template-columns:1.3fr 1fr auto;gap:24px;align-items:center;background:#fff;border:1px solid var(--bord);
      border-radius:22px;padding:24px;margin-bottom:14px;transition:box-shadow .2s,border-color .2s;}
    .trajet:hover{box-shadow:var(--ombre-2);border-color:transparent;}
    .trajet.meilleur{border-color:var(--or);}
    .ruban{position:absolute;top:-11px;left:24px;background:var(--or);color:var(--encre);font-size:12px;font-weight:800;padding:3px 10px;border-radius:999px;}
    .horaires{display:grid;grid-template-columns:auto 1fr auto;gap:14px;align-items:center;}
    .point{display:flex;flex-direction:column;}
    .point b{font-size:26px;font-weight:800;letter-spacing:-.02em;font-variant-numeric:tabular-nums;}
    .point span{font-weight:600;color:var(--texte-2);}
    .point small{font-size:12px;color:var(--texte-3);max-width:140px;}
    .duree{display:flex;flex-direction:column;align-items:center;gap:4px;font-size:13px;color:var(--texte-2);font-weight:600;}
    .duree i{width:100%;height:2px;background:repeating-linear-gradient(90deg,var(--vert) 0 6px,transparent 6px 10px);position:relative;}
    .duree i::before,.duree i::after{content:'';position:absolute;top:-4px;width:10px;height:10px;border-radius:50%;border:2px solid var(--vert);background:#fff;}
    .duree i::before{left:-4px;} .duree i::after{right:-4px;background:var(--vert);}
    .duree small{color:var(--texte-3);}
    .details{display:flex;flex-direction:column;gap:14px;}
    .compagnie{display:flex;align-items:center;gap:12px;}
    .logo-cie{width:44px;height:44px;border-radius:13px;background:var(--encre);color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;}
    .sous{display:flex;gap:10px;align-items:center;font-size:13px;}
    .classe{font-weight:700;color:var(--texte-2);}
    .classe.confort{color:var(--vert);} .classe.vip{color:var(--or-fonce);}
    .note{display:inline-flex;align-items:center;gap:3px;color:var(--or-fonce);font-weight:700;}
    .note small{color:var(--texte-3);font-weight:500;}
    .equipements{display:flex;gap:6px;}
    .equipements span{width:32px;height:32px;border-radius:9px;background:var(--surface-2);color:var(--texte-2);display:flex;align-items:center;justify-content:center;}
    .achat{display:flex;flex-direction:column;align-items:flex-end;gap:8px;min-width:170px;}
    .prix{display:flex;flex-direction:column;align-items:flex-end;}
    .prix b{font-size:28px;font-weight:900;color:var(--vert);letter-spacing:-.02em;white-space:nowrap;}
    .prix s{font-size:14px;color:var(--texte-3);}
    .prix small{font-size:13px;color:var(--texte-3);}
    .places{font-size:13px;font-weight:600;color:var(--texte-2);}
    .places.peu{color:var(--danger);}
    @media (max-width:1000px){
      .disposition{grid-template-columns:1fr;}
      .bouton-filtres{display:inline-flex;margin-bottom:14px;}
      .filtres{display:none;position:fixed;inset:0;top:0;z-index:900;border-radius:0;overflow-y:auto;}
      .filtres.ouverts{display:block;}
      .fermer{display:inline-flex;border:none;background:var(--surface-2);width:40px;height:40px;border-radius:12px;align-items:center;justify-content:center;cursor:pointer;}
      .voir{display:flex;margin-top:12px;}
      .trajet{grid-template-columns:1fr;gap:18px;}
      .achat{flex-direction:row;align-items:center;justify-content:space-between;flex-wrap:wrap;min-width:0;border-top:1px solid var(--bord);padding-top:16px;}
      .prix{align-items:flex-start;}
    }
  `],
})
export class RechercheComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private api = inject(ApiService);
  private villesService = inject(VillesService);

  readonly tris: { code: Tri; label: string }[] = [
    { code: 'horaire', label: 'Départ le plus tôt' }, { code: 'prix', label: 'Prix le plus bas' },
    { code: 'duree', label: 'Trajet le plus court' }, { code: 'note', label: 'Mieux notés' },
  ];
  readonly moments = MOMENTS;
  readonly classes = [{ code: 'standard', label: 'Standard' }, { code: 'confort', label: 'Confort' }, { code: 'vip', label: 'VIP' }];
  readonly aujourdhui = isoJour(new Date());
  readonly decaler = decaler;

  villes = signal<Ville[]>([]);
  departId = signal(''); arriveeId = signal(''); date = signal(''); passagers = signal(1);
  pret = signal(false);
  trajets = signal<Trajet[]>([]);
  chargement = signal(true);
  erreur = signal('');
  tri = signal<Tri>('horaire');
  momentsChoisis = signal(new Set<string>());
  classesChoisies = signal(new Set<string>());
  compagniesChoisies = signal(new Set<string>());
  filtresOuverts = signal(false);

  jours = computed(() => {
    const debut = this.date() <= decaler(this.aujourdhui, 2) ? this.aujourdhui : decaler(this.date(), -2);
    return Array.from({ length: 5 }, (_, i) => decaler(debut, i));
  });
  compagnies = computed(() => [...new Set(this.trajets().map(t => t.compagnie))].sort());
  nbFiltres = computed(() => this.momentsChoisis().size + this.classesChoisies().size + this.compagniesChoisies().size);
  affiches = computed(() => {
    const m = this.momentsChoisis(), c = this.classesChoisies(), cie = this.compagniesChoisies();
    const liste = this.trajets().filter(t => {
      const h = new Date(t.heure_depart).getHours();
      const okMoment = !m.size || MOMENTS.some(x => m.has(x.code) && ((h >= x.de && h < x.a) || (x.a > 24 && h < x.a - 24)));
      return okMoment && (!c.size || c.has(t.bus_classe)) && (!cie.size || cie.has(t.compagnie));
    });
    const duree = (t: Trajet) => new Date(t.heure_arrivee_estimee).getTime() - new Date(t.heure_depart).getTime();
    const tri = this.tri();
    return [...liste].sort((a, b) =>
      tri === 'prix' ? a.prix_actuel - b.prix_actuel :
      tri === 'duree' ? duree(a) - duree(b) :
      tri === 'note' ? +b.note_moyenne - +a.note_moyenne :
      a.heure_depart.localeCompare(b.heure_depart));
  });
  moinsCher = computed(() => this.affiches().reduce<Trajet | null>((m, t) => !m || t.prix_actuel < m.prix_actuel ? t : m, null));

  ngOnInit(): void {
    this.villesService.villes$.subscribe(v => this.villes.set(v));
    this.route.queryParamMap.subscribe(p => {
      this.departId.set(p.get('depart') ?? '');
      this.arriveeId.set(p.get('arrivee') ?? '');
      this.date.set(p.get('date') ?? decaler(this.aujourdhui, 1));
      this.passagers.set(Math.min(9, Math.max(1, Number(p.get('passagers')) || 1)));
      // Recrée le formulaire avec les nouvelles valeurs
      this.pret.set(false);
      setTimeout(() => this.pret.set(true));
      this.charger();
    });
  }

  charger(): void {
    if (!this.departId() || !this.arriveeId()) { this.chargement.set(false); this.trajets.set([]); return; }
    this.chargement.set(true);
    this.erreur.set('');
    this.api.rechercher({ depart: this.departId(), arrivee: this.arriveeId(), date: this.date(), passagers: this.passagers() }).subscribe({
      next: t => { this.trajets.set(t); this.chargement.set(false); },
      error: e => { this.erreur.set(e?.error?.message === 'Parametres invalides.' ? 'Vérifiez les villes et la date.' : 'Le service est momentanément indisponible.'); this.chargement.set(false); },
    });
  }

  changerDate(d: string): void {
    if (d < this.aujourdhui) return;
    this.router.navigate([], { queryParams: { date: d }, queryParamsHandling: 'merge' });
  }

  choisir(t: Trajet): void {
    this.router.navigate(['/reservation', t.id], { queryParams: { passagers: this.passagers() } });
  }

  basculer(s: typeof this.momentsChoisis, code: string): void {
    s.update(x => { const n = new Set(x); n.has(code) ? n.delete(code) : n.add(code); return n; });
  }
  reinitialiser(): void {
    this.momentsChoisis.set(new Set()); this.classesChoisies.set(new Set()); this.compagniesChoisies.set(new Set());
  }

  libelle(iso: string): string { return iso ? libelleJour(iso) : ''; }
  villeNom(id: string): string { return this.villes().find(v => v.id === id)?.nom ?? '…'; }
  classeLabel(c: string): string { return ({ standard: 'Standard', confort: 'Confort', vip: 'VIP' } as Record<string, string>)[c] ?? c; }
  equip(code: string): { label: string; icone: string } { return EQUIPEMENTS[code] ?? { label: code, icone: 'info' }; }
}
