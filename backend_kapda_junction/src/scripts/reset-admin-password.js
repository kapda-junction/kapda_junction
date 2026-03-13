require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const NEW_PASSWORD = 'Admin@123';

async function resetAdminPassword() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected');

    const hashed = await bcrypt.hash(NEW_PASSWORD, 12);
    const result = await User.updateOne(
      { email: 'admin@kapdajunction.com' },
      { $set: { password: hashed } }
    );

    if (result.modifiedCount > 0) {
      console.log('✅ Admin password reset successfully!');
      console.log('   Email: admin@kapdajunction.com');
      console.log('   Password: Admin@123');
    } else {
      console.log('❌ Admin user not found. Run register first or check email.');
    }
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

resetAdminPassword();
