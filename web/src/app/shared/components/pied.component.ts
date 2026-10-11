import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/api.service';
import { LignePopulaire } from '../../core/models';
import { MOBILE_MONEY } from '../../core/paiements';
import { demain } from '../../core/recherche';
import { IconComponent } from './icon/icon.component';

const VILLES_PHARES = ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Korhogo', 'Daloa'];
const LIGNES_DEFAUT = ['Abidjan - Bouaké', 'Abidjan - Yamoussoukro', 'Abidjan - San-Pédro', 'Bouaké - Korhogo', 'Abidjan - Daloa', 'Abidjan - Man'];

@Component({
  selector: 'tb-pied',
  standalone: true,
  imports: [RouterLink, IconComponent],
  template: `
    <footer class="pied">
      <div class="conteneur colonnes">
        <nav aria-label="Destinations">
          <h4>Destinations</h4>
          <a routerLink="/destinations">Toutes nos destinations</a>
          <a routerLink="/gares">Carte interactive des gares</a>
          @for (v of villes; track v) { <a routerLink="/destinations" [queryParams]="{ ville: v }">Car pour {{ v }}</a> }
        </nav>
        <nav aria-label="Lignes">
          <h4>Lignes</h4>
          @for (l of lignes(); track l.id) {
            <a routerLink="/recherche" [queryParams]="{ depart: l.depart_id, arrivee: l.arrivee_id, date: dateDemain, passagers: 1 }">{{ l.depart }} - {{ l.arrivee }}</a>
          } @empty {
            @for (l of lignesDefaut; track l) { <a routerLink="/destinations">{{ l }}</a> }
          }
        </nav>
        <nav aria-label="TamBour">
          <h4>TamBour</h4>
          <a routerLink="/infos/a-propos">À propos de TamBour</a>
          <a routerLink="/infos/conditions">Conditions générales de vente</a>
          <a routerLink="/infos/transport">Conditions de transport</a>
          <a routerLink="/compte" [queryParams]="{ onglet: 'fidelite' }">Fidélité & parrainage</a>
          <a routerLink="/infos/partenaires">Devenir compagnie partenaire</a>
          <a routerLink="/infos/chauffeurs">Devenez chauffeur TamBour</a>
        </nav>
        <nav aria-label="Service client">
          <h4>Service client</h4>
          <a routerLink="/aide">Centre d'aide</a>
          <a routerLink="/aide" fragment="contact">Contacter le service client</a>
          <a routerLink="/compte" [queryParams]="{ onglet: 'billets' }">Gérer ma réservation</a>
          <a routerLink="/infos/reserver">Comment réserver un billet de car ?</a>
          <a routerLink="/aide" fragment="reclamation">Faire une réclamation</a>
          <a routerLink="/infos/bagages">Bagages à bord</a>
        </nav>
      </div>

      <div class="conteneur milieu">
        <div>
          <h4>Application TamBour</h4>
          <div class="stores">
            <a class="store" href="#" (click)="$event.preventDefault()" aria-label="Disponible sur Google Play">
              <svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true"><path fill="#34A853" d="M3.6 1.8 13.8 12 3.6 22.2a1.6 1.6 0 0 1-.6-1.3V3.1c0-.5.2-1 .6-1.3Z"/><path fill="#FBBC04" d="m17.2 8.6-3.4 3.4 3.4 3.4 3.8-2.2c1.1-.6 1.1-1.8 0-2.4Z"/><path fill="#EA4335" d="M13.8 12 3.6 22.2c.4.3 1 .4 1.6 0l12-6.8Z"/><path fill="#4285F4" d="M3.6 1.8 13.8 12l3.4-3.4-12-6.8c-.6-.4-1.2-.3-1.6 0Z"/></svg>
              <span><small>DISPONIBLE SUR</small><b>Google Play</b></span>
            </a>
            <a class="store" href="#" (click)="$event.preventDefault()" aria-label="Télécharger dans l'App Store">
              <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true"><path fill="#fff" d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.8 1.2 1.8 2.6 3.1 2.5 1.3 0 1.7-.8 3.3-.8 1.5 0 1.9.8 3.3.8 1.4 0 2.2-1.2 3-2.5.9-1.4 1.3-2.7 1.3-2.8 0 0-2.6-1-2.7-4.1ZM13.9 4.9c.7-.8 1.2-2 1-3.1-1 0-2.2.7-2.9 1.5-.6.7-1.2 1.9-1 3 1.1.1 2.2-.6 2.9-1.4Z"/></svg>
              <span><small>Télécharger dans</small><b>l'App Store</b></span>
            </a>
          </div>
        </div>
        <div class="social">
          <h4>Rejoignez-nous sur :</h4>
          <div class="reseaux">
            @for (r of reseaux; track r.nom) {
              <a [href]="r.url" target="_blank" rel="noopener" [attr.aria-label]="r.nom"><tb-icon [name]="r.icone" [size]="18" /></a>
            }
          </div>
        </div>
      </div>

      <div class="conteneur bas">
        <a routerLink="/" class="logo" aria-label="TamBour, accueil"><img src="assets/marque/tambour-symbole-clair.svg" alt="" width="30" height="42"><span><b>TamBour</b><small>Voyagez au bon rythme</small></span></a>
        <div class="legal">
          <a routerLink="/infos/confidentialite">Confidentialité</a>
          <a routerLink="/infos/droits-passagers">Droits des passagers</a>
          <a routerLink="/infos/mentions-legales">Mentions légales</a>
          <a routerLink="/infos/cookies">Cookies</a>
        </div>
        <div class="paiements" aria-label="Moyens de paiement acceptés">
          @for (m of mobileMoney; track m.code) { <img [src]="m.logo" [alt]="m.label" [title]="m.label" width="34" height="34"> }
          <span class="carte-pay" title="Visa, Mastercard"><tb-icon name="card" [size]="18" /></span>
        </div>
        <span class="copy">© {{ annee }} TamBour · Abidjan, Côte d'Ivoire</span>
      </div>
    </footer>
  `,
  styles: [`
    .pied{background:var(--encre);color:rgba(255,255,255,.72);padding:64px 0 28px;margin-top:40px;}
    .colonnes{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:32px;}
    @media (max-width:900px){.colonnes{grid-template-columns:repeat(2,minmax(0,1fr));}}
    @media (max-width:520px){.colonnes{gap:24px 16px;} nav a{font-size:14px;padding:6px 0;}}
    h4{color:#fff;font-size:16px;font-weight:800;margin-bottom:14px;}
    nav a{display:block;padding:7px 0;font-size:15px;transition:color .15s,transform .15s;}
    nav a:hover{color:#fff;transform:translateX(2px);}
    .milieu{display:flex;justify-content:space-between;align-items:flex-end;gap:24px;flex-wrap:wrap;margin-top:44px;padding-top:32px;border-top:1px solid rgba(255,255,255,.1);}
    .stores{display:flex;gap:10px;flex-wrap:wrap;}
    .store{display:inline-flex;align-items:center;gap:10px;padding:8px 16px 8px 12px;border-radius:12px;background:#000;border:1px solid rgba(255,255,255,.25);color:#fff;transition:border-color .15s,transform .15s;}
    .store:hover{border-color:#fff;transform:translateY(-1px);}
    .store span{display:flex;flex-direction:column;line-height:1.1;}
    .store small{font-size:10px;letter-spacing:.04em;opacity:.85;}
    .store b{font-size:17px;font-weight:600;}
    .reseaux{display:flex;gap:10px;}
    .reseaux a{width:42px;height:42px;border-radius:50%;border:1.5px solid rgba(255,255,255,.35);display:flex;align-items:center;justify-content:center;color:#fff;transition:all .15s;}
    .reseaux a:hover{background:var(--or);border-color:var(--or);color:var(--encre);}
    .bas{display:flex;align-items:center;justify-content:space-between;gap:16px 24px;flex-wrap:wrap;margin-top:32px;padding-top:24px;border-top:1px solid rgba(255,255,255,.1);font-size:14px;}
    .logo{display:flex;align-items:center;gap:10px;color:#fff;}
    .logo img{height:42px;width:auto;display:block;}
    .logo span{display:flex;flex-direction:column;line-height:1.1;}
    .logo b{font-size:22px;font-weight:700;letter-spacing:-.02em;}
    .logo small{font-size:10px;letter-spacing:.22em;text-transform:uppercase;color:var(--or);font-weight:600;margin-top:3px;}
    .legal{display:flex;gap:6px 20px;flex-wrap:wrap;}
    .legal a:hover{color:#fff;}
    .paiements{display:flex;flex-wrap:wrap;gap:8px;align-items:center;}
    .paiements img{width:34px;height:34px;object-fit:contain;}
    .carte-pay{width:34px;height:34px;border-radius:9px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.2);color:#fff;display:flex;align-items:center;justify-content:center;}
    .copy{font-size:13px;opacity:.7;}
  `],
})
export class PiedComponent implements OnInit {
  private api = inject(ApiService);
  annee = new Date().getFullYear();
  dateDemain = demain();
  readonly villes = VILLES_PHARES;
  readonly mobileMoney = MOBILE_MONEY;
  readonly lignesDefaut = LIGNES_DEFAUT;
  lignes = signal<LignePopulaire[]>([]);
  readonly reseaux = [
    { nom: 'Facebook', icone: 'facebook', url: 'https://www.facebook.com/' },
    { nom: 'Instagram', icone: 'instagram', url: 'https://www.instagram.com/' },
    { nom: 'YouTube', icone: 'youtube', url: 'https://www.youtube.com/' },
    { nom: 'LinkedIn', icone: 'linkedin', url: 'https://www.linkedin.com/' },
    { nom: 'X', icone: 'xsocial', url: 'https://x.com/' },
    { nom: 'TikTok', icone: 'tiktok', url: 'https://www.tiktok.com/' },
  ];

  ngOnInit(): void {
    this.api.lignesPopulaires().subscribe({ next: l => this.lignes.set(l.slice(0, 6)), error: () => {} });
  }
}
