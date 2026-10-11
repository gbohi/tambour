import { Pipe, PipeTransform } from '@angular/core';

const FORMAT = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });

/**
 * « 618695 » → « 618 695 ». L'espace fine insécable de fr-FR (U+202F) n'existe pas dans
 * la police Outfit : on la remplace par une espace insécable classique.
 */
@Pipe({ name: 'nb', standalone: true })
export class NombrePipe implements PipeTransform {
  transform(v: number | string | null | undefined, suffixe = ''): string {
    if (v === null || v === undefined || v === '') return '—';
    const n = typeof v === 'string' ? Number(v) : v;
    if (Number.isNaN(n)) return String(v);
    return FORMAT.format(n).replace(/ /g, ' ') + (suffixe ? ' ' + suffixe : '');
  }
}
