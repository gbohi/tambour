import { Component, OnInit, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { LignePopulaire, CategorieFAQ } from '../../core/models';
import { MOBILE_MONEY } from '../../core/paiements';
import { aujourdhui } from '../../core/recherche';
import { FormulaireRechercheComponent } from '../../shared/components/formulaire-recherche.component';
import { CarrouselBannieresComponent } from '../../shared/components/carrousel-bannieres.component';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';

@Component({
  selector: 'tb-accueil',
  standalone: true,
  imports: [RouterLink, FormulaireRechercheComponent, CarrouselBannieresComponent, IconComponent, NombrePipe],
  template: `
    <!-- ── Hero ─────────────────────────────────────────────────────────── -->
    <section class="hero">
      <svg class="routes" viewBox="0 0 1440 640" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
        <path d="M-40 520 C 240 420, 380 600, 640 480 S 1040 300, 1480 380" />
        <path d="M-40 600 C 300 520, 520 660, 820 560 S 1200 420, 1480 470" class="pointille" />
        <path d="M200 -40 C 260 160, 120 260, 300 420" class="fin" />
      </svg>
      <div class="conteneur hero-contenu">
        <span class="badge-hero"><span class="mini-logos">@for (m of mobileMoney; track m.code) { <img [src]="m.logo" [alt]="m.label" width="22" height="22"> }</span> Payez avec Orange Money, Wave, MTN MoMo ou Moov Money</span>
        <h1>Voyagez partout en<br><span>Côte d'Ivoire</span>, simplement.</h1>
        <p>Comparez les départs des meilleures compagnies, réservez en 2 minutes et embarquez avec votre billet sur le téléphone.</p>
        <tb-recherche />
        <div class="raccourcis">
          <span>Populaires :</span>
          @for (l of lignes().slice(0, 4); track l.id) {
            <a (click)="chercher(l)">{{ l.depart }} → {{ l.arrivee }}</a>
          }
        </div>
      </div>
    </section>

    <!-- ── Confiance ─────────────────────────────────────────────────────── -->
    <section class="confiance">
      <div class="conteneur grille-confiance">
        @for (a of atouts; track a.titre) {
          <div class="atout"><span class="ico"><tb-icon [name]="a.icone" [size]="22" /></span><div><b>{{ a.titre }}</b><small>{{ a.texte }}</small></div></div>
        }
      </div>
    </section>

    <!-- ── Lignes populaires ─────────────────────────────────────────────── -->
    <section class="section">
      <div class="conteneur">
        <div class="tete-section">
          <div><span class="surtitre">Destinations</span><h2 class="titre-section">Les lignes les plus demandées</h2>
            <p class="intro">Des départs tous les jours, au meilleur prix.</p></div>
          <a routerLink="/destinations" class="btn btn-blanc">Toutes les destinations <tb-icon name="arrow-right" [size]="18" /></a>
        </div>
        <div class="grille-lignes">
          @if (lignes().length === 0) { @for (i of [1,2,3,4,5,6]; track i) { <div class="squelette" style="height:150px"></div> } }
          @for (l of lignes().slice(0, 6); track l.id; let i = $index) {
            <button class="ligne" (click)="chercher(l)" [class.vedette]="i === 0">
              <div class="ligne-haut">
                <div class="villes"><span>{{ l.depart }}</span><tb-icon name="arrow-right" [size]="18" /><span>{{ l.arrivee }}</span></div>
                @if (l.est_populaire) { <span class="pastille or"><tb-icon name="trend" [size]="14" /> Populaire</span> }
              </div>
              <div class="ligne-bas">
                <div class="infos">
                  @if (l.duree_label) { <span><tb-icon name="clock" [size]="15" /> {{ l.duree_label }}</span> }
                  @if (l.trajets_par_jour) { <span><tb-icon name="bus" [size]="15" /> {{ l.trajets_par_jour }} départs/jour</span> }
                </div>
                <div class="prix">@if (l.prix_min) { <small>dès</small> {{ l.prix_min | nb:'F' }} } @else { <small>Voir les départs</small> }</div>
              </div>
            </button>
          }
        </div>
      </div>
    </section>

    <!-- ── Bannières (gérées dans l'admin) ─────────────────────────────── -->
    <section class="section section-bannieres">
      <div class="conteneur"><tb-carrousel-bannieres /></div>
    </section>

    <!-- ── Comment ça marche ────────────────────────────────────────────── -->
    <section class="section etapes-section">
      <div class="conteneur">
        <div class="centre"><span class="surtitre">Simple et rapide</span><h2 class="titre-section">Votre billet en 3 étapes</h2></div>
        <div class="etapes">
          @for (e of etapes; track e.titre; let i = $index) {
            <div class="etape"><span class="num">{{ i + 1 }}</span><span class="ico"><tb-icon [name]="e.icone" [size]="26" /></span>
              <h3>{{ e.titre }}</h3><p>{{ e.texte }}</p></div>
          }
        </div>
      </div>
    </section>

    <!-- ── Parrainage + application ─────────────────────────────────────── -->
    <section class="section">
      <div class="conteneur duo">
        <div class="bandeau parrainage">
          <span class="pastille or"><tb-icon name="gift" [size]="14" /> Programme fidélité</span>
          <h3>Parrainez vos amis,<br>gagnez des points.</h3>
          <p>Chaque ami qui s'inscrit avec votre code vous rapporte des points, et il en reçoit aussi. Vos points s'accumulent à chaque voyage.</p>
          <a [routerLink]="auth.connecte() ? '/compte' : '/connexion'" [queryParams]="auth.connecte() ? { onglet: 'fidelite' } : { mode: 'inscription' }" class="btn btn-or">
            {{ auth.connecte() ? 'Voir mon code de parrainage' : 'Créer mon compte' }} <tb-icon name="arrow-right" [size]="18" /></a>
        </div>
        <div class="bandeau appli">
          <span class="pastille"><tb-icon name="download" [size]="14" /> Application mobile</span>
          <h3>Votre billet,<br>même hors connexion.</h3>
          <p>Alertes de départ et de retard, carte des gares avec itinéraire, QR code prêt à scanner à l'embarquement.</p>
          <div class="telephone" aria-hidden="true">
            <div class="ecran"><div class="qr"></div><b>Abidjan → Bouaké</b><small>Siège 7A · 06:00</small></div>
          </div>
        </div>
      </div>
    </section>

    <!-- ── FAQ ───────────────────────────────────────────────────────────── -->
    @if (questions().length) {
      <section class="section faq-section">
        <div class="conteneur faq">
          <div><span class="surtitre">Questions fréquentes</span><h2 class="titre-section">Tout savoir avant de partir</h2>
            <p class="intro">Une autre question ? Notre équipe répond 7j/7.</p>
            <a routerLink="/aide" class="btn btn-blanc" style="margin-top:20px">Centre d'aide <tb-icon name="arrow-right" [size]="18" /></a></div>
          <div class="questions">
            @for (q of questions(); track q.question) {
              <details><summary>{{ q.question }}<tb-icon name="chevron-down" [size]="20" /></summary><p>{{ q.reponse }}</p></details>
            }
          </div>
        </div>
      </section>
    }
  `,
  styles: [`
    .section-bannieres{padding-top:0;}
    .hero{position:relative;overflow:hidden;color:#fff;padding:150px 0 110px;
      background:radial-gradient(900px 500px at 85% 10%,rgba(46,132,102,.45),transparent 60%),
                 radial-gradient(700px 400px at 0% 100%,rgba(245,166,35,.28),transparent 60%),
                 linear-gradient(165deg,#072A21 0%,#06402A 45%,#0F4A3B 100%);}
    .routes{position:absolute;inset:0;width:100%;height:100%;opacity:.35;}
    .routes path{fill:none;stroke:rgba(255,255,255,.28);stroke-width:2;}
    .routes .pointille{stroke:var(--or);stroke-dasharray:2 14;stroke-linecap:round;stroke-width:4;opacity:.8;}
    .routes .fin{stroke-width:1;}
    .hero-contenu{position:relative;}
    .badge-hero{display:inline-flex;align-items:center;gap:8px;padding:8px 14px;border-radius:999px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);font-size:14px;font-weight:600;backdrop-filter:blur(6px);}
    h1{font-size:clamp(38px,6vw,72px);line-height:1.02;font-weight:900;letter-spacing:-.045em;margin:22px 0 18px;}
    h1 span{color:var(--or);}
    .hero p{font-size:clamp(17px,1.6vw,20px);max-width:620px;opacity:.85;margin-bottom:36px;}
    .raccourcis{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin-top:52px;font-size:14px;}
    .raccourcis span{opacity:.7;}
    .raccourcis a{cursor:pointer;padding:6px 12px;border-radius:999px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);transition:background .15s;}
    .raccourcis a:hover{background:rgba(255,255,255,.2);}
    .confiance{background:#fff;border-bottom:1px solid var(--bord);}
    .grille-confiance{display:grid;grid-template-columns:repeat(4,1fr);gap:24px;padding:28px 24px;}
    @media (max-width:900px){.grille-confiance{grid-template-columns:1fr 1fr;}}
    .mini-logos{display:inline-flex;gap:4px;}
    .mini-logos img{width:22px;height:22px;object-fit:contain;}
    .atout{display:flex;align-items:center;gap:14px;}
    .atout .ico{width:48px;height:48px;border-radius:14px;background:var(--vert-clair);color:var(--vert);display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .atout b{display:block;font-size:16px;} .atout small{color:var(--texte-2);font-size:14px;}
    .tete-section{display:flex;align-items:flex-end;justify-content:space-between;gap:24px;flex-wrap:wrap;margin-bottom:36px;}
    .grille-lignes{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;}
    @media (max-width:900px){.grille-lignes{grid-template-columns:1fr 1fr;}}
    @media (max-width:600px){.grille-lignes{grid-template-columns:1fr;}}
    .ligne{display:flex;flex-direction:column;justify-content:space-between;gap:28px;text-align:left;padding:24px;border-radius:var(--r-lg);border:1px solid var(--bord);background:#fff;
      cursor:pointer;transition:transform .2s,box-shadow .2s,border-color .2s;min-height:168px;}
    .ligne:hover{transform:translateY(-4px);box-shadow:var(--ombre-2);border-color:transparent;}
    .ligne.vedette{background:linear-gradient(150deg,var(--vert-900),var(--vert));color:#fff;border:none;}
    .ligne-haut{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;}
    .villes{display:flex;align-items:center;gap:10px;font-size:21px;font-weight:800;letter-spacing:-.02em;flex-wrap:wrap;}
    .villes tb-icon{color:var(--or);}
    .ligne-bas{display:flex;justify-content:space-between;align-items:flex-end;gap:12px;}
    .infos{display:flex;flex-direction:column;gap:6px;font-size:14px;color:var(--texte-2);}
    .vedette .infos{color:rgba(255,255,255,.75);}
    .infos span{display:inline-flex;align-items:center;gap:6px;}
    .prix{font-size:24px;font-weight:900;color:var(--vert);letter-spacing:-.02em;white-space:nowrap;}
    .vedette .prix{color:var(--or);}
    .prix small{font-size:13px;font-weight:600;color:var(--texte-3);}
    .vedette .prix small{color:rgba(255,255,255,.6);}
    .etapes-section{background:#fff;}
    .centre{text-align:center;margin-bottom:48px;}
    .etapes{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;}
    @media (max-width:800px){.etapes{grid-template-columns:1fr;}}
    .etape{position:relative;padding:32px 28px;border-radius:var(--r-lg);background:var(--fond);overflow:hidden;}
    .etape .num{position:absolute;right:20px;top:4px;font-size:96px;font-weight:900;color:rgba(15,74,59,.07);line-height:1;}
    .etape .ico{width:56px;height:56px;border-radius:16px;background:#fff;color:var(--vert);display:flex;align-items:center;justify-content:center;box-shadow:var(--ombre-1);margin-bottom:20px;}
    .etape h3{font-size:20px;margin-bottom:8px;}
    .etape p{color:var(--texte-2);}
    .duo{display:grid;grid-template-columns:1fr 1fr;gap:24px;}
    @media (max-width:900px){.duo{grid-template-columns:1fr;}}
    .bandeau{position:relative;overflow:hidden;border-radius:var(--r-xl);padding:40px;min-height:340px;display:flex;flex-direction:column;align-items:flex-start;gap:16px;}
    .bandeau h3{font-size:clamp(26px,3vw,34px);line-height:1.1;font-weight:800;letter-spacing:-.03em;}
    .bandeau p{max-width:380px;}
    .parrainage{background:linear-gradient(150deg,#FFF6E3,#FFE7B8);color:var(--encre);}
    .parrainage p{color:#5E4A1E;}
    .appli{background:linear-gradient(150deg,var(--encre),#0B3A2E);color:#fff;}
    .appli p{color:rgba(255,255,255,.75);max-width:300px;}
    .appli{padding-right:240px;}
    .appli .pastille{background:rgba(255,255,255,.1);color:#fff;}
    .telephone{position:absolute;right:36px;bottom:-60px;width:170px;height:300px;border-radius:32px;background:#0E1512;border:6px solid #2A3631;
      box-shadow:var(--ombre-3);animation:flotte 6s ease-in-out infinite;}
    .ecran{position:absolute;inset:10px;border-radius:22px;background:#fff;color:var(--encre);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;}
    .qr{width:96px;height:96px;border-radius:10px;background:
      conic-gradient(from 90deg at 25% 25%,#000 25%,transparent 0) 0 0/24px 24px,
      repeating-linear-gradient(45deg,#000 0 4px,transparent 4px 9px);opacity:.85;}
    .ecran b{font-size:13px;} .ecran small{font-size:11px;color:var(--texte-2);}
    @media (max-width:560px){.telephone{display:none;}.bandeau,.appli{padding:28px;}}
    .faq-section{background:#fff;}
    .faq{display:grid;grid-template-columns:1fr 1.3fr;gap:48px;}
    @media (max-width:900px){.faq{grid-template-columns:1fr;}}
    .questions{display:flex;flex-direction:column;gap:10px;}
    details{border:1px solid var(--bord);border-radius:var(--r);background:var(--fond);overflow:hidden;}
    details[open]{background:#fff;box-shadow:var(--ombre-1);}
    summary{list-style:none;cursor:pointer;padding:18px 20px;font-weight:700;display:flex;justify-content:space-between;align-items:center;gap:16px;}
    summary::-webkit-details-marker{display:none;}
    details[open] summary tb-icon{transform:rotate(180deg);}
    summary tb-icon{transition:transform .2s;color:var(--texte-3);}
    details p{padding:0 20px 18px;color:var(--texte-2);}
  `],
})
export class AccueilComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private router = inject(Router);
  lignes = signal<LignePopulaire[]>([]);
  questions = signal<{ question: string; reponse: string }[]>([]);

  readonly mobileMoney = MOBILE_MONEY;
  readonly atouts = [
    { icone: 'wallet', titre: 'Mobile Money', texte: 'Orange, Wave, MTN, Moov ou carte' },
    { icone: 'qr', titre: 'Billet sur mobile', texte: 'QR code, pas d\'impression' },
    { icone: 'seat', titre: 'Siège garanti', texte: 'Attribué dès le paiement validé' },
    { icone: 'headset', titre: 'Support 7j/7', texte: 'Par téléphone et WhatsApp' },
  ];
  readonly etapes = [
    { icone: 'search', titre: 'Cherchez votre trajet', texte: 'Comparez horaires, prix, confort et avis des compagnies partenaires.' },
    { icone: 'wallet', titre: 'Payez en toute sécurité', texte: 'Mobile Money ou carte bancaire : la confirmation est immédiate.' },
    { icone: 'qr', titre: 'Embarquez', texte: 'Présentez le QR code de votre billet au chauffeur. Bon voyage !' },
  ];

  ngOnInit(): void {
    this.api.lignesPopulaires().subscribe({ next: l => this.lignes.set(l), error: () => {} });
    this.api.faq().subscribe({
      next: (cats: CategorieFAQ[]) => this.questions.set(cats.flatMap(c => c.questions).slice(0, 5)), error: () => {},
    });
  }

  chercher(l: LignePopulaire): void {
    this.router.navigate(['/recherche'], { queryParams: { depart: l.depart_id, arrivee: l.arrivee_id, date: aujourdhui(), passagers: 1 } });
  }
}
