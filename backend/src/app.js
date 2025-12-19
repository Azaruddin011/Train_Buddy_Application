const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const pnrRoutes = require('./routes/pnr');
const paymentRoutes = require('./routes/payments');
const buddyRoutes = require('./routes/buddies');
const trainRoutes = require('./routes/trains');
const userRoutes = require('./routes/users');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.use('/auth', authRoutes);
app.use('/pnr', pnrRoutes);
app.use('/payments', paymentRoutes);
app.use('/buddies', buddyRoutes);
app.use('/trains', trainRoutes);
app.use('/users', userRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    errorCode: 'NOT_FOUND',
    message: 'Route not found'
  });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    success: false,
    errorCode: 'INTERNAL_ERROR',
    message: 'Something went wrong'
  });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log('TrainBuddy backend listening on port ' + PORT);
});
