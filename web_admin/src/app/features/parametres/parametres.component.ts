import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../shared/components/icon/icon.component';
import { NombrePipe } from '../../shared/pipes/nombre.pipe';
import { ApiService } from '../../core/services/api.service';
import { ToastService } from '../../core/services/toast.service';
import { ModeFrais, ParametresPlateforme } from '../../core/models/plateforme.model';

const MODES: { code: ModeFrais; titre: string; detail: string }[] = [
  { code: 'par_reservation', titre: 'Montant fixe par réservation', detail: 'Le même montant quel que soit le nombre de passagers.' },
  { code: 'par_passager', titre: 'Montant fixe par passager', detail: 'Multiplié par le nombre de billets de la réservation.' },
  { code: 'pourcentage', titre: 'Pourcentage du prix des billets', detail: 'Avec un minimum en FCFA (50 % au plus).' },
];

/** Paramètres de la plateforme : frais de service ajoutés au prix des billets (TTC = billets + frais). */
@Component({
  selector: 'app-parametres',
  standalone: true,
  imports: [FormsModule, IconComponent, NombrePipe],
  template: `
    <div class="page">
      <div class="page-header">
        <div><h1 class="page-title">Paramètres</h1>
          <p class="page-subtitle">Frais de service appliqués à chaque réservation (application et site)</p></div>
      </div>

      @if (chargement()) { <div class="card"><div class="loading-row"><span class="spinner"></span></div></div> }
      @else {
        <div class="grille">
          <div class="card">
            <h3 class="titre"><tb-icon name="wallet" [size]="18" /> Frais de service</h3>
            <p class="form-hint">Les voyageurs paient : <b>prix des billets + frais de service = total TTC</b>. Le changement s'applique aux nouvelles réservations.</p>

            <div class="modes">
              @for (m of modes; track m.code) {
                <label class="mode" [class.actif]="form.frais_service_mode === m.code">
                  <input type="radio" name="mode" [value]="m.code" [(ngModel)]="form.frais_service_mode" (ngModelChange)="maj()">
                  <span><b>{{ m.titre }}</b><small>{{ m.detail }}</small></span>
                </label>
              }
            </div>

            <div class="form-row">
              <div class="form-group">
                <label class="form-label">{{ form.frais_service_mode === 'pourcentage' ? 'Pourcentage (%)' : 'Montant (FCFA)' }}</label>
                <input type="number" class="form-control" min="0" [max]="form.frais_service_mode === 'pourcentage' ? 50 : null"
                       [step]="form.frais_service_mode === 'pourcentage' ? 0.5 : 50" [(ngModel)]="form.frais_service_valeur" (ngModelChange)="maj()">
              </div>
              @if (form.frais_service_mode === 'pourcentage') {
                <div class="form-group"><label class="form-label">Minimum (FCFA)</label>
                  <input type="number" class="form-control" min="0" step="50" [(ngModel)]="form.frais_service_minimum" (ngModelChange)="maj()"></div>
              }
            </div>

            <label class="case"><input type="checkbox" [(ngModel)]="form.frais_remboursables">
              Rembourser les frais de service en cas d'annulation</label>
            <span class="form-hint">Par défaut, seuls les billets sont remboursés.</span>

            <div class="actions">
              <button class="btn btn-primary" (click)="enregistrer()" [disabled]="envoi() || !valide()">
                @if (envoi()) { <span class="spinner"></span> } Enregistrer</button>
            </div>
          </div>

          <div class="card apercu">
            <h3 class="titre"><tb-icon name="eye" [size]="18" /> Aperçu pour un voyageur</h3>
            <div class="form-row">
              <div class="form-group"><label class="form-label">Prix du billet</label>
                <input type="number" class="form-control" step="100" [(ngModel)]="exemplePrix" (ngModelChange)="maj()"></div>
              <div class="form-group"><label class="form-label">Passagers</label>
                <input type="number" class="form-control" min="1" max="9" [(ngModel)]="exempleNb" (ngModelChange)="maj()"></div>
            </div>
            <div class="lignes">
              <div><span>{{ exempleNb }} × billet</span><span>{{ exemplePrix | nb }} F</span></div>
              <div><span>Frais de service</span><span>{{ apercu().frais | nb }} F</span></div>
              <div class="total"><span>Total TTC</span><span>{{ apercu().total | nb }} F</span></div>
            </div>
            <p class="avis"><tb-icon name="info" [size]="16" /> Les voyageurs voient : « Des frais de service s'appliquent à chaque réservation. »</p>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .grille{display:grid;grid-template-columns:minmax(0,1.4fr) minmax(0,1fr);gap:20px;align-items:start;}
    @media (max-width:960px){.grille{grid-template-columns:1fr;}}
    .titre{display:flex;align-items:center;gap:8px;font-size:16px;font-weight:700;margin:0 0 6px;}
    .modes{display:grid;gap:10px;margin:18px 0;}
    .mode{display:flex;gap:12px;align-items:flex-start;padding:14px;border:1.5px solid var(--border);border-radius:12px;cursor:pointer;}
    .mode.actif{border-color:var(--primary);background:var(--primary-light);}
    .mode input{accent-color:var(--primary);margin-top:3px;}
    .mode span{display:flex;flex-direction:column;gap:2px;font-size:14px;}
    .mode small{color:var(--text-3);font-size:12px;}
    .case{display:flex;align-items:center;gap:8px;font-size:14px;color:var(--text-2);cursor:pointer;margin-top:6px;}
    .case input{accent-color:var(--primary);width:16px;height:16px;}
    .actions{display:flex;justify-content:flex-end;margin-top:18px;}
    .lignes{display:grid;gap:10px;margin-top:8px;font-size:14px;}
    .lignes div{display:flex;justify-content:space-between;color:var(--text-2);}
    .lignes .total{border-top:1px solid var(--border);padding-top:10px;font-size:18px;font-weight:800;color:var(--text);}
    .avis{display:flex;gap:8px;align-items:center;margin-top:16px;padding:10px 12px;border-radius:10px;background:var(--warning-bg);color:var(--warning);font-size:13px;}
  `],
})
export class ParametresComponent implements OnInit {
  private api = inject(ApiService);
  private toast = inject(ToastService);
  readonly modes = MODES;
  chargement = signal(true);
  envoi = signal(false);
  form: ParametresPlateforme = { frais_service_mode: 'par_reservation', frais_service_valeur: 500, frais_service_minimum: 0, frais_remboursables: false };
  exemplePrix = 4400;
  exempleNb = 2;
  private version = signal(0);

