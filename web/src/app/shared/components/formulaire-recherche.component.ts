import { Component, ElementRef, HostListener, Input, OnInit, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { NgTemplateOutlet } from '@angular/common';
import { VillesService } from '../../core/villes.service';
import { Ville } from '../../core/models';
import { demain, isoJour } from '../../core/recherche';
import { IconComponent } from './icon/icon.component';

type Champ = 'depart' | 'arrivee' | 'passagers' | null;

@Component({
  selector: 'tb-recherche',
  standalone: true,
  imports: [FormsModule, NgTemplateOutlet, IconComponent],
  template: `
    <form class="recherche" [class.compact]="compact" (ngSubmit)="rechercher()">
      <div class="trajet">
        <div class="bloc" [class.ouvert]="ouvert() === 'depart'" (click)="$event.stopPropagation(); ouvrir('depart')">
          <tb-icon name="map-pin" [size]="20" class="pict" />
          <div class="valeur">
            <label>Départ</label>
            @if (ouvert() === 'depart') {
              <input class="saisie" [ngModel]="filtre()" (ngModelChange)="filtre.set($event)" name="fd" placeholder="Ville de départ" autocomplete="off" (keydown.enter)="$event.preventDefault(); choisirPremier('depart')">
            } @else { <span [class.placeholder]="!depart()">{{ depart()?.nom ?? 'Ville de départ' }}</span> }
          </div>
          @if (ouvert() === 'depart') { <ng-container *ngTemplateOutlet="liste; context: { champ: 'depart' }" /> }
        </div>
        <button type="button" class="inverser" (click)="$event.stopPropagation(); inverser()" aria-label="Inverser départ et arrivée"><tb-icon name="swap" [size]="18" /></button>
        <div class="bloc" [class.ouvert]="ouvert() === 'arrivee'" (click)="$event.stopPropagation(); ouvrir('arrivee')">
          <tb-icon name="map-pin" [size]="20" class="pict or" />
          <div class="valeur">
            <label>Arrivée</label>
            @if (ouvert() === 'arrivee') {
              <input class="saisie" [ngModel]="filtre()" (ngModelChange)="filtre.set($event)" name="fa" placeholder="Ville d'arrivée" autocomplete="off" (keydown.enter)="$event.preventDefault(); choisirPremier('arrivee')">
            } @else { <span [class.placeholder]="!arrivee()">{{ arrivee()?.nom ?? "Ville d'arrivée" }}</span> }
          </div>
          @if (ouvert() === 'arrivee') { <ng-container *ngTemplateOutlet="liste; context: { champ: 'arrivee' }" /> }
        </div>
      </div>

      <label class="bloc date">
        <tb-icon name="calendar" [size]="20" class="pict" />
        <div class="valeur">
          <label>Date</label>
          <input type="date" class="saisie" [min]="aujourdhui" [(ngModel)]="date" name="date" required>
        </div>
      </label>

      <div class="bloc pax" [class.ouvert]="ouvert() === 'passagers'" (click)="$event.stopPropagation(); ouvrir('passagers')">
        <tb-icon name="users" [size]="20" class="pict" />
        <div class="valeur"><label>Passagers</label><span>{{ passagers }} passager{{ passagers > 1 ? 's' : '' }}</span></div>
        @if (ouvert() === 'passagers') {
          <div class="menu pax-menu" (click)="$event.stopPropagation()">
            <div class="compteur">
              <div><b>Passagers</b><small>9 maximum par réservation</small></div>
              <button type="button" (click)="passagers = max1(passagers - 1)" [disabled]="passagers <= 1" aria-label="Moins">−</button>
              <span>{{ passagers }}</span>
              <button type="button" (click)="passagers = min9(passagers + 1)" [disabled]="passagers >= 9" aria-label="Plus">+</button>
            </div>
            <button type="button" class="btn btn-primaire btn-sm btn-bloc" (click)="ouvert.set(null)">Valider</button>
          </div>
        }
      </div>

      <button type="submit" class="btn btn-or lancer"><tb-icon name="search" [size]="20" /> <span>Rechercher</span></button>

      <ng-template #liste let-champ="champ">
        <div class="menu" (click)="$event.stopPropagation()">
          @for (v of proposees(); track v.id) {
            <button type="button" class="option" (click)="choisir(champ, v)">
              <tb-icon name="map-pin" [size]="16" /><span><b>{{ v.nom }}</b><small>{{ v.region }}</small></span>
            </button>
          } @empty { <div class="aucune">Aucune ville trouvée</div> }
        </div>
      </ng-template>
      @if (erreur()) { <div class="erreur">{{ erreur() }}</div> }
    </form>
  `,
  styles: [`
    .recherche{position:relative;color:var(--texte);text-align:left;display:grid;grid-template-columns:minmax(0,2.3fr) minmax(0,1fr) minmax(0,1fr) auto;min-width:0;gap:8px;background:#fff;padding:8px;border-radius:24px;box-shadow:var(--ombre-3);}
    .trajet{position:relative;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:8px;min-width:0;}
    .bloc,.valeur{min-width:0;}
    .bloc{position:relative;display:flex;align-items:center;gap:12px;padding:12px 16px;border-radius:18px;background:var(--surface-2);cursor:pointer;min-height:68px;transition:background .15s,box-shadow .15s;}
    .bloc:hover{background:#E9EEEB;}
    .bloc.ouvert{background:#fff;box-shadow:0 0 0 2px var(--vert);}
    .pict{color:var(--vert);flex-shrink:0;} .pict.or{color:var(--or-fonce);}
    .valeur{display:flex;flex-direction:column;justify-content:center;min-width:0;flex:1;min-height:44px;}
    .valeur label{font-size:12px;font-weight:700;color:var(--texte-3);text-transform:uppercase;letter-spacing:.06em;cursor:pointer;}
    .valeur span{font-size:17px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .valeur span.placeholder{color:var(--texte-3);font-weight:500;}
    .saisie{border:none;outline:none;background:transparent;font-size:17px;font-weight:700;width:100%;padding:0;min-width:0;height:26px;line-height:26px;color:var(--texte);}
    input[type=date].saisie{cursor:pointer;}
    .inverser{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);z-index:2;width:38px;height:38px;border-radius:50%;border:4px solid #fff;
      background:var(--vert);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;transition:transform .25s;}
    .inverser:hover{transform:translate(-50%,-50%) rotate(180deg);}
    .lancer{height:auto;min-height:68px;border-radius:18px;padding:0 28px;font-size:17px;}
    .menu{position:absolute;top:calc(100% + 10px);left:0;min-width:100%;width:max-content;max-width:360px;max-height:320px;overflow-y:auto;background:#fff;border-radius:18px;
      box-shadow:var(--ombre-3);padding:8px;z-index:50;cursor:default;animation:monte .18s;}
    .option{display:flex;align-items:center;gap:12px;width:100%;padding:10px 12px;border:none;background:none;border-radius:12px;cursor:pointer;text-align:left;color:var(--texte-2);}
    .option:hover{background:var(--vert-clair);color:var(--vert);}
    .option span{display:flex;flex-direction:column;}
    .option b{color:var(--texte);font-size:16px;}
    .option small{font-size:13px;color:var(--texte-3);}
    .aucune{padding:16px;color:var(--texte-3);}
    .pax-menu{width:300px;display:flex;flex-direction:column;gap:12px;padding:16px;right:0;left:auto;}
    .compteur{display:flex;align-items:center;gap:12px;}
    .compteur div{flex:1;display:flex;flex-direction:column;}
    .compteur small{font-size:12px;color:var(--texte-3);}
    .compteur button{width:38px;height:38px;border-radius:50%;border:1px solid var(--bord);background:#fff;font-size:20px;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;}
    .compteur button:disabled{opacity:.4;cursor:not-allowed;}
    .compteur > span{min-width:20px;text-align:center;font-weight:800;font-size:18px;}
    .erreur{position:absolute;left:16px;bottom:-34px;font-size:14px;font-weight:600;color:#fff;background:var(--danger);padding:4px 12px;border-radius:8px;}
    .compact{box-shadow:var(--ombre-2);border-radius:20px;}
    .compact .bloc,.compact .lancer{min-height:58px;}
    @media (max-width:980px){
      .recherche{grid-template-columns:minmax(0,1fr) minmax(0,1fr);}
      .trajet{grid-column:1/-1;}
      .lancer{grid-column:1/-1;min-height:58px;}
    }
    @media (max-width:560px){
      .trajet{grid-template-columns:minmax(0,1fr);}
      .bloc{padding:10px 12px;gap:10px;}
      .saisie,.valeur span{font-size:16px;}
      .inverser{left:auto;right:18px;transform:translateY(-50%) rotate(90deg);}
      .inverser:hover{transform:translateY(-50%) rotate(270deg);}
      .recherche{grid-template-columns:minmax(0,1fr) minmax(0,1fr);}
      .menu{max-width:calc(100vw - 48px);}
      .pax-menu{width:260px;}
    }
  `],
})
export class FormulaireRechercheComponent implements OnInit {
  @Input() compact = false;
  @Input() departId?: string;
  @Input() arriveeId?: string;
  @Input() dateInitiale?: string;
  @Input() passagersInitial?: number;

  private router = inject(Router);
  private hote = inject(ElementRef);
  private villesService = inject(VillesService);

  villes = signal<Ville[]>([]);
  depart = signal<Ville | null>(null);
  arrivee = signal<Ville | null>(null);
  ouvert = signal<Champ>(null);
  erreur = signal('');
  filtre = signal('');
  date = demain();
  passagers = 1;
  aujourdhui = isoJour(new Date());

  proposees = computed(() => {
    const c = this.ouvert();
    return c === 'depart' || c === 'arrivee' ? this.filtrees(c) : [];
  });

  ngOnInit(): void {
    if (this.dateInitiale) this.date = this.dateInitiale < this.aujourdhui ? this.aujourdhui : this.dateInitiale;
    if (this.passagersInitial) this.passagers = this.passagersInitial;
    this.villesService.villes$.subscribe(v => {
      this.villes.set(v);
      this.depart.set(v.find(x => x.id === this.departId) ?? (this.departId ? null : v.find(x => x.nom === 'Abidjan') ?? null));
      this.arrivee.set(v.find(x => x.id === this.arriveeId) ?? null);
    });
  }

  /** Villes filtrées par la saisie (hors ville déjà choisie de l'autre côté). */
  filtrees(champ: 'depart' | 'arrivee'): Ville[] {
    const q = this.normaliser(this.filtre());
    const exclue = champ === 'depart' ? this.arrivee()?.id : this.depart()?.id;
    return this.villes().filter(v => v.id !== exclue && (!q || this.normaliser(v.nom + ' ' + v.region).includes(q)));
  }

  ouvrir(c: Champ): void {
    if (this.ouvert() === c) return;
    this.filtre.set('');
    this.erreur.set('');
    this.ouvert.set(c);
    if (c === 'depart' || c === 'arrivee') {
      setTimeout(() => (this.hote.nativeElement as HTMLElement).querySelector<HTMLInputElement>('input.saisie:not([type=date])')?.focus());
    }
  }

  choisir(champ: 'depart' | 'arrivee', v: Ville): void {
    (champ === 'depart' ? this.depart : this.arrivee).set(v);
    this.filtre.set('');
    // Enchaîne naturellement sur le champ suivant
    this.ouvert.set(null);
    if (champ === 'depart' && !this.arrivee()) setTimeout(() => this.ouvrir('arrivee'));
  }

  choisirPremier(champ: 'depart' | 'arrivee'): void {
    const v = this.filtrees(champ)[0];
    if (v) this.choisir(champ, v);
  }

  inverser(): void {
    const d = this.depart();
    this.depart.set(this.arrivee());
    this.arrivee.set(d);
  }

  max1(n: number): number { return Math.max(1, n); }
  min9(n: number): number { return Math.min(9, n); }

  rechercher(): void {
    this.ouvert.set(null);
    if (!this.depart() || !this.arrivee()) { this.erreur.set('Choisissez votre ville de départ et d\'arrivée.'); return; }
    if (!this.date) this.date = demain();
    this.router.navigate(['/recherche'], { queryParams: {
      depart: this.depart()!.id, arrivee: this.arrivee()!.id, date: this.date, passagers: this.passagers } });
  }

  // Ferme les menus au clic en dehors
  @HostListener('document:click', ['$event']) clicDehors(e: MouseEvent): void {
    if (!(this.hote.nativeElement as HTMLElement).contains(e.target as Node)) this.ouvert.set(null);
  }

  private normaliser(s: string): string { return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim(); }

}
