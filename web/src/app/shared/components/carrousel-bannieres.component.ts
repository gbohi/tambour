import { Component, OnDestroy, OnInit, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { ApiService } from '../../core/api.service';
import { Banniere } from '../../core/models';
import { aujourdhui } from '../../core/recherche';
import { IconComponent } from './icon/icon.component';

/** Pages du site ouvertes par l'action « page » d'une bannière. */
const PAGES: Record<string, string> = { fidelite: '/compte', gares: '/gares', lignes: '/destinations', aide: '/aide' };

/**
 * Carrousel d'images de l'accueil. Contenu, ordre et dates de diffusion sont gérés
 * dans l'administration (Plateforme › Bannières) ; rien n'est affiché sans bannière active.
 */
@Component({
  selector: 'tb-carrousel-bannieres',
  standalone: true,
  imports: [IconComponent],
  template: `
    @if (bannieres().length) {
      <div class="carrousel" (mouseenter)="pause = true" (mouseleave)="pause = false">
        <div class="piste" [style.transform]="'translateX(-' + index() * 100 + '%)'">
          @for (b of bannieres(); track b.id) {
            <button class="diapo" [style.background-color]="b.couleur_fond" [class.cliquable]="b.action !== 'aucune'"
                    (click)="ouvrir(b)" [attr.aria-label]="b.titre || 'Bannière'">
              @if (b.image_url) { <img [src]="b.image_url" [alt]="b.titre" loading="lazy"> }
              @if (b.titre || b.sous_titre) {
                <div class="texte">
                  @if (b.titre) { <h3>{{ b.titre }}</h3> }
                  @if (b.sous_titre) { <p>{{ b.sous_titre }}</p> }
                  @if (b.texte_bouton && b.action !== 'aucune') { <span class="bouton">{{ b.texte_bouton }} <tb-icon name="arrow-right" [size]="16" /></span> }
                </div>
              }
            </button>
          }
        </div>
        @if (bannieres().length > 1) {
          <button class="fleche g" (click)="aller(index() - 1)" aria-label="Précédente"><tb-icon name="chevron-left" /></button>
          <button class="fleche d" (click)="aller(index() + 1)" aria-label="Suivante"><tb-icon name="chevron-right" /></button>
          <div class="points">
            @for (b of bannieres(); track b.id; let i = $index) {
              <button [class.actif]="i === index()" (click)="aller(i)" [attr.aria-label]="'Bannière ' + (i + 1)"></button>
            }
          </div>
        }
      </div>
    }
  `,
  styles: [`
    .carrousel{position:relative;border-radius:24px;overflow:hidden;box-shadow:0 12px 32px rgba(7,42,33,.12);}
    .piste{display:flex;transition:transform .55s cubic-bezier(.4,0,.2,1);}
    .diapo{position:relative;flex:0 0 100%;aspect-ratio:16/5;min-height:220px;border:0;padding:0;cursor:default;overflow:hidden;text-align:left;font:inherit;}
    .diapo.cliquable{cursor:pointer;}
    .diapo img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;transition:transform .6s;}
    .diapo.cliquable:hover img{transform:scale(1.03);}
    .texte{position:absolute;inset:0;display:flex;flex-direction:column;justify-content:flex-end;gap:8px;padding:32px 40px;
      background:linear-gradient(90deg,rgba(7,42,33,.82) 0%,rgba(7,42,33,.35) 55%,rgba(7,42,33,0) 85%);color:#fff;}
    .texte h3{font-size:clamp(22px,3vw,34px);font-weight:900;line-height:1.1;max-width:560px;margin:0;}
    .texte p{font-size:16px;opacity:.92;max-width:520px;margin:0;}
    .bouton{align-self:flex-start;display:inline-flex;align-items:center;gap:6px;margin-top:6px;background:var(--or);color:var(--vert-900);
      font-weight:800;font-size:14px;padding:9px 16px;border-radius:999px;}
    .fleche{position:absolute;top:50%;transform:translateY(-50%);width:42px;height:42px;border-radius:50%;border:0;background:rgba(255,255,255,.9);
      color:var(--vert);display:grid;place-items:center;cursor:pointer;box-shadow:0 4px 12px rgba(0,0,0,.15);}
    .fleche.g{left:14px;} .fleche.d{right:14px;}
    .points{position:absolute;bottom:14px;right:20px;display:flex;gap:6px;}
    .points button{width:8px;height:8px;border-radius:4px;border:0;background:rgba(255,255,255,.55);cursor:pointer;transition:width .25s;padding:0;}
    .points button.actif{width:22px;background:#fff;}
    @media (max-width:640px){
      .diapo{aspect-ratio:auto;height:220px;}
      .texte{padding:20px 22px 34px;}
      .texte p{font-size:14px;}
      .fleche{display:none;}
      .points{left:0;right:0;justify-content:center;}
    }
  `],
})
export class CarrouselBannieresComponent implements OnInit, OnDestroy {
  private api = inject(ApiService);
  private router = inject(Router);
  bannieres = signal<Banniere[]>([]);
  index = signal(0);
  pause = false;
  private minuteur?: ReturnType<typeof setInterval>;

  ngOnInit(): void {
    this.api.bannieres().subscribe({ next: b => this.bannieres.set(b), error: () => {} });
    this.minuteur = setInterval(() => { if (!this.pause && this.bannieres().length > 1) this.aller(this.index() + 1); }, 6000);
  }

  ngOnDestroy(): void { clearInterval(this.minuteur); }

  aller(i: number): void {
    const n = this.bannieres().length;
    this.index.set(((i % n) + n) % n);
  }

  ouvrir(b: Banniere): void {
    if (b.action === 'recherche' && b.depart && b.arrivee) {
      this.router.navigate(['/recherche'], { queryParams: { depart: b.depart, arrivee: b.arrivee, date: aujourdhui(), passagers: 1 } });
    } else if (b.action === 'page' && PAGES[b.page]) {
      this.router.navigateByUrl(PAGES[b.page]);
    } else if (b.action === 'lien' && b.lien) {
      window.open(b.lien, '_blank', 'noopener');
    }
  }
}
