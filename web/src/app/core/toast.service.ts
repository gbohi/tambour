import { Injectable, signal } from '@angular/core';

export interface Toast { id: number; type: 'succes' | 'erreur' | 'info'; message: string; }

@Injectable({ providedIn: 'root' })
export class ToastService {
  readonly toasts = signal<Toast[]>([]);
  private n = 0;
  private ajouter(type: Toast['type'], message: string, duree = 4500): void {
    const id = ++this.n;
    this.toasts.update(t => [...t, { id, type, message }]);
    setTimeout(() => this.retirer(id), duree);
  }
  retirer(id: number): void { this.toasts.update(t => t.filter(x => x.id !== id)); }
  succes(m: string): void { this.ajouter('succes', m); }
  erreur(m: string): void { this.ajouter('erreur', m, 6500); }
  info(m: string): void { this.ajouter('info', m); }
}
