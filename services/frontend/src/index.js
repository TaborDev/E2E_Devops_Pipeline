import express from 'express';
import morgan from 'morgan';
import { healthRoutes } from './health.js';

const app = express();
app.use(morgan('tiny'));

const apiBase = process.env.FRONTEND_API_BASE_URL || 'http://localhost:5000';
const orderApi = process.env.ORDER_API_BASE_URL || 'http://localhost:7000';

app.get('/', (_, res) => {
  res.send(`TechCommerce Frontend. Product API: ${apiBase}, Order API: ${orderApi}`);
});

healthRoutes(app);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Frontend on :${port}`));