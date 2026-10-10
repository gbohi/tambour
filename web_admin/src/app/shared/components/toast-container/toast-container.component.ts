import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="toast-wrap">
      @for (t of ts.toasts(); track t.id) {
        <div class="toast toast-{{t.type}}" (click)="ts.remove(t.id)">
          <span class="toast-ico">{{ ico(t.type) }}</span>
          <span class="toast-msg">{{ t.message }}</span>
          <button class="toast-x">&#215;</button>
        </div>
      }
    </div>
  `,
  styles: [`
    .toast-wrap{position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;flex-direction:column;gap:8px;max-width:380px;}
    .toast{display:flex;align-items:center;gap:10px;padding:12px 16px;border-radius:12px;font-size:13px;font-weight:500;box-shadow:0 4px 16px rgba(0,0,0,0.12);cursor:pointer;animation:toastIn 0.2s ease;background:#fff;border-left:4px solid #ccc;}
    .toast-success{border-color:#0A7C4E;color:#065C38;}
    .toast-error{border-color:#D94040;color:#9B2222;}
    .toast-warning{border-color:#F5A623;color:#916208;}
    .toast-info{border-color:#2563EB;color:#1D4ED8;}
    .toast-ico{font-size:16px;flex-shrink:0;}
    .toast-msg{flex:1;line-height:1.4;}
    .toast-x{background:none;border:none;font-size:18px;cursor:pointer;color:#999;padding:0 2px;}
    @keyframes toastIn{from{transform:translateX(100%);opacity:0;}to{transform:translateX(0);opacity:1;}}
  `]
})
export class ToastContainerComponent {
  ts = inject(ToastService);
  ico(type: string): string {
    const m: Record<string, string> = { success: '✓', error: '✕', warning: '⚠', info: 'ℹ' };
    return m[type] ?? 'ℹ';
  }
}
