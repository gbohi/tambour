import { Component, Input, Output, EventEmitter } from '@angular/core';
import { IconComponent } from '../icon/icon.component';
import { NombrePipe } from '../../pipes/nombre.pipe';

@Component({
  selector: 'app-pagination',
  standalone: true,
  imports: [IconComponent, NombrePipe],
  template: `
    <div class="table-footer">
      <span>{{ rangeStart() | nb }}–{{ rangeEnd() | nb }} sur <b>{{ total | nb }}</b></span>
      @if (totalPages() > 1) {
        <div class="pag">
          <button class="icon-btn" [disabled]="page <= 1" (click)="pageChange.emit(page - 1)" aria-label="Page précédente">
            <tb-icon name="chevron-left" [size]="16" />
          </button>
          @for (p of pages(); track $index) {
            @if (p === 0) { <span class="trous">…</span> }
            @else { <button class="num" [class.active]="p === page" (click)="pageChange.emit(p)">{{ p }}</button> }
          }
          <button class="icon-btn" [disabled]="page >= totalPages()" (click)="pageChange.emit(page + 1)" aria-label="Page suivante">
            <tb-icon name="chevron-right" [size]="16" />
          </button>
        </div>
      }
    </div>
  `,
  styles: [`
    .pag{display:flex;align-items:center;gap:4px;}
    .num{min-width:34px;height:34px;padding:0 8px;border-radius:9px;border:1px solid transparent;background:none;font-size:13px;font-weight:600;color:var(--text-2);cursor:pointer;}
    .num:hover{background:var(--surface-2);color:var(--text-1);}
    .num.active{background:var(--primary);color:#fff;}
    .trous{color:var(--text-3);padding:0 4px;}
    b{color:var(--text-1);}
  `]
})
export class PaginationComponent {
  @Input() page = 1;
  @Input() total = 0;
  @Input() pageSize = 20;
  @Output() pageChange = new EventEmitter<number>();

  totalPages(): number { return Math.max(Math.ceil(this.total / this.pageSize), 1); }
  rangeStart(): number { return this.total === 0 ? 0 : (this.page - 1) * this.pageSize + 1; }
  rangeEnd(): number { return Math.min(this.page * this.pageSize, this.total); }
  /** Numéros de page, 0 = « … » */
  pages(): number[] {
    const tp = this.totalPages();
    if (tp <= 7) return Array.from({ length: tp }, (_, i) => i + 1);
    const garder = [...new Set([1, tp, this.page - 1, this.page, this.page + 1])].filter(x => x >= 1 && x <= tp).sort((a, b) => a - b);
    const res: number[] = [];
    garder.forEach((p, i) => { if (i && p - garder[i - 1] > 1) res.push(0); res.push(p); });
    return res;
  }
}
