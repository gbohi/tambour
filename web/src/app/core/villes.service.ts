import { Injectable, inject } from '@angular/core';
import { Observable, shareReplay, catchError, of } from 'rxjs';
import { ApiService } from './api.service';
import { Ville } from './models';

/** Liste des villes chargée une seule fois. */
@Injectable({ providedIn: 'root' })
export class VillesService {
  private api = inject(ApiService);
  readonly villes$: Observable<Ville[]> = this.api.villes().pipe(catchError(() => of([])), shareReplay(1));
}
