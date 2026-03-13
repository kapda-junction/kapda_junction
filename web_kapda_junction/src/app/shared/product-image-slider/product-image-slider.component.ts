import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-product-image-slider',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="slider-wrap">
      @if (imgList.length === 0) {
        <img src="https://via.placeholder.com/300" [alt]="alt" />
      } @else if (imgList.length === 1) {
        <img [src]="imgList[0]" [alt]="alt" />
      } @else {
        @for (img of imgList; track img; let i = $index) {
          <img
            [src]="img"
            [alt]="alt"
            [class.active]="currentIndex === i"
            class="slide-img"
          />
        }
        <div class="dots" *ngIf="imgList.length > 1">
          @for (img of imgList; track img; let i = $index) {
            <span class="dot" [class.active]="currentIndex === i"></span>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    :host { display: block; width: 100%; height: 100%; }
    .slider-wrap {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    .slider-wrap img {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      opacity: 0;
      transition: opacity 0.35s ease;
    }
    .slider-wrap img:first-child:last-child { position: relative; opacity: 1; }
    .slider-wrap .slide-img.active { opacity: 1; z-index: 1; }
    .dots {
      position: absolute;
      bottom: 0.5rem;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      gap: 0.35rem;
      z-index: 2;
    }
    .dot {
      width: 5px;
      height: 5px;
      border-radius: 50%;
      background: rgba(255,255,255,0.5);
      transition: background 0.2s;
    }
    .dot.active { background: #fff; }
  `],
})
export class ProductImageSliderComponent implements OnInit, OnDestroy {
  @Input() images: string[] = [];
  @Input() alt = 'Product';
  @Input() intervalMs = 3500;

  currentIndex = 0;
  private timer: ReturnType<typeof setInterval> | null = null;

  get imgList(): string[] {
    return Array.isArray(this.images) ? this.images.filter(Boolean) : [];
  }

  ngOnInit() {
    if (this.imgList.length > 1) {
      this.timer = setInterval(() => {
        this.currentIndex = (this.currentIndex + 1) % this.imgList.length;
      }, this.intervalMs);
    }
  }

  ngOnDestroy() {
    if (this.timer) clearInterval(this.timer);
  }
}
