import { Component, OnInit, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { Ville } from '../../core/models/transport.model';
import { ActionBanniere, Banniere, PageBanniere } from '../../core/models/plateforme.model';

interface BanniereForm {
  titre: string; sous_titre: string; couleur_fond: string; texte_bouton: string;
  action: ActionBanniere; depart: string; arrivee: string; page: PageBanniere; lien: string;
  ordre: number; est_active: boolean; debut: string; fin: string;
}

const ACTIONS: { code: ActionBanniere; label: string }[] = [
  { code: 'aucune', label: 'Aucune (visuel seul)' },
  { code: 'recherche', label: 'Lancer une recherche de trajet' },
  { code: 'page', label: "Ouvrir une page de l'application" },
  { code: 'lien', label: 'Ouvrir un lien externe' },
];
const PAGES: { code: PageBanniere; label: string }[] = [
  { code: 'fidelite', label: 'Fidélité et parrainage' }, { code: 'gares', label: 'Gares' },
  { code: 'lignes', label: 'Lignes populaires' }, { code: 'aide', label: "Centre d'aide" },
];

/** Bannières du carrousel d'accueil de l'application voyageurs et du site. */
@Component({
  selector: 'app-bannieres',
  standalone: true,
  imports: [DatePipe, FormsModule, IconComponent],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Bannières</h1>
          <p class="page-subtitle">Carrousel d'images de l'accueil, affiché après « Lignes populaires » dans l'application et sur le site</p></div>
        <button class="btn btn-primary" (click)="ouvrirCreer()"><tb-icon name="plus" [size]="18" /> Ajouter une bannière</button>
      </div>

      @if (chargement()) { <div class="card"><div class="loading-row"><span class="spinner"></span></div></div> }
      @else {
        <div class="grille">
          @for (b of bannieres(); track b.id) {
            <div class="carte" [class.inactive]="!b.est_active">
              <div class="visuel" [style.background-color]="b.couleur_fond">
                @if (b.image_url) { <img [src]="b.image_url" [alt]="b.titre"> }
                @else { <div class="sans-image"><tb-icon name="image" [size]="28" /></div> }
                <span class="ordre">#{{ b.ordre }}</span>
              </div>
              <div class="corps">
                <div class="haut">
                  <b class="titre">{{ b.titre || 'Sans titre' }}</b>
                  <span class="badge" [class]="'badge ' + statut(b).classe">{{ statut(b).label }}</span>
                </div>
                @if (b.sous_titre) { <p class="sous">{{ b.sous_titre }}</p> }
                <p class="action"><tb-icon name="arrow-right" [size]="14" /> {{ libelleAction(b) }}</p>
                @if (b.debut || b.fin) {
                  <p class="dates"><tb-icon name="calendar" [size]="14" />
                    @if (b.debut) { du {{ b.debut | date:'dd/MM/yyyy HH:mm' }} } @if (b.fin) { au {{ b.fin | date:'dd/MM/yyyy HH:mm' }} }</p>
                }
                <div class="outils">
                  <label class="interrupteur" data-tip="Afficher / masquer">
                    <input type="checkbox" [checked]="b.est_active" (change)="basculer(b)"><span></span>
                  </label>
                  <span class="espace"></span>
                  <button class="icon-btn" data-tip="Monter" (click)="deplacer(b, -1)" [disabled]="$first"><tb-icon name="chevron-left" [size]="16" style="transform:rotate(90deg)" /></button>
                  <button class="icon-btn" data-tip="Descendre" (click)="deplacer(b, 1)" [disabled]="$last"><tb-icon name="chevron-down" [size]="16" /></button>
                  <button class="icon-btn" data-tip="Modifier" (click)="ouvrirModifier(b)"><tb-icon name="edit" /></button>
                  <button class="icon-btn danger" data-tip="Supprimer" (click)="supprimer(b)"><tb-icon name="trash" /></button>
                </div>
              </div>
            </div>
          } @empty {
            <div class="card empty-state"><div class="empty-icon"><tb-icon name="image" [size]="26" /></div>
              <h3>Aucune bannière</h3><p>Le carrousel est masqué tant qu'aucune bannière n'est active.</p></div>
          }
        </div>
      }
    </div>

    @if (formulaire()) {
      <div class="modal-backdrop" (click)="formulaire.set(false)">
        <div class="modal" style="max-width:640px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div class="modal-title">{{ edition() ? 'Modifier la bannière' : 'Nouvelle bannière' }}</div>
            <button class="modal-close" (click)="formulaire.set(false)"><tb-icon name="x" /></button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Image <span class="form-hint">(paysage, 1600 × 500 px conseillé, JPG ou PNG)</span></label>
              <label class="depot" [style.background-color]="form.couleur_fond">
                @if (apercuImage()) { <img [src]="apercuImage()" alt=""> }
                @else { <span><tb-icon name="image" [size]="22" /> Choisir une image</span> }
                <input type="file" accept="image/*" (change)="choisirImage($event)">
              </label>
            </div>
            <div class="form-group"><label class="form-label">Titre <span class="form-hint">(facultatif, affiché sur l'image)</span></label>
              <input class="form-control" [(ngModel)]="form.titre" maxlength="80" placeholder="Ex. : Abidjan → Yamoussoukro"></div>
            <div class="form-group"><label class="form-label">Sous-titre</label>
              <input class="form-control" [(ngModel)]="form.sous_titre" maxlength="140" placeholder="Ex. : Dès 2 600 F, départs toute la journée"></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Texte du bouton</label>
                <input class="form-control" [(ngModel)]="form.texte_bouton" maxlength="30" placeholder="Ex. : Voir les départs"></div>
              <div class="form-group"><label class="form-label">Couleur de fond</label>
                <div class="couleur"><input type="color" [(ngModel)]="form.couleur_fond"><input class="form-control" [(ngModel)]="form.couleur_fond" maxlength="7"></div></div>
            </div>
            <div class="form-group"><label class="form-label">Au toucher</label>
              <select class="form-control" [(ngModel)]="form.action">
                @for (a of actions; track a.code) { <option [value]="a.code">{{ a.label }}</option> }
              </select></div>
            @if (form.action === 'recherche') {
              <div class="form-row">
                <div class="form-group"><label class="form-label">Départ</label>
                  <select class="form-control" [(ngModel)]="form.depart"><option value="">Choisir…</option>
                    @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }</select></div>
                <div class="form-group"><label class="form-label">Arrivée</label>
                  <select class="form-control" [(ngModel)]="form.arrivee"><option value="">Choisir…</option>
                    @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }</select></div>
              </div>
            }
            @if (form.action === 'page') {
              <div class="form-group"><label class="form-label">Page</label>
                <select class="form-control" [(ngModel)]="form.page"><option value="">Choisir…</option>
                  @for (p of pages; track p.code) { <option [value]="p.code">{{ p.label }}</option> }</select></div>
            }
            @if (form.action === 'lien') {
              <div class="form-group"><label class="form-label">Lien</label>
                <input class="form-control" type="url" [(ngModel)]="form.lien" placeholder="https://…"></div>
            }
            <div class="form-row trois">
              <div class="form-group"><label class="form-label">Ordre</label>
                <input class="form-control" type="number" min="0" [(ngModel)]="form.ordre"></div>
              <div class="form-group"><label class="form-label">Début <span class="form-hint">(facultatif)</span></label>
                <input class="form-control" type="datetime-local" [(ngModel)]="form.debut"></div>
              <div class="form-group"><label class="form-label">Fin <span class="form-hint">(facultatif)</span></label>
                <input class="form-control" type="datetime-local" [(ngModel)]="form.fin"></div>
            </div>
            <label class="case"><input type="checkbox" [(ngModel)]="form.est_active"> Bannière active</label>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="formulaire.set(false)">Annuler</button>
            <button class="btn btn-primary" (click)="enregistrer()" [disabled]="envoi()">
              @if (envoi()) { <span class="spinner"></span> } {{ edition() ? 'Enregistrer' : 'Créer la bannière' }}</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .grille{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:18px;}
    .grille > .empty-state{grid-column:1/-1;}
    .carte{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-lg);overflow:hidden;box-shadow:var(--shadow-xs);display:flex;flex-direction:column;}
    .carte.inactive .visuel{filter:grayscale(.8);opacity:.6;}
    .visuel{position:relative;aspect-ratio:16/5;min-height:110px;}
    .visuel img{width:100%;height:100%;object-fit:cover;display:block;}
    .sans-image{position:absolute;inset:0;display:grid;place-items:center;color:rgba(255,255,255,.7);}
    .ordre{position:absolute;top:10px;left:10px;background:rgba(0,0,0,.55);color:#fff;font-size:12px;font-weight:700;padding:2px 8px;border-radius:999px;}
    .corps{padding:14px 16px;display:flex;flex-direction:column;gap:6px;flex:1;}
    .haut{display:flex;justify-content:space-between;gap:10px;align-items:flex-start;}
    .titre{font-size:15px;}
    .sous{font-size:13px;color:var(--text-2);margin:0;}
    .action,.dates{display:flex;align-items:center;gap:6px;font-size:12px;color:var(--text-3);margin:0;}
    .outils{display:flex;align-items:center;gap:4px;margin-top:auto;padding-top:8px;}
    .espace{flex:1;}
    .icon-btn.danger:hover{color:var(--error);}
    .interrupteur{position:relative;display:inline-block;width:38px;height:22px;cursor:pointer;}
    .interrupteur input{opacity:0;width:0;height:0;}
    .interrupteur span{position:absolute;inset:0;border-radius:999px;background:var(--border);transition:.2s;}
    .interrupteur span::after{content:'';position:absolute;left:3px;top:3px;width:16px;height:16px;border-radius:50%;background:#fff;transition:.2s;}
    .interrupteur input:checked + span{background:var(--primary);}
    .interrupteur input:checked + span::after{transform:translateX(16px);}
    .depot{position:relative;display:grid;place-items:center;aspect-ratio:16/5;border-radius:12px;overflow:hidden;cursor:pointer;color:#fff;border:1.5px dashed var(--border);}
    .depot img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;}
    .depot span{display:flex;gap:8px;align-items:center;font-weight:600;}
    .depot input{position:absolute;inset:0;opacity:0;cursor:pointer;}
    .couleur{display:flex;gap:8px;align-items:center;}
    .couleur input[type=color]{width:44px;height:40px;border:1px solid var(--border);border-radius:10px;padding:2px;background:var(--surface);}
    .form-row.trois{grid-template-columns:90px 1fr 1fr;}
    @media (max-width:640px){.form-row.trois{grid-template-columns:1fr;}}
    .case{display:inline-flex;align-items:center;gap:8px;font-size:14px;color:var(--text-2);cursor:pointer;}
    .case input{accent-color:var(--primary);width:16px;height:16px;}
  `],
})
export class BannieresComponent implements OnInit {
  private api = inject(ApiService);
  private toast = inject(ToastService);
  readonly actions = ACTIONS;
  readonly pages = PAGES;
  bannieres = signal<Banniere[]>([]);
  villes = signal<Ville[]>([]);
  chargement = signal(true);
  formulaire = signal(false);
  edition = signal<Banniere | null>(null);
  envoi = signal(false);
  apercuImage = signal<string | null>(null);
  form: BanniereForm = this.formVide();
  private image: File | null = null;

  ngOnInit(): void {
    this.charger();
    this.api.getVilles({ page_size: 100 }).subscribe({ next: r => this.villes.set(r.data.results), error: () => {} });
  }

  charger(): void {
    this.api.getBannieres().subscribe({
      next: r => { this.bannieres.set([...r.data.results].sort((a, b) => a.ordre - b.ordre || a.id - b.id)); this.chargement.set(false); },
      error: () => { this.chargement.set(false); this.toast.error('Impossible de charger les bannières.'); },
    });
  }

  formVide(): BanniereForm {
    const ordre = Math.max(0, ...this.bannieres?.().map(b => b.ordre) ?? [0]) + 1;
    return { titre: '', sous_titre: '', couleur_fond: '#0F4A3B', texte_bouton: '', action: 'aucune', depart: '', arrivee: '',
      page: '', lien: '', ordre, est_active: true, debut: '', fin: '' };
  }

  statut(b: Banniere): { label: string; classe: string } {
    const maintenant = Date.now();
    if (!b.est_active) return { label: 'Masquée', classe: 'badge-neutral' };
    if (b.debut && new Date(b.debut).getTime() > maintenant) return { label: 'Programmée', classe: 'badge-info' };
    if (b.fin && new Date(b.fin).getTime() < maintenant) return { label: 'Terminée', classe: 'badge-warning' };
    return { label: 'En ligne', classe: 'badge-success' };
  }

  libelleAction(b: Banniere): string {
    switch (b.action) {
      case 'recherche': return `Recherche ${b.depart_nom ?? '?'} → ${b.arrivee_nom ?? '?'}`;
      case 'page': return `Page « ${PAGES.find(p => p.code === b.page)?.label ?? b.page} »`;
      case 'lien': return b.lien;
      default: return 'Aucune action';
    }
  }

  ouvrirCreer(): void {
    this.edition.set(null); this.form = this.formVide(); this.image = null; this.apercuImage.set(null); this.formulaire.set(true);
  }

  ouvrirModifier(b: Banniere): void {
    this.edition.set(b); this.image = null; this.apercuImage.set(b.image_url);
    const local = (iso: string | null) => {
      if (!iso) return '';
      const d = new Date(iso); const z = (n: number) => String(n).padStart(2, '0');
      return `${d.getFullYear()}-${z(d.getMonth() + 1)}-${z(d.getDate())}T${z(d.getHours())}:${z(d.getMinutes())}`;
    };
    this.form = { titre: b.titre, sous_titre: b.sous_titre, couleur_fond: b.couleur_fond || '#0F4A3B', texte_bouton: b.texte_bouton,
      action: b.action, depart: b.depart ?? '', arrivee: b.arrivee ?? '', page: b.page, lien: b.lien, ordre: b.ordre,
      est_active: b.est_active, debut: local(b.debut), fin: local(b.fin) };
    this.formulaire.set(true);
  }

  choisirImage(e: Event): void {
    const f = (e.target as HTMLInputElement).files?.[0];
    if (!f) return;
    if (f.size > 5 * 1024 * 1024) { this.toast.error('Image trop lourde (5 Mo maximum).'); return; }
    this.image = f;
    const lecteur = new FileReader();
    lecteur.onload = () => this.apercuImage.set(lecteur.result as string);
    lecteur.readAsDataURL(f);
  }

  enregistrer(): void {
    const b = this.edition();
    if (!b && !this.image) { this.toast.error('Choisissez une image.'); return; }
    const f = this.form;
    if (f.action === 'recherche' && (!f.depart || !f.arrivee)) { this.toast.error("Choisissez les villes de départ et d'arrivée."); return; }
    if (f.action === 'recherche' && f.depart === f.arrivee) { this.toast.error("Le départ et l'arrivée doivent être différents."); return; }
    if (f.action === 'page' && !f.page) { this.toast.error('Choisissez la page à ouvrir.'); return; }
    if (f.action === 'lien' && !/^https?:\/\//.test(f.lien)) { this.toast.error('Indiquez un lien commençant par https://'); return; }
    if (f.debut && f.fin && f.debut >= f.fin) { this.toast.error('La fin doit être après le début.'); return; }

    const data = new FormData();
    const iso = (v: string) => v ? new Date(v).toISOString() : '';
    const champs: Record<string, string> = {
      titre: f.titre.trim(), sous_titre: f.sous_titre.trim(), couleur_fond: f.couleur_fond, texte_bouton: f.texte_bouton.trim(),
      action: f.action, depart: f.action === 'recherche' ? f.depart : '', arrivee: f.action === 'recherche' ? f.arrivee : '',
      page: f.action === 'page' ? f.page : '', lien: f.action === 'lien' ? f.lien.trim() : '',
      ordre: String(f.ordre ?? 0), est_active: f.est_active ? 'true' : 'false', debut: iso(f.debut), fin: iso(f.fin),
    };
    Object.entries(champs).forEach(([k, v]) => data.append(k, v));
    if (this.image) data.append('image', this.image);

    this.envoi.set(true);
    this.api.enregistrerBanniere(b?.id ?? null, data).subscribe({
      next: () => { this.envoi.set(false); this.formulaire.set(false); this.toast.success(b ? 'Bannière mise à jour.' : 'Bannière créée.'); this.charger(); },
      error: e => {
        this.envoi.set(false);
        const err = e?.error?.errors; const premier = err && typeof err === 'object' ? Object.values(err)[0] : null;
        this.toast.error((Array.isArray(premier) ? premier[0] : premier) || e?.error?.message || "Erreur lors de l'enregistrement.");
      },
    });
  }

  basculer(b: Banniere): void {
    this.api.updateBanniere(b.id, { est_active: !b.est_active }).subscribe({
      next: () => { this.toast.success(b.est_active ? 'Bannière masquée.' : 'Bannière en ligne.'); this.charger(); },
      error: () => this.toast.error('Modification impossible.'),
    });
  }

  /** Échange l'ordre avec la bannière voisine. */
  deplacer(b: Banniere, sens: -1 | 1): void {
    const liste = this.bannieres();
    const i = liste.indexOf(b); const voisin = liste[i + sens];
    if (!voisin) return;
    const [o1, o2] = b.ordre === voisin.ordre ? [voisin.ordre + (sens > 0 ? 1 : -1), b.ordre] : [voisin.ordre, b.ordre];
    this.api.updateBanniere(b.id, { ordre: Math.max(0, o1) }).subscribe({
      next: () => this.api.updateBanniere(voisin.id, { ordre: Math.max(0, o2) }).subscribe({ next: () => this.charger(), error: () => this.charger() }),
      error: () => this.toast.error('Modification impossible.'),
    });
  }

  supprimer(b: Banniere): void {
    if (!confirm(`Supprimer la bannière « ${b.titre || 'sans titre'} » ?`)) return;
    this.api.deleteBanniere(b.id).subscribe({
      next: () => { this.toast.success('Bannière supprimée.'); this.charger(); },
      error: () => this.toast.error('Suppression impossible.'),
    });
  }
}
