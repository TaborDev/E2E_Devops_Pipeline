import express from 'express';
import morgan from 'morgan';
import { healthRoutes } from './health.js';

const app = express();
app.use(morgan('tiny'));

app.get('/orders', (_, res) => {
  res.json([{ id: 'ord_1', total: 24.99 }]);
});

healthRoutes(app);

const port = process.env.PORT || 7000;
app.listen(port, () => console.log(`Order API on :${port}`));