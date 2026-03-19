# Kapda Junction - Production Payment Flow

## Razorpay Webhook Events (हमें ज़रूरी)

| Event | Use Case | Action |
|-------|----------|--------|
| **payment.captured** | Payment success | Order को `paid` mark करो, stock reduce (optional) |
| **payment.failed** | Payment fail (user ने बीच में छोड़ दिया) | Order `failed` mark या payment_status update |
| **refund.processed** | Refund complete | Order `refunded`, status `cancelled` |
| **refund.failed** | Refund fail | Log करो, admin को alert |

### Optional (future)

- **order.paid** – alternative confirmation
- **refund.created** – refund initiated (status update)

---

## Order Status Flow

```
pending (order created, payment pending)
    ↓ payment.captured
paid + confirmed (admin accept)
    ↓ admin ships
shipped
    ↓ delivered
delivered

OR

pending/paid → admin cancel / stock issue / can't deliver
    ↓ initiate refund
refund initiated
    ↓ refund.processed webhook
cancelled + refunded
```

---

## Scenarios

### 1. Stock नहीं है, payment हो गई (race condition)
- **Prevention:** create-payment से पहले stock validate
- **If still happens:** payment.captured के बाद stock check → अगर fail तो auto-refund + order cancel

### 2. Admin cancel करता है (delivery नहीं हो सकती)
- Admin "Cancel" पर click
- अगर paid: Razorpay refund API call → refund.processed webhook → order cancelled
- अगर pending: direct cancel

### 3. Customer side error (payment fail)
- payment.failed webhook → order payment_status = failed

### 4. Refund fail
- refund.failed webhook → log, admin manually retry

---

## Razorpay Dashboard - Webhook Setup

**URL:** `https://your-domain.com/api/orders/webhook`

**Events subscribe करो:**
- payment.captured
- payment.failed
- refund.processed
- refund.failed

---

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | /orders/create-payment | user | Order + Razorpay order create (stock validate) |
| PUT | /orders/:id/status | admin | Status update (confirmed/shipped/delivered) |
| PUT | /orders/:id/cancel | admin | Cancel + refund (if paid) |
| POST | /orders/:id/refund | admin | Manual full refund |
