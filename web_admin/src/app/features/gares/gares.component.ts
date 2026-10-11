import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { Gare, Ville } from '../../core/models/transport.model';

interface GareForm { nom: string; ville: string; adresse: string; latitude: number; longitude: number; telephone: string; heures_ouverture: string; est_principale: boolean; }

@Component({
  selector: 'app-gares',
  standalone: true,
  imports: [CommonModule, FormsModule, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Gares</h1><p class="page-subtitle">{{ total() | nb }} gares dans {{ villes().length }} villes</p></div>
        <button class="btn btn-primary" (click)="ouvrirCreer()"><tb-icon name="plus" [size]="18" /> Ajouter une gare</button>
      </div>
      <div class="table-card">
        <div class="toolbar">
          <select class="form-control" [(ngModel)]="filtreVille" (change)="load()">
            <option value="">Toutes les villes</option>
            @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }
          </select>
          <label class="case"><input type="checkbox" [(ngModel)]="filtrePrincipale" (change)="load()"> Gares principales</label>
        </div>
        <div class="table-container">
          <table>
            <thead><tr><th>Gare</th><th>Adresse</th><th>Horaires</th><th>Compagnies</th><th class="right"></th></tr></thead>
            <tbody>
              @if (loading()) {
                <tr><td colspan="5"><div class="loading-row"><span class="spinner"></span></div></td></tr>
              } @else {
                @for (g of gares(); track g.id) {
                  <tr>
                    <td><div class="cell-flex"><div class="pin" [class.principale]="g.est_principale"><tb-icon name="map-pin" [size]="18" /></div>
                      <div><div class="cell-main">{{ g.nom }}</div>
                        <div class="cell-sub">{{ g.ville_nom }}@if (g.est_principale) { · <span class="text-gold">gare principale</span> }</div></div></div></td>
                    <td><div style="max-width:280px">{{ g.adresse || '—' }}</div>@if (g.telephone) { <div class="cell-sub">{{ g.telephone }}</div> }</td>
                    <td><span class="chip"><tb-icon name="clock" [size]="13" /> {{ g.heures_ouverture }}</span></td>
                    <td>
                      <div class="compagnies">
                        @for (c of g.compagnies.slice(0, 2); track $index) { <span class="chip">{{ c }}</span> }
                        @if (g.compagnies.length > 2) { <span class="chip">+{{ g.compagnies.length - 2 }}</span> }
                        @if (g.compagnies.length === 0) { <span class="text-hint">—</span> }
                      </div>
                    </td>
                    <td class="right">
                      <div class="row-actions">
                        <a class="icon-btn" data-tip="Voir sur la carte" target="_blank" rel="noopener"
                          [href]="'https://www.google.com/maps?q=' + g.latitude + ',' + g.longitude"><tb-icon name="globe" /></a>
                        <button class="icon-btn" data-tip="Modifier" (click)="ouvrirModifier(g)"><tb-icon name="edit" /></button>
                      </div>
                    </td>
                  </tr>
                } @empty {
                  <tr><td colspan="5"><div class="empty-state"><div class="empty-icon"><tb-icon name="map-pin" [size]="26" /></div>
                    <h3>Aucune gare</h3><p>Ajoutez la première gare.</p></div></td></tr>
                }
              }
            </tbody>
          </table>
        </div>
      </div>
    </div>

    @if (showForm()) {
      <div class="modal-backdrop" (click)="showForm.set(false)">
        <div class="modal" style="max-width:560px" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <div class="modal-title">{{ editGare() ? 'Modifier la gare' : 'Nouvelle gare' }}</div>
            <button class="modal-close" (click)="showForm.set(false)"><tb-icon name="x" /></button>
          </div>
          <div class="modal-body">
            <div class="form-group"><label class="form-label">Nom de la gare</label>
              <input type="text" class="form-control" [(ngModel)]="form.nom" placeholder="Ex. : Gare d'Adjamé Nord"></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Ville</label>
                <select class="form-control" [(ngModel)]="form.ville"><option value="">Choisir…</option>
                  @for (v of villes(); track v.id) { <option [value]="v.id">{{ v.nom }}</option> }</select></div>
              <div class="form-group"><label class="form-label">Téléphone</label><input type="text" class="form-control" [(ngModel)]="form.telephone"></div>
            </div>
            <div class="form-group"><label class="form-label">Adresse</label><textarea class="form-control" [(ngModel)]="form.adresse" rows="2"></textarea></div>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Latitude</label><input type="number" class="form-control" [(ngModel)]="form.latitude" step="0.0001"></div>
              <div class="form-group"><label class="form-label">Longitude</label><input type="number" class="form-control" [(ngModel)]="form.longitude" step="0.0001"></div>
            </div>
            <span class="form-hint">Astuce : clic droit sur Google Maps › « Plus d'infos sur cet endroit » pour copier les coordonnées.</span>
            <div class="form-group"><label class="form-label">Horaires d'ouverture</label>
              <input type="text" class="form-control" [(ngModel)]="form.heures_ouverture" placeholder="05h00 - 22h00"></div>
            <label class="case"><input type="checkbox" [(ngModel)]="form.est_principale"> Gare principale de la ville</label>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" (click)="showForm.set(false)">Annuler</button>
            <button class="btn btn-primary" (click)="sauvegarder()" [disabled]="!form.nom.trim() || !form.ville">{{ editGare() ? 'Enregistrer' : 'Créer la gare' }}</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .case{display:inline-flex;align-items:center;gap:8px;font-size:14px;color:var(--text-2);cursor:pointer;}
    .case input{accent-color:var(--primary);width:16px;height:16px;}
    .pin{width:40px;height:40px;border-radius:12px;background:var(--surface-2);color:var(--text-2);display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .pin.principale{background:var(--primary-light);color:var(--primary);}
    .compagnies{display:flex;flex-wrap:wrap;gap:6px;}
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
      next: () => { this.toast.success(g ? 'Gare mise à jour.' : 'Gare créée.'); this.showForm.set(false); this.load(); },
      error: () => this.toast.error("Erreur lors de l'enregistrement.")
    });
  }
}
