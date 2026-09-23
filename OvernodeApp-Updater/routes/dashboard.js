const express = require('express');
const router = express.Router();
const db = require('../db');
const github = require('../github');

function requireAuth(req, res, next) {
  if (!req.session || !req.session.userId) {
    return res.redirect('/auth/login');
  }
  next();
}

router.use(requireAuth);

router.get('/', async (req, res) => {
  try {
    const deployment = db.getDeployment();
    const stats = db.getStats();
    
    // Fetch both commits and releases
    const commits = await github.fetchLatestCommits();
    const releases = await github.fetchGitHubReleases();

    const latestRelease = releases[0] || null;
    const latestCommit = commits[0] || null;
    
    let comparison = 0;
    if (latestRelease) {
      comparison = github.compareVersions(latestRelease.version, deployment.currentVersion);
    }

    res.render('dashboard', {
      user: { id: req.session.userId, username: req.session.username },
      deployment,
      stats,
      releases,
      commits,
      latestRelease,
      latestCommit,
      hasNewerRelease: comparison > 0 || (latestCommit && latestCommit.shortSha && !deployment.releaseNotes.includes(latestCommit.shortSha)),
      repo: github.GITHUB_REPO,
      successMessage: req.query.success || null,
      errorMessage: req.query.error || null
    });
  } catch (err) {
    console.error('[Dashboard] Error rendering dashboard:', err);
    res.status(500).send('Erreur interne: ' + err.message);
  }
});

// "Push to app" Action
router.post('/deploy', (req, res) => {
  const { version, downloadUrl, releaseNotes, sha256, mandatory } = req.body;

  if (!version || !downloadUrl) {
    return res.redirect('/?error=Version+et+URL+de+t%C3%A9l%C3%A9chargement+requises');
  }

  try {
    db.pushNewVersion({
      version,
      downloadUrl,
      releaseNotes,
      sha256,
      mandatory: mandatory === 'on' || mandatory === 'true',
      pushedBy: req.session.username || 'admin'
    });

    console.log(`[Deployment] 🚀 New version v${version} pushed to app by ${req.session.username}`);
    res.redirect(`/?success=Version+v${encodeURIComponent(version)}+d%C3%A9ploy%C3%A9e+avec+succ%C3%A8s+sur+l%27application`);
  } catch (err) {
    res.redirect('/?error=' + encodeURIComponent(err.message));
  }
});

module.exports = router;

