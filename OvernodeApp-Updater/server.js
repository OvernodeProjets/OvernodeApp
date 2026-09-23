const express = require('express');
const cookieSession = require('cookie-session');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const db = require('./db');
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 3344;
const SESSION_SECRET = process.env.SESSION_SECRET || 'overnode-updater-secret-key-2026';

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.use(
  cookieSession({
    name: 'overnode_updater_session',
    keys: [SESSION_SECRET],
    maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
  })
);

// Routes
app.use('/auth', authRoutes);
app.use('/api', apiRoutes);
app.use('/', dashboardRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'OvernodeApp-Updater', time: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('[OvernodeApp-Updater] Server Error:', err);
  res.status(500).send('Une erreur est survenue sur le serveur.');
});

if (require.main === module) {
  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`[OvernodeApp-Updater] 🚀 Server running at http://localhost:${PORT}`);
    console.log(`[OvernodeApp-Updater] 📡 App Update API available at http://localhost:${PORT}/api/v1/update/check`);
  });
}

module.exports = app;

