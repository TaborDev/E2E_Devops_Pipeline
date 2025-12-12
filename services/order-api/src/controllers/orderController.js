import { saveOrder, getOrder } from '../services/storage.js';

export const createOrder = async (req, res) => {
  try {
    const order = req.body;
    const result = await saveOrder(order);
    res.status(201).json({ 
      message: 'Order created successfully',
      orderId: result.Key 
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: error.message });
  }
};

export const getOrderById = async (req, res) => {
  try {
    const order = await getOrder(req.params.id);
    if (order) {
      return res.json(order);
    }
    res.status(404).json({ error: 'Order not found' });
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ error: error.message });
  }
};
