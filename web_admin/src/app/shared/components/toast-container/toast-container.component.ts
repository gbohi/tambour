import { Component, inject } from '@angular/core';
import { ToastService } from '../../../core/services/toast.service';
import { IconComponent } from '../icon/icon.component';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="toast-wrap" aria-live="polite">
      @for (t of ts.toasts(); track t.id) {
        <div class="toast" [class]="'toast toast-' + t.type" (click)="ts.remove(t.id)">
          <span class="ico"><tb-icon [name]="ico(t.type)" [size]="18" /></span>
          <span class="msg">{{ t.message }}</span>
          <button class="x" aria-label="Fermer"><tb-icon name="x" [size]="16" /></button>
        </div>
      }
    </div>
  `,
  styles: [`
    .toast-wrap{position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;flex-direction:column;gap:10px;max-width:400px;}
    .toast{display:flex;align-items:center;gap:12px;padding:12px 12px 12px 14px;border-radius:14px;font-size:14px;font-weight:500;cursor:pointer;
      background:var(--ink);color:#fff;box-shadow:var(--shadow-lg);animation:toastIn .25s cubic-bezier(.2,.8,.2,1);}
    .ico{width:30px;height:30px;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
    .toast-success .ico{background:rgba(19,168,110,.25);color:#4ADE9B;}
    .toast-error .ico{background:rgba(209,67,67,.25);color:#FF8A8A;}
    .toast-warning .ico{background:rgba(245,166,35,.25);color:#FFC766;}
    .toast-info .ico{background:rgba(37,99,235,.25);color:#8AB4FF;}
    .msg{flex:1;line-height:1.4;}
    .x{background:none;border:none;color:rgba(255,255,255,.5);cursor:pointer;display:flex;padding:4px;border-radius:6px;}
    .x:hover{color:#fff;background:rgba(255,255,255,.1);}
    @keyframes toastIn{from{transform:translateY(12px);opacity:0;}to{transform:none;opacity:1;}}
  `]
})
export class ToastContainerComponent {
  ts = inject(ToastService);
  ico(type: string): string {
    return ({ success: 'check-circle', error: 'x-circle', warning: 'alert', info: 'info' } as Record<string, string>)[type] ?? 'info';
  }
}
