import express from 'express';
import { createOrder, getOrderById } from './controllers/orderController.js';
import dotenv from 'dotenv';
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.post('/orders', createOrder);
app.get('/orders/:id', getOrderById);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Order API running on port ${PORT}`);
});
