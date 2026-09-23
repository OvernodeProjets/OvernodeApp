const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/login', (req, res) => {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  res.render('login', { error: req.query.error || null, message: req.query.message || null });
});

router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.render('login', { error: 'Nom d\'utilisateur et mot de passe requis.', message: null });
  }

  try {
    const user = await db.verifyUser(username, password);
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

router.get('/register', (req, res) => {
  if (req.session && req.session.userId) {
    return res.redirect('/');
  }
  res.render('register', { error: req.query.error || null });
});

router.post('/register', async (req, res) => {
  const { username, password, consoleCode } = req.body;

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

  if (password.length < 6) {
    return res.render('register', {
      error: 'Le mot de passe doit comporter au moins 6 caractères.'
    });
  }

  // CRITICAL REQUIREMENT: Check console code!
  if (!db.verifyConsoleCode(consoleCode)) {
    return res.render('register', {
      error: '❌ Code console invalide. Vous devez renseigner le code secret affiché dans la console du serveur OvernodeApp-Updater.'
    });
  }

  try {
    const user = await db.createUser(username, password);
    req.session.userId = user.id;
    req.session.username = user.username;
    res.redirect('/?welcome=1');
  } catch (err) {
    res.render('register', { error: err.message });
  }
});

router.get('/logout', (req, res) => {
  req.session = null;
  res.redirect('/auth/login?message=Vous+%C3%AAtes+d%C3%A9connect%C3%A9');
});

module.exports = router;

