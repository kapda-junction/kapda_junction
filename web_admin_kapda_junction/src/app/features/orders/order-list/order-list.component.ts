import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { SnackbarService } from '../../../core/services/snackbar.service';

interface OrderItem {
  product: { _id: string; name: string; price: number; images?: string[] };
  name: string;
  price: number;
  quantity: number;
  size?: string;
  color?: string;
}

interface Order {
  _id: string;
  user: { _id: string; name: string; email: string };
  items: OrderItem[];
  status: string;
  paymentStatus: string;
  totalAmount: number;
  shippingAddress: any;
  createdAt: string;
  cancelledAt?: string;
  cancelReason?: string;
  razorpayOrderId?: string;
  razorpayPaymentId?: string;
  refundStatus?: string;
  refundAmount?: number;
}

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="page-header">
      <h1>Orders</h1>
      <button class="btn" (click)="load()" [disabled]="loading">↻ Refresh</button>
    </div>

    @if (loading && !orders.length) { <p class="loading">Loading orders...</p> }
    @else if (orders.length) {
      <div class="table-wrap">
        <table class="table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Items</th>
              <th>Total</th>
              <th>Payment</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            @for (o of orders; track o._id) {
              <tr>
                <td><code class="order-id">{{ o._id?.slice(-8) }}</code></td>
                <td>
                  <div class="customer">{{ o.user?.name }}</div>
                  <div class="email">{{ o.user?.email }}</div>
                </td>
                <td>{{ formatDate(o.createdAt) }}</td>
                <td>
                  <span class="item-count">{{ o.items?.length || 0 }} item(s)</span>
                </td>
                <td>₹{{ o.totalAmount }}</td>
                <td>
                  <span class="badge" [class]="'pay-' + o.paymentStatus">{{ o.paymentStatus }}</span>
                  @if (o.refundStatus === 'pending') { <span class="badge refund-pending">Refund pending</span> }
                  @if (o.refundStatus === 'processed') { <span class="badge refund-done">Refunded</span> }
                  @if (o.refundStatus === 'failed') { <span class="badge refund-fail">Refund failed</span> }
                </td>
                <td>
                  <span class="badge" [class]="'status-' + o.status">{{ o.status }}</span>
                </td>
                <td>
                  <div class="actions">
                    @if (o.status !== 'cancelled' && o.status !== 'delivered') {
                      @if (o.status === 'pending' && o.paymentStatus === 'paid') {
                        <button class="btn small primary" (click)="confirmOrder(o)" [disabled]="actioning === o._id">Accept</button>
                      }
                      @if (o.status === 'confirmed') {
                        <select class="status-select" [value]="o.status" (change)="onStatusChange(o, $event)">
                          <option value="confirmed">Confirmed</option>
                          <option value="shipped">Shipped</option>
                          <option value="delivered">Delivered</option>
                        </select>
                      }
                      @if (o.status === 'shipped') {
                        <select class="status-select" [value]="o.status" (change)="onStatusChange(o, $event)">
                          <option value="shipped">Shipped</option>
                          <option value="delivered">Delivered</option>
                        </select>
                      }
                      <button class="btn small danger" (click)="openCancelModal(o)" [disabled]="actioning === o._id">Cancel</button>
                    }
                  </div>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    }
    @else { <p class="empty">No orders yet.</p> }

    @if (showCancelModal) {
      <div class="modal-overlay" (click)="closeCancelModal()">
        <div class="modal" (click)="$event.stopPropagation()">
          <h2>Cancel Order</h2>
          <p class="modal-msg">Order #{{ cancellingOrder?._id?.slice(-8) }} will be cancelled. @if (cancellingOrder?.paymentStatus === 'paid') { A full refund will be initiated. }</p>
          <div class="field">
            <label>Reason (optional)</label>
            <input [(ngModel)]="cancelReason" placeholder="e.g. Out of stock, Customer request" />
          </div>
          <div class="modal-actions">
            <button type="button" class="btn" (click)="closeCancelModal()">Back</button>
            <button type="button" class="btn danger" (click)="cancelOrder()" [disabled]="actioning">
              {{ actioning ? 'Processing...' : 'Cancel & Refund' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    .btn { padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; border: 1px solid #ddd; background: #fff; }
    .btn.primary { background: #1a1a2e; color: #fff; border-color: #1a1a2e; }
    .btn.small { padding: 0.25rem 0.5rem; font-size: 0.85rem; }
    .btn.danger { color: #dc3545; border-color: #dc3545; }
    .btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .table-wrap { overflow-x: auto; }
    .table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .table th, .table td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eee; }
    .table th { background: #f8f9fa; font-weight: 600; font-size: 0.85rem; }
    .order-id { font-size: 0.8rem; background: #f1f3f4; padding: 0.15rem 0.4rem; border-radius: 4px; }
    .customer { font-weight: 500; }
    .email { font-size: 0.8rem; color: #666; }
    .item-count { font-size: 0.9rem; }
    .badge { display: inline-block; padding: 0.15rem 0.5rem; font-size: 0.75rem; border-radius: 4px; margin-right: 0.25rem; }
    .badge.pay-paid { background: #d4edda; color: #155724; }
    .badge.pay-pending { background: #fff3cd; color: #856404; }
    .badge.pay-failed { background: #f8d7da; color: #721c24; }
    .badge.pay-refunded { background: #e2e3e5; color: #383d41; }
    .badge.status-confirmed { background: #cce5ff; color: #004085; }
    .badge.status-shipped { background: #d1ecf1; color: #0c5460; }
    .badge.status-delivered { background: #d4edda; color: #155724; }
    .badge.status-cancelled { background: #f8d7da; color: #721c24; }
    .badge.status-pending { background: #fff3cd; color: #856404; }
    .badge.refund-pending { background: #ffeaa7; color: #5d4e37; }
    .badge.refund-done { background: #d4edda; color: #155724; }
    .badge.refund-fail { background: #f8d7da; color: #721c24; }
    .actions { display: flex; flex-wrap: wrap; gap: 0.35rem; align-items: center; }
    .status-select { padding: 0.2rem 0.5rem; font-size: 0.85rem; border-radius: 4px; border: 1px solid #ddd; }
    .loading, .empty { padding: 2rem; text-align: center; color: #666; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
    .modal { background: #fff; padding: 2rem; border-radius: 12px; max-width: 420px; width: 90%; }
    .modal-msg { margin-bottom: 1rem; font-size: 0.95rem; color: #555; }
    .field { margin-bottom: 1rem; }
    .field label { display: block; font-weight: 500; margin-bottom: 0.35rem; font-size: 0.9rem; }
    .field input { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 6px; }
    .modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem; }
  `],
})
export class OrderListComponent implements OnInit {
  private api = inject(ApiService);
  private snackbar = inject(SnackbarService);

  orders: Order[] = [];
  loading = false;
  actioning: string | null = null;
  showCancelModal = false;
  cancellingOrder: Order | null = null;
  cancelReason = '';

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading = true;
    this.api.get<Order[]>('/orders').subscribe({
      next: (data) => {
        this.orders = Array.isArray(data) ? data : [];
        this.loading = false;
      },
      error: () => {
        this.snackbar.showError('Failed to load orders');
        this.loading = false;
      },
    });
  }

  formatDate(d: string) {
    if (!d) return '—';
    const date = new Date(d);
    return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  }

  confirmOrder(o: Order) {
    this.actioning = o._id;
    this.api.put<Order>(`/orders/${o._id}/status`, { status: 'confirmed' }).subscribe({
      next: (updated) => {
        o.status = updated.status;
        this.actioning = null;
        this.snackbar.showSuccess('Order confirmed');
      },
      error: () => {
        this.actioning = null;
        this.snackbar.showError('Failed to confirm');
      },
    });
  }

  onStatusChange(o: Order, ev: Event) {
    const target = ev.target as HTMLSelectElement;
    const status = target.value as 'confirmed' | 'shipped' | 'delivered';
    if (!status || status === o.status) return;
    this.actioning = o._id;
    this.api.put<Order>(`/orders/${o._id}/status`, { status }).subscribe({
      next: (updated) => {
        o.status = updated.status;
        this.actioning = null;
        this.snackbar.showSuccess('Status updated');
      },
      error: () => {
        this.actioning = null;
        target.value = o.status;
        this.snackbar.showError('Failed to update');
      },
    });
  }

  openCancelModal(o: Order) {
    this.cancellingOrder = o;
    this.cancelReason = '';
    this.showCancelModal = true;
  }

  closeCancelModal() {
    this.showCancelModal = false;
    this.cancellingOrder = null;
    this.cancelReason = '';
  }

  cancelOrder() {
    if (!this.cancellingOrder) return;
    this.actioning = this.cancellingOrder._id;
    this.api.put<{ order?: Order; message?: string } & Order>(`/orders/${this.cancellingOrder._id}/cancel`, { reason: this.cancelReason }).subscribe({
      next: (res) => {
        const updated = (res as any).order || res;
        const idx = this.orders.findIndex((x) => x._id === this.cancellingOrder!._id);
        if (idx >= 0) this.orders[idx] = updated;
        this.closeCancelModal();
        this.actioning = null;
        this.snackbar.showSuccess(
          updated.paymentStatus === 'refunded' || updated.refundStatus === 'pending'
            ? 'Order cancelled. Refund initiated.'
            : 'Order cancelled'
        );
      },
      error: (err) => {
        this.actioning = null;
        this.snackbar.showError(err.error?.message || 'Failed to cancel');
      },
    });
  }
}
