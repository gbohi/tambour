import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-pagination',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="pag">
      <span class="pag-info">{{ rangeStart() }}&ndash;{{ rangeEnd() }} sur {{ total }}</span>
      <div class="pag-ctrl">
        <button class="btn btn-ghost btn-sm" [disabled]="page <= 1" (click)="pageChange.emit(page-1)">&#8592; Préc.</button>
        @for (p of pages(); track p) {
          <button class="btn btn-sm"
            [class.btn-primary]="p === page"
            [class.btn-ghost]="p !== page"
            (click)="pageChange.emit(p)">{{ p }}</button>
        }
        <button class="btn btn-ghost btn-sm" [disabled]="page >= totalPages()" (click)="pageChange.emit(page+1)">Suiv. &#8594;</button>
      </div>
    </div>
  `,
  styles: [`.pag{display:flex;align-items:center;justify-content:space-between;padding:16px;border-top:0.5px solid var(--divider);}
    .pag-info{font-size:12px;color:var(--text-2);}
    .pag-ctrl{display:flex;gap:4px;flex-wrap:wrap;}`]
})
export class PaginationComponent {
  @Input() page = 1;
  @Input() total = 0;
  @Input() pageSize = 20;
  @Output() pageChange = new EventEmitter<number>();

  totalPages(): number { return Math.max(Math.ceil(this.total / this.pageSize), 1); }
  rangeStart(): number { return this.total === 0 ? 0 : (this.page-1)*this.pageSize+1; }
  rangeEnd():   number { return Math.min(this.page*this.pageSize, this.total); }
  pages(): number[] {
    const tp = this.totalPages();
    if (tp <= 7) return Array.from({ length: tp }, (_, i) => i+1);
    const near = new Set([1, tp, this.page, this.page-1, this.page+1].filter(x => x >= 1 && x <= tp));
    return [...near].sort((a,b) => a-b);
  }
}
