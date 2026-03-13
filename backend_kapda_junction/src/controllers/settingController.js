const Setting = require('../models/Setting');

const WHATSAPP_KEY = 'whatsappInquiryNumber';
const DEFAULT_WHATSAPP = '9770525851';

async function getOrCreateWhatsapp() {
  let doc = await Setting.findOne({ key: WHATSAPP_KEY });
  if (!doc) {
    doc = await Setting.create({ key: WHATSAPP_KEY, value: DEFAULT_WHATSAPP });
  }
  return doc.value;
}

exports.getPublic = async (req, res, next) => {
  try {
    const value = await getOrCreateWhatsapp();
    res.json({ whatsappInquiryNumber: value });
  } catch (err) {
    next(err);
  }
};

exports.updateWhatsapp = async (req, res, next) => {
  try {
    const { whatsappInquiryNumber } = req.body;
    if (!whatsappInquiryNumber || typeof whatsappInquiryNumber !== 'string') {
      return res.status(400).json({ message: 'Valid WhatsApp number required' });
    }
    const cleaned = whatsappInquiryNumber.replace(/\D/g, '');
    if (cleaned.length < 10) {
      return res.status(400).json({ message: 'Invalid WhatsApp number' });
    }
    const doc = await Setting.findOneAndUpdate(
      { key: WHATSAPP_KEY },
      { value: cleaned },
      { new: true, upsert: true }
    );
    res.json({ whatsappInquiryNumber: doc.value });
  } catch (err) {
    next(err);
  }
};
