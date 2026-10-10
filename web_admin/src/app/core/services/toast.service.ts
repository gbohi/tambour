import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'error' | 'warning' | 'info';
export interface Toast { id: number; type: ToastType; message: string; duration: number; }

@Injectable({ providedIn: 'root' })
export class ToastService {
  private _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();
  private nextId = 0;

  private add(type: ToastType, message: string, duration = 4000): void {
    const id = ++this.nextId;
    this._toasts.update(t => [...t, { id, type, message, duration }]);
    setTimeout(() => this.remove(id), duration);
  }
  remove(id: number): void { this._toasts.update(t => t.filter(x => x.id !== id)); }
  success(msg: string) { this.add('success', msg); }
  error(msg: string)   { this.add('error', msg, 6000); }
  warning(msg: string) { this.add('warning', msg); }
  info(msg: string)    { this.add('info', msg); }
}
