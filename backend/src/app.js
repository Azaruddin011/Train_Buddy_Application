const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');
const { connectDB } = require('./db/mongoose');

const authRoutes = require('./routes/auth');
const pnrRoutes = require('./routes/pnr');
const paymentRoutes = require('./routes/payments');
const buddyRoutes = require('./routes/buddies');
const trainRoutes = require('./routes/trains');
const userRoutes = require('./routes/users');
const adminRoutes = require('./routes/admin');
const offerRoutes = require('./routes/offers');
const ApiError = require('./utils/apiError');

const app = express();
app.use(cors());
app.use(express.json());

const uploadsDir = process.env.UPLOADS_DIR
  ? path.resolve(process.env.UPLOADS_DIR)
  : path.join(__dirname, '..', 'uploads');
app.use('/uploads', express.static(uploadsDir));

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.use('/auth', authRoutes);
app.use('/pnr', pnrRoutes);
app.use('/payments', paymentRoutes);
app.use('/buddies', buddyRoutes);
app.use('/offers', offerRoutes);
app.use('/trains', trainRoutes);
app.use('/users', userRoutes);
app.use('/admin', adminRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    errorCode: 'NOT_FOUND',
    message: 'Route not found'
  });
});

app.use((err, req, res, next) => {
  console.error(err);
  if (err instanceof ApiError) {
    return res.status(err.statusCode || 500).json(err.toJSON());
  }

  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    success: false,
    errorCode: 'INTERNAL_ERROR',
    message: err.message || 'Something went wrong'
  });
});

const PORT = process.env.PORT || 4000;

// Connect to MongoDB
connectDB().then(connected => {
  if (!connected) {
    console.warn('Warning: MongoDB connection failed. Some features may not work properly.');
  }
  
  // Start server regardless of DB connection status
  app.listen(PORT, () => {
    console.log('TrainBuddy backend listening on port ' + PORT);
  });
});
