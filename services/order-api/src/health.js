export const healthRoutes = (app) => {
  app.get('/healthz', (req, res) => res.json({ status: 'ok' }));
  app.get('/livez', (req, res) => res.json({ live: true }));
};