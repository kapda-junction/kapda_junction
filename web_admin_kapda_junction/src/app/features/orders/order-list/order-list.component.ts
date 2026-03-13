import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [CommonModule],
  template: `<div><h1>Orders</h1><p>Order management</p></div>`,
})
export class OrderListComponent {}
