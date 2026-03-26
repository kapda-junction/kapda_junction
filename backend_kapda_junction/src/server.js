require('dotenv').config();
const http = require('http');
const connectDB = require('./config/database');
const app = require('./app');

const PORT = process.env.PORT || 3000;

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`🚀 Kapda Junction API running on port ${PORT}`);

      // Optional local keep-alive.
      // Note: If Render suspends the container, even this interval won't run until the instance wakes up.
      if (process.env.KEEPALIVE_LOCAL === 'true') {
        const intervalMsRaw = parseInt(process.env.KEEPALIVE_INTERVAL_MS || '600000', 10);
        const intervalMs = Number.isFinite(intervalMsRaw) ? Math.max(intervalMsRaw, 30000) : 600000;
        const healthPath = process.env.KEEPALIVE_PATH || '/api/health';

        const pingHealth = () => {
          const req = http.get(
            {
              hostname: '127.0.0.1',
              port: PORT,
              path: healthPath,
              timeout: 5000
            },
            (res) => {
              res.resume(); // Consume response to free memory.
            }
          );

          req.on('timeout', () => req.destroy());
          req.on('error', () => {});
        };

        // Ping once immediately and then on interval.
        pingHealth();
        const timer = setInterval(pingHealth, intervalMs);
        timer.unref(); // Ensure this doesn't keep the event loop alive.
        console.log(`Keep-alive local enabled: ping every ${intervalMs}ms`);
      }
    });
  })
  .catch((err) => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });
