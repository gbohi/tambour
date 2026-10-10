import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-stat-card',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="stat-card">
      <div class="stat-icon" [style.background]="iconBg">{{ icon }}</div>
      <div>
        <div class="stat-value">{{ value }}</div>
        <div class="stat-label">{{ label }}</div>
        @if (delta !== undefined) {
          <div class="stat-delta" [class.pos]="delta >= 0" [class.neg]="delta < 0">
            {{ delta >= 0 ? '+' : '' }}{{ delta }} {{ deltaLabel }}
          </div>
        }
      </div>
    </div>
  `
})
export class StatCardComponent {
  @Input() icon = '';
  @Input() label = '';
  @Input() value = '';
  @Input() iconBg = 'var(--primary-light)';
  @Input() delta?: number;
  @Input() deltaLabel = '';
}
