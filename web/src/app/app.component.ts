import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { EnteteComponent } from './shared/components/entete.component';
import { PiedComponent } from './shared/components/pied.component';
import { ToastsComponent } from './shared/components/toasts.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, EnteteComponent, PiedComponent, ToastsComponent],
  template: `
    <tb-entete />
    <main><router-outlet /></main>
    <tb-pied />
    <tb-toasts />
  `,
  styles: [':host{display:flex;flex-direction:column;min-height:100vh} main{flex:1}'],
})
export class AppComponent {}
