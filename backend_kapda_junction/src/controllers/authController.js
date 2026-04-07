const User = require('../models/User');
const DeviceToken = require('../models/DeviceToken');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const generateToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET || 'kapda-junction-secret',
    { expiresIn: '7d' }
  );
};

exports.register = async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!name || !normalizedEmail || !password) {
      return res.status(400).json({ message: 'Name, email and password are required' });
    }

    const existing = await User.findOne({ email: normalizedEmail }).lean();
    if (existing) {
      return res.status(409).json({ message: 'Email already registered' });
    }

    // User model pre-save hook hashes password, so pass plain password here.
    const user = await User.create({
      name,
      email: normalizedEmail,
      password,
      role: role || 'customer'
    });
    const token = generateToken(user);
    res.status(201).json({
      user: { id: user._id, name: user.name, email: user.email, role: user.role },
      token
    });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail }).select('+password');
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    const token = generateToken(user);
    user.password = undefined;
    res.json({ user, token });
  } catch (err) {
    next(err);
  }
};

exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.json(user);
  } catch (err) {
    next(err);
  }
};

exports.saveFcmToken = async (req, res, next) => {
  try {
    const { token, platform } = req.body;
    if (!token) return res.status(400).json({ message: 'Token required' });
    // Remove duplicate then push fresh
    await User.findByIdAndUpdate(req.user.id, { $pull: { fcmTokens: { token } } });
    await User.findByIdAndUpdate(req.user.id, {
      $push: { fcmTokens: { token, platform: platform || 'android', updatedAt: new Date() } }
    });
    // Token now belongs to a logged-in user — remove from anonymous device pool
    await DeviceToken.deleteOne({ token });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

function getAddressStore(user) {
  const raw = user.address || {};
  if (Array.isArray(raw.addresses)) {
    return {
      addresses: raw.addresses.map((a) => ({ ...a })),
    };
  }

  // Backward-compatible migration: old single address object -> first entry
  const hasLegacy =
    raw &&
    typeof raw === 'object' &&
    (raw.name || raw.phone || raw.address || raw.city || raw.state || raw.pincode);
  if (!hasLegacy) return { addresses: [] };

  return {
    addresses: [{
      id: new mongoose.Types.ObjectId().toString(),
      label: 'Home',
      name: raw.name || user.name || '',
      phone: raw.phone || user.phone || '',
      address: raw.address || '',
      city: raw.city || '',
      state: raw.state || '',
      pincode: raw.pincode || '',
      isDefault: true,
      updatedAt: new Date()
    }]
  };
}

function sanitizeAddressInput(input) {
  const out = {
    label: String(input.label || 'Home').trim(),
    name: String(input.name || '').trim(),
    phone: String(input.phone || '').trim(),
    address: String(input.address || '').trim(),
    city: String(input.city || '').trim(),
    state: String(input.state || '').trim(),
    pincode: String(input.pincode || '').trim(),
    isDefault: input.isDefault === true,
  };

  if (!out.name || !out.phone || !out.address || !out.city || !out.state || !out.pincode) {
    throw new Error('name, phone, address, city, state and pincode are required');
  }
  return out;
}

function normalizeDefaults(addresses) {
  if (!addresses.length) return addresses;
  const defaultIdx = addresses.findIndex((a) => a.isDefault);
  if (defaultIdx === -1) {
    addresses[0].isDefault = true;
    return addresses;
  }
  return addresses.map((a, i) => ({ ...a, isDefault: i == defaultIdx }));
}

exports.getAddresses = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('name phone address');
    if (!user) return res.status(404).json({ message: 'User not found' });
    const store = getAddressStore(user);
    const addresses = normalizeDefaults(store.addresses).sort((a, b) => {
      if ((a.isDefault ? 1 : 0) != (b.isDefault ? 1 : 0)) {
        return a.isDefault ? -1 : 1;
      }
      return new Date(b.updatedAt || 0) - new Date(a.updatedAt || 0);
    });
    res.json({ addresses });
  } catch (err) {
    next(err);
  }
};

exports.addAddress = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('name phone address');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const store = getAddressStore(user);
    const input = sanitizeAddressInput(req.body || {});
    const entry = {
      id: new mongoose.Types.ObjectId().toString(),
      ...input,
      updatedAt: new Date()
    };

    let nextAddresses = [...store.addresses, entry];
    if (entry.isDefault || nextAddresses.length === 1) {
      nextAddresses = nextAddresses.map((a) => ({ ...a, isDefault: a.id === entry.id }));
    }

    await User.findByIdAndUpdate(req.user.id, { address: { addresses: nextAddresses } });
    res.status(201).json({ address: entry, addresses: normalizeDefaults(nextAddresses) });
  } catch (err) {
    next(err);
  }
};

exports.updateAddress = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(req.user.id).select('name phone address');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const store = getAddressStore(user);
    const idx = store.addresses.findIndex((a) => String(a.id) === String(id));
    if (idx === -1) return res.status(404).json({ message: 'Address not found' });

    const current = store.addresses[idx];
    const merged = {
      ...current,
      ...(req.body || {}),
      id: current.id,
      updatedAt: new Date()
    };
    const sanitized = sanitizeAddressInput(merged);
    store.addresses[idx] = {
      id: current.id,
      ...sanitized,
      updatedAt: new Date()
    };

    if (sanitized.isDefault) {
      store.addresses = store.addresses.map((a) => ({ ...a, isDefault: a.id === current.id }));
    } else {
      store.addresses = normalizeDefaults(store.addresses);
    }

    await User.findByIdAndUpdate(req.user.id, { address: { addresses: store.addresses } });
    res.json({ address: store.addresses[idx], addresses: store.addresses });
  } catch (err) {
    next(err);
  }
};

exports.deleteAddress = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(req.user.id).select('name phone address');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const store = getAddressStore(user);
    const existing = store.addresses.find((a) => String(a.id) === String(id));
    if (!existing) return res.status(404).json({ message: 'Address not found' });

    let nextAddresses = store.addresses.filter((a) => String(a.id) !== String(id));
    nextAddresses = normalizeDefaults(nextAddresses);

    await User.findByIdAndUpdate(req.user.id, { address: { addresses: nextAddresses } });
    res.json({ ok: true, addresses: nextAddresses });
  } catch (err) {
    next(err);
  }
};

exports.setDefaultAddress = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(req.user.id).select('name phone address');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const store = getAddressStore(user);
    const exists = store.addresses.some((a) => String(a.id) === String(id));
    if (!exists) return res.status(404).json({ message: 'Address not found' });
    const nextAddresses = store.addresses.map((a) => ({
      ...a,
      isDefault: String(a.id) === String(id),
      updatedAt: new Date()
    }));

    await User.findByIdAndUpdate(req.user.id, { address: { addresses: nextAddresses } });
    res.json({ ok: true, addresses: nextAddresses });
  } catch (err) {
    next(err);
  }
};
