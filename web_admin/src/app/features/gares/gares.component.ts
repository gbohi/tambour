import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { Gare, Ville } from '../../core/models/transport.model';

interface GareForm { nom: string; ville: string; adresse: string; latitude: number; longitude: number; telephone: string; heures_ouverture: string; est_principale: boolean; }

@Component({
  selector: 'app-gares',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Gares partenaires</h1><p class="page-subtitle">{{ total() }} gares &middot; {{ villes().length }} villes</p></div>
        <button class="btn btn-primary" (click)="ouvrirCreer()">+ Ajouter une gare</button>
      </div>
      <div class="filters">
        <select class="form-control" style="width:auto" [(ngModel)]="filtreVille" (change)="load()">
          <option value="">Toutes les villes</option>
          @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }
        </select>
        <label style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer">
          <input type="checkbox" [(ngModel)]="filtrePrincipale" (change)="load()"> Principales uniquement
        </label>
      </div>
      @if (loading()) {
        <div class="gg"><div class="skeleton-card" style="height:190px;border-radius:16px"></div></div>
      } @else {
        <div class="gg">
          @for (g of gares(); track g.id) {
            <div class="gc">
              <div class="gc-hd">
                <div class="gc-ico">&#128205;</div>
                <div>
                  @if (g.est_principale) { <span class="badge badge-gold" style="display:block;margin-bottom:4px">&#11088; Principale</span> }
                  <div style="font-size:11px;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:0.5px">{{ g.ville_nom }}</div>
                </div>
              </div>
              <h3 style="font-size:15px;font-weight:700;margin-bottom:10px;line-height:1.3">{{ g.nom }}</h3>
              <div class="gc-meta">
                <span>&#128205; {{ g.adresse }}</span>
                <span>&#128336; {{ g.heures_ouverture }}</span>
                @if (g.telephone) { <span>&#128222; {{ g.telephone }}</span> }
              </div>
              @if (g.compagnies.length > 0) {
                <div style="display:flex;flex-wrap:wrap;gap:4px;margin-bottom:10px">
                  @for (c of g.compagnies.slice(0, 3); track $index) {
                    <span class="badge badge-neutral" style="font-size:10px">{{ c }}</span>
                  }
                  @if (g.compagnies.length > 3) {
                    <span class="badge badge-neutral" style="font-size:10px">+{{ g.compagnies.length - 3 }}</span>
                  }
                </div>
              }
              <button class="btn btn-ghost btn-sm" style="width:100%" (click)="ouvrirModifier(g)">&#9999; Modifier</button>
            </div>
          } @empty {
            <div class="empty-state" style="grid-column:1/-1"><div class="empty-icon">📍</div><h3>Aucune gare</h3><p>Ajoutez la première gare partenaire.</p></div>
          }
        </div>
      }
    </div>
    @if (showForm()) {
      <div class="modal-backdrop" (click)="showForm.set(false)">
        <div class="modal" style="max-width:540px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div class="modal-title">{{ editGare() ? 'Modifier : ' + editGare()!.nom : 'Nouvelle gare' }}</div>
            <button class="modal-close" (click)="showForm.set(false)">&#215;</button>
          </div>
          <div class="modal-body" style="display:flex;flex-direction:column;gap:14px">
            <div class="form-group"><label class="form-label">Nom *</label>
              <input type="text" class="form-control" [(ngModel)]="form.nom" placeholder="Ex: Gare d'Adjame Nord">
            </div>
            <div class="form-group"><label class="form-label">Ville *</label>
              <select class="form-control" [(ngModel)]="form.ville">
                <option value="">Sélectionner</option>
                @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }
              </select>
            </div>
            <div class="form-group"><label class="form-label">Adresse</label>
              <textarea class="form-control" [(ngModel)]="form.adresse" rows="2"></textarea>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
              <div class="form-group"><label class="form-label">Latitude</label>
                <input type="number" class="form-control" [(ngModel)]="form.latitude" step="0.0001">
              </div>
              <div class="form-group"><label class="form-label">Longitude</label>
                <input type="number" class="form-control" [(ngModel)]="form.longitude" step="0.0001">
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
              <div class="form-group"><label class="form-label">Téléphone</label>
                <input type="text" class="form-control" [(ngModel)]="form.telephone">
              </div>
              <div class="form-group"><label class="form-label">Horaires</label>
                <input type="text" class="form-control" [(ngModel)]="form.heures_ouverture" placeholder="05h00 - 22h00">
              </div>
            </div>
            <label style="display:flex;align-items:center;gap:8px;cursor:pointer;font-size:13px">
              <input type="checkbox" [(ngModel)]="form.est_principale"> Gare principale
            </label>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="showForm.set(false)">Annuler</button>
            <button class="btn btn-primary" (click)="sauvegarder()" [disabled]="!form.nom.trim() || !form.ville">
              {{ editGare() ? 'Enregistrer' : 'Créer la gare' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .gg{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:14px;}
    .gc{background:var(--surface);border:0.5px solid var(--border);border-radius:16px;padding:18px;box-shadow:var(--shadow-sm);transition:all 0.15s;}
    .gc:hover{box-shadow:var(--shadow-md);}
    .gc-hd{display:flex;align-items:flex-start;gap:10px;margin-bottom:10px;}
    .gc-ico{width:40px;height:40px;border-radius:10px;background:var(--primary-light);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
    .gc-meta{display:flex;flex-direction:column;gap:4px;font-size:12px;color:var(--text-2);margin-bottom:10px;}
  `]
})
export class GaresComponent implements OnInit {
  private api   = inject(ApiService);
  private toast = inject(ToastService);
  gares    = signal<Gare[]>([]);
  villes   = signal<Ville[]>([]);
  total    = signal(0);
  loading  = signal(false);
  editGare = signal<Gare | null>(null);
  showForm = signal(false);
  filtreVille = ''; filtrePrincipale = false;
  form: GareForm = this.emptyForm();

  ngOnInit(): void { this.loadVilles(); this.load(); }
  emptyForm(): GareForm { return { nom:'', ville:'', adresse:'', latitude:0, longitude:0, telephone:'', heures_ouverture:'05h00 - 22h00', est_principale:false }; }

  loadVilles(): void {
    // page_size est converti en string par toParams() dans ApiService — on passe un number
    this.api.getVilles({ page_size: 100 }).subscribe({ next: res => this.villes.set(res.data.results), error: () => {} });
  }
  load(): void {
    this.loading.set(true);
    const p: Record<string,string> = {};
    if (this.filtreVille)      p['ville']         = this.filtreVille;
    if (this.filtrePrincipale) p['est_principale'] = 'true';
    this.api.getGares(p).subscribe({
      next: res => { this.gares.set(res.data.results); this.total.set(res.data.count); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }
  ouvrirCreer(): void { this.editGare.set(null); this.form = this.emptyForm(); this.showForm.set(true); }
  ouvrirModifier(g: Gare): void {
    this.editGare.set(g);
    this.form = { nom:g.nom, ville:g.ville, adresse:g.adresse, latitude:g.latitude, longitude:g.longitude, telephone:g.telephone, heures_ouverture:g.heures_ouverture, est_principale:g.est_principale };
    this.showForm.set(true);
  }
  sauvegarder(): void {
    const g = this.editGare();
    const obs = g ? this.api.updateGare(g.id, this.form as Partial<Gare>) : this.api.createGare(this.form as Partial<Gare>);
    obs.subscribe({
      next: () => { this.toast.success(g ? 'Gare mise a jour.' : 'Gare creee.'); this.showForm.set(false); this.load(); },
      error: () => this.toast.error("Erreur lors de l'enregistrement.")
    });
  }
}
