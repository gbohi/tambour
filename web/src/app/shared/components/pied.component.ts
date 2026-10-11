import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { IconComponent } from './icon/icon.component';

@Component({
  selector: 'tb-pied',
  standalone: true,
  imports: [RouterLink, IconComponent],
  template: `
    <footer class="pied">
      <div class="conteneur grille">
        <div class="marque">
          <a routerLink="/" class="logo"><span class="pict"><tb-icon name="bus" [size]="18" [stroke]="2.3" /></span>Tam<b>Bour</b></a>
          <p>Les billets de car de Côte d'Ivoire, en quelques clics. Payez par Mobile Money, voyagez avec votre billet sur le téléphone.</p>
          <div class="paiements">
            <span style="--c:#FF7900">Orange Money</span><span style="--c:#FFCB05">MTN MoMo</span><span style="--c:#1DC8F2">Wave</span><span style="--c:#9FB3FF">Visa / Mastercard</span>
          </div>
        </div>
        <div>
          <h4>Voyager</h4>
          <a routerLink="/destinations">Toutes les destinations</a>
          <a routerLink="/gares">Nos gares</a>
          <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }">Mes billets</a>
          <a routerLink="/compte" [queryParams]="{ onglet: 'fidelite' }">Fidélité & parrainage</a>
        </div>
        <div>
          <h4>Besoin d'aide ?</h4>
          <a routerLink="/aide">Centre d'aide</a>
          <a routerLink="/aide" fragment="contact">Contacter le support</a>
          <a routerLink="/aide" fragment="reclamation">Faire une réclamation</a>
        </div>
        <div>
          <h4>L'application</h4>
          <p class="app">Votre billet hors connexion, les alertes de départ et la carte des gares.</p>
          <div class="stores"><span><tb-icon name="download" [size]="16" /> Android</span><span><tb-icon name="download" [size]="16" /> iPhone</span></div>
        </div>
      </div>
      <div class="conteneur bas"><span>© {{ annee }} TamBour · Abidjan, Côte d'Ivoire</span><span>Conditions · Confidentialité · Mentions légales</span></div>
    </footer>
  `,
  styles: [`
    .pied{background:var(--encre);color:rgba(255,255,255,.7);padding:72px 0 28px;margin-top:40px;}
    .grille{display:grid;grid-template-columns:1.5fr 1fr 1fr 1.2fr;gap:40px;}
    @media (max-width:900px){.grille{grid-template-columns:1fr 1fr;}}
    @media (max-width:560px){.grille{grid-template-columns:1fr;}}
    .logo{display:inline-flex;align-items:center;gap:10px;font-size:22px;font-weight:800;color:#fff;letter-spacing:-.03em;margin-bottom:16px;}
    .logo b{color:var(--or);}
    .pict{width:34px;height:34px;border-radius:10px;background:var(--vert);display:flex;align-items:center;justify-content:center;}
    .marque p{font-size:15px;max-width:340px;}
    .paiements{display:flex;flex-wrap:wrap;gap:8px;margin-top:18px;}
    .paiements span{font-size:12px;font-weight:700;padding:6px 10px;border-radius:8px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);color:var(--c);}
    h4{color:#fff;font-size:15px;margin-bottom:14px;}
    .grille > div > a{display:block;padding:6px 0;font-size:15px;transition:color .15s;}
    .grille > div > a:hover{color:#fff;}
    .app{font-size:15px;margin-bottom:14px;}
    .stores{display:flex;gap:8px;flex-wrap:wrap;}
    .stores span{display:inline-flex;align-items:center;gap:8px;padding:10px 14px;border-radius:12px;background:rgba(255,255,255,.08);color:#fff;font-weight:600;font-size:14px;}
    .bas{display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;border-top:1px solid rgba(255,255,255,.1);margin-top:48px;padding-top:24px;font-size:13px;}
  `],
})
export class PiedComponent { annee = new Date().getFullYear(); }
