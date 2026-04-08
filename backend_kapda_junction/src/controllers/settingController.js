const Setting = require('../models/Setting');
const storePolicy = require('../services/storePolicyService');

const WHATSAPP_KEY = 'whatsappInquiryNumber';
const SIZE_GUIDE_KEY = 'sizeGuideHtml';
const DEFAULT_WHATSAPP = '9770525851';

async function getOrCreateWhatsapp() {
  let doc = await Setting.findOne({ key: WHATSAPP_KEY });
  if (!doc) {
    doc = await Setting.create({ key: WHATSAPP_KEY, value: DEFAULT_WHATSAPP });
  }
  return doc.value;
}

async function getSizeGuideHtml() {
  const doc = await Setting.findOne({ key: SIZE_GUIDE_KEY });
  if (!doc || doc.value == null) return '';
  return String(doc.value);
}

exports.getPublic = async (req, res, next) => {
  try {
    const [whatsappInquiryNumber, policy, sizeGuideHtml] = await Promise.all([
      getOrCreateWhatsapp(),
      storePolicy.getPublicStorePolicy(),
      getSizeGuideHtml()
    ]);
    res.json({
      whatsappInquiryNumber,
      sizeGuideHtml,
      ...policy
    });
  } catch (err) {
    next(err);
  }
};

/** Admin: update WhatsApp + store policy toggles (all fields optional except at least one should be sent). */
exports.updateSettings = async (req, res, next) => {
  try {
    const {
      whatsappInquiryNumber,
      sizeGuideHtml,
      returnsEnabled,
      returnVideoRequired,
      customerOrderCancelEnabled
    } = req.body || {};

    if (whatsappInquiryNumber !== undefined) {
      if (typeof whatsappInquiryNumber !== 'string') {
        return res.status(400).json({ message: 'WhatsApp number must be a string' });
      }
      const cleaned = whatsappInquiryNumber.replace(/\D/g, '');
      if (cleaned.length < 10) {
        return res.status(400).json({ message: 'Invalid WhatsApp number' });
      }
      await Setting.findOneAndUpdate(
        { key: WHATSAPP_KEY },
        { value: cleaned },
        { new: true, upsert: true }
      );
    }

    if (sizeGuideHtml !== undefined) {
      const html = typeof sizeGuideHtml === 'string' ? sizeGuideHtml : String(sizeGuideHtml || '');
      if (html.length > 80000) {
        return res.status(400).json({ message: 'sizeGuideHtml too long (max 80k chars)' });
      }
      await Setting.findOneAndUpdate(
        { key: SIZE_GUIDE_KEY },
        { value: html },
        { upsert: true, new: true }
      );
    }

    await storePolicy.setStorePolicy({
      returnsEnabled,
      returnVideoRequired,
      customerOrderCancelEnabled
    });

    const value = await getOrCreateWhatsapp();
    const policy = await storePolicy.getPublicStorePolicy();
    const sg = await getSizeGuideHtml();
    res.json({ whatsappInquiryNumber: value, sizeGuideHtml: sg, ...policy });
  } catch (err) {
    next(err);
  }
};
