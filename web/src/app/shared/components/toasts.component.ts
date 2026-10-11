import { Component, inject } from '@angular/core';
import { ToastService } from '../../core/toast.service';
import { IconComponent } from './icon/icon.component';

@Component({
  selector: 'tb-toasts',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="pile" aria-live="polite">
      @for (t of ts.toasts(); track t.id) {
        <div class="toast" [class]="'toast ' + t.type" (click)="ts.retirer(t.id)">
          <tb-icon [name]="t.type === 'succes' ? 'check-circle' : t.type === 'erreur' ? 'alert' : 'info'" [size]="20" />
          <span>{{ t.message }}</span>
        </div>
      }
    </div>
  `,
  styles: [`
    .pile{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);z-index:2000;display:flex;flex-direction:column;gap:10px;width:min(440px,calc(100vw - 32px));}
    .toast{display:flex;align-items:center;gap:12px;padding:14px 18px;border-radius:16px;background:var(--encre);color:#fff;font-weight:500;box-shadow:var(--ombre-3);cursor:pointer;animation:monte .25s;}
    .succes tb-icon{color:#4ADE9B;} .erreur tb-icon{color:#FF8A8A;} .info tb-icon{color:#FFC766;}
  `],
})
export class ToastsComponent { ts = inject(ToastService); }
