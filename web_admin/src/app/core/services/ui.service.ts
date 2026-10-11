import { Injectable, signal } from '@angular/core';

/** État d'interface partagé (menu latéral ouvert sur mobile / tablette). */
@Injectable({ providedIn: 'root' })
export class UiService {
  readonly menuOuvert = signal(false);
  basculerMenu(): void { this.menuOuvert.update(v => !v); }
  fermerMenu(): void { this.menuOuvert.set(false); }
}
