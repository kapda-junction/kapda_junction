import { Component, Input, OnInit, OnChanges, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SettingsService } from '../../core/services/settings.service';

@Component({
  selector: 'app-whatsapp-button',
  standalone: true,
  imports: [CommonModule],
  template: `
    <a
      *ngIf="href"
      [href]="href"
      target="_blank"
      rel="noopener noreferrer"
      class="wa-btn"
      [attr.aria-label]="'Contact on WhatsApp'"
    >
      <svg viewBox="0 0 24 24" fill="currentColor" width="24" height="24">
        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
      </svg>
      <span *ngIf="showLabel">{{ label }}</span>
    </a>
  `,
  styles: [`
    .wa-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.4rem;
      padding: 0.4rem 0.75rem;
      background: #25d366;
      color: #fff;
      border-radius: var(--radius-sm, 8px);
      font-size: 0.85rem;
      font-weight: 500;
      text-decoration: none;
      transition: background 0.2s, transform 0.2s;
      box-shadow: 0 2px 8px rgba(37, 211, 102, 0.4);
    }
    .wa-btn:hover { background: #20bd5a; color: #fff; transform: scale(1.02); }
    .wa-btn svg { flex-shrink: 0; }
    .wa-btn.inline { padding: 0.35rem 0.6rem; }
    .wa-btn.inline svg { width: 18px; height: 18px; }
  `],
})
export class WhatsAppButtonComponent implements OnInit, OnChanges {
  @Input() product: { name?: string; _id?: string } | null = null;
  @Input() showLabel = false;
  @Input() label = 'WhatsApp';
  @Input() inline = false;
  @Input() customMessage?: string;

  href = '';

  private settings = inject(SettingsService);

  ngOnInit() {
    this.updateHref('9770525851');
    this.settings.getWhatsapp().subscribe((num) => this.updateHref(num));
  }

  ngOnChanges() {
    this.settings.getWhatsapp().subscribe((num) => this.updateHref(num));
  }

  private updateHref(num: string) {
    this.href = this.settings.getWhatsappUrl(num, this.product ?? undefined, this.customMessage);
  }
}
