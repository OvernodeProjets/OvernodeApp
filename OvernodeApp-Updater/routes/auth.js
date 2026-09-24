const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const db = require('../db');

// SECURITY: Rate-limit authentication routes to prevent brute-force attacks
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Max 10 attempts per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Trop de tentatives. Veuillez réessayer dans 15 minutes.',
  handler: function(req, res) {
    if (req.path === '/login') {
      return res.render('login', { error: 'Trop de tentatives de connexion. Réessayez dans 15 minutes.', message: null });
    }
    if (req.path === '/register') {
      return res.render('register', { error: 'Trop de tentatives. Réessayez dans 15 minutes.' });
    }
    res.status(429).send('Trop de tentatives. Veuillez réessayer dans 15 minutes.');
  }
});

// SECURITY: Stricter rate limit on registration (console code brute-force protection)
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // Max 5 registration attempts per hour per IP
  standardHeaders: true,
  legacyHeaders: false,
  handler: function(req, res) {
    res.render('register', { error: 'Trop de tentatives d\'inscription. Réessayez dans 1 heure.' });
  }
});

router.get('/login', function(req, res) {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  res.render('login', { error: req.query.error || null, message: req.query.message || null });
});

router.post('/login', authLimiter, async function(req, res) {
  var username = req.body.username;
  var password = req.body.password;
  if (!username || !password) {
    return res.render('login', { error: 'Nom d\'utilisateur et mot de passe requis.', message: null });
  }

  try {
    var user = await db.verifyUser(username, password);
    if (!user) {
      return res.render('login', { error: 'Identifiants invalides.', message: null });
    }

    req.session.userId = user.id;
    req.session.username = user.username;
    res.redirect('/');
  } catch (err) {
    res.render('login', { error: 'Erreur lors de la connexion: ' + err.message, message: null });
  }
});

router.get('/register', function(req, res) {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  res.render('register', { error: req.query.error || null });
});

router.post('/register', registerLimiter, async function(req, res) {
  var username = req.body.username;
  var password = req.body.password;
  var consoleCode = req.body.consoleCode;

  if (!username || !password || !consoleCode) {
    return res.render('register', {
      error: 'Tous les champs sont requis (nom d\'utilisateur, mot de passe et code console).'
    });
  }

  if (username.trim().length < 3) {
    return res.render('register', {
      error: 'Le nom d\'utilisateur doit comporter au moins 3 caractères.'
    });
  }

  if (password.length < 8) {
    return res.render('register', {
      error: 'Le mot de passe doit comporter au moins 8 caractères.'
    });
  }

  // CRITICAL REQUIREMENT: Check console code!
  if (!db.verifyConsoleCode(consoleCode)) {
    return res.render('register', {
      error: 'Code console invalide. Vous devez renseigner le code secret affiché dans la console du serveur OvernodeApp-Updater.'
    });
  }

  try {
    var user = await db.createUser(username, password);
    req.session.userId = user.id;
    req.session.username = user.username;
    res.redirect('/?welcome=1');
  } catch (err) {
    res.render('register', { error: err.message });
  }
});

router.get('/logout', function(req, res) {
  req.session = null;
  res.redirect('/auth/login?message=Vous+%C3%AAtes+d%C3%A9connect%C3%A9');
});

module.exports = router;
