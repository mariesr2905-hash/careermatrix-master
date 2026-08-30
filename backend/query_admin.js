const mongoose = require('mongoose');
const User = require('./models/User');

async function test() {
  try {
    await mongoose.connect('mongodb://127.0.0.1:27017/career_matrix');
    console.log('Connected!');

    const admins = await User.find({ role: 'ADMIN' });
    console.log('Admins found:', admins.length);
    admins.forEach(admin => {
      console.log(`- ID: ${admin._id}, Name: ${admin.name}, Email: ${admin.email}, Status: ${admin.status}`);
    });

    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

test();
