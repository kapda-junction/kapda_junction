import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-product-price',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span class="price-wrap" [class.has-offer]="hasOffer">
      @if (hasOffer) {
        <span class="price-original">₹{{ compareAtPrice }}</span>
        <span class="price-offer">₹{{ price }}</span>
        <span class="price-badge">{{ discountPercent }}% OFF</span>
      } @else {
        <span class="price-single">₹{{ price }}</span>
      }
    </span>
  `,
  styles: [`
    .price-wrap { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 0.35rem 0.5rem; }
    .price-original { font-size: inherit; color: #999; text-decoration: line-through; }
    .price-offer { font-weight: 700; color: var(--color-primary); }
    .price-badge { font-size: 0.7em; font-weight: 600; background: #dc3545; color: #fff; padding: 0.15rem 0.35rem; border-radius: 4px; }
    .price-single { font-weight: 700; color: var(--color-primary); }
  `],
})
export class ProductPriceComponent {
  @Input() price!: number;
  @Input() compareAtPrice?: number;

  get hasOffer(): boolean {
    return !!(
      this.compareAtPrice &&
      this.price != null &&
      this.compareAtPrice > this.price
    );
  }

  get discountPercent(): number {
    if (!this.hasOffer || !this.compareAtPrice) return 0;
    return Math.round(((this.compareAtPrice - this.price) / this.compareAtPrice) * 100);
  }
}
