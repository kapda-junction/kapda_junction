const Setting = require('../models/Setting');

const KEYS = {
  returnsEnabled: 'returnsEnabled',
  returnVideoRequired: 'returnVideoRequired',
  customerOrderCancelEnabled: 'customerOrderCancelEnabled'
};

async function getBool(key, defaultValue) {
  const doc = await Setting.findOne({ key });
  if (doc == null || doc.value === undefined || doc.value === null) return defaultValue;
  if (typeof doc.value === 'boolean') return doc.value;
  if (doc.value === 'true' || doc.value === true) return true;
  if (doc.value === 'false' || doc.value === false) return false;
  return defaultValue;
}

async function setBool(key, value) {
  await Setting.findOneAndUpdate(
    { key },
    { value: !!value },
    { upsert: true, new: true }
  );
}

exports.KEYS = KEYS;

exports.isReturnsEnabled = () => getBool(KEYS.returnsEnabled, true);

exports.isReturnVideoRequired = () => getBool(KEYS.returnVideoRequired, true);

exports.isCustomerOrderCancelEnabled = () => getBool(KEYS.customerOrderCancelEnabled, true);

exports.getPublicStorePolicy = async () => ({
  returnsEnabled: await exports.isReturnsEnabled(),
  returnVideoRequired: await exports.isReturnVideoRequired(),
  customerOrderCancelEnabled: await exports.isCustomerOrderCancelEnabled()
});

exports.setStorePolicy = async ({ returnsEnabled, returnVideoRequired, customerOrderCancelEnabled }) => {
  if (returnsEnabled !== undefined) await setBool(KEYS.returnsEnabled, returnsEnabled);
  if (returnVideoRequired !== undefined) await setBool(KEYS.returnVideoRequired, returnVideoRequired);
  if (customerOrderCancelEnabled !== undefined) {
    await setBool(KEYS.customerOrderCancelEnabled, customerOrderCancelEnabled);
  }
};