  /** Même calcul que le serveur (arrondi à 5 FCFA). */
  apercu = computed(() => {
    this.version();
    const billets = (Number(this.exemplePrix) || 0) * (Number(this.exempleNb) || 0);
    const v = Number(this.form.frais_service_valeur) || 0;
    let frais = this.form.frais_service_mode === 'par_passager' ? v * (Number(this.exempleNb) || 0)
      : this.form.frais_service_mode === 'pourcentage' ? Math.max(billets * v / 100, Number(this.form.frais_service_minimum) || 0)
      : v;
    frais = Math.round(frais / 5) * 5;
    return { frais, total: billets + frais };
  });

  ngOnInit(): void {
    this.api.getParametres().subscribe({
      next: r => { this.form = { ...r.data, frais_service_valeur: Number(r.data.frais_service_valeur) }; this.chargement.set(false); this.maj(); },
      error: () => { this.chargement.set(false); this.toast.error('Impossible de charger les paramètres.'); },
    });
  }

  maj(): void { this.version.update(v => v + 1); }

  valide(): boolean {
    const v = Number(this.form.frais_service_valeur);
    return v >= 0 && (this.form.frais_service_mode !== 'pourcentage' || v <= 50);
  }

  enregistrer(): void {
    this.envoi.set(true);
    const { frais_service_mode, frais_service_valeur, frais_service_minimum, frais_remboursables } = this.form;
    this.api.updateParametres({ frais_service_mode, frais_service_valeur, frais_service_minimum: frais_service_minimum || 0, frais_remboursables }).subscribe({
      next: r => { this.envoi.set(false); this.toast.success(`Frais de service enregistrés : ${r.data.libelle_frais ?? ''}`); },
      error: e => { this.envoi.set(false); this.toast.error(e?.error?.message || "Erreur lors de l'enregistrement."); },
    });
  }
}
