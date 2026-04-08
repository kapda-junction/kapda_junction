const mongoose = require('mongoose');

const returnLineSchema = new mongoose.Schema({
  orderItemId: { type: mongoose.Schema.Types.ObjectId, default: null },
  itemIndex: { type: Number, default: null, min: 0 },
  quantity: { type: Number, required: true, min: 1 }
}, { _id: false });

const RETURN_STATUSES = [
  'requested',
  'approved',
  'rejected',
  'cancelled',
  'pickup_scheduled',
  'in_transit',
  'received',
  'refund_processing',
  'refunded',
  'exchange_processing',
  'exchange_shipped',
  'completed'
];

const returnRequestSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  type: { type: String, enum: ['return', 'exchange', 'order_cancel'], required: true },
  /** Empty when type is order_cancel (full order). */
  items: { type: [returnLineSchema], default: [] },
  reason: { type: String, required: true },
  reasonDetail: { type: String, default: '' },
  /** Proof video (Cloudinary URL). Required when store policy mandates it. */
  videoUrl: { type: String, default: '' },
  exchangeFor: {
    size: { type: String, default: '' },
    color: { type: String, default: '' }
  },
  status: { type: String, enum: RETURN_STATUSES, default: 'requested' },
  adminNote: { type: String, default: '' },
  rejectReason: { type: String, default: '' },
  pickupCourier: { type: String, default: '' },
  pickupAwb: { type: String, default: '' },
  pickupScheduledAt: { type: Date, default: null },
  refundAmount: { type: Number, default: null },
  /** When exchange is shipped, optional AWB for replacement */
  exchangeAwb: { type: String, default: '' }
}, { timestamps: true });

const TERMINAL = ['rejected', 'refunded', 'completed', 'cancelled'];

returnRequestSchema.pre('validate', function validateItems(next) {
  if (this.type !== 'order_cancel' && (!this.items || this.items.length === 0)) {
    this.invalidate('items', 'At least one line item is required');
  }
  next();
});

returnRequestSchema.index({ order: 1, user: 1, createdAt: -1 });
returnRequestSchema.index({ status: 1 });

const ReturnRequestModel = mongoose.model('ReturnRequest', returnRequestSchema);
ReturnRequestModel.RETURN_STATUSES = RETURN_STATUSES;
ReturnRequestModel.TERMINAL_RETURN_STATUSES = TERMINAL;
module.exports = ReturnRequestModel;
