const express = require('express');
const router = express.Router();
const db = require('../db');
const github = require('../github');

// macOS App checks for updates:
// GET /api/v1/update/check?version=1.0.0&platform=darwin-arm64
router.get('/v1/update/check', (req, res) => {
  const clientVersion = (req.query.version || '0.0.0').trim();
  const clientPlatform = (req.query.platform || 'darwin-arm64').trim();

  // Log stats
  db.recordUpdateCheck(clientVersion, clientPlatform);

  const deployment = db.getDeployment();
  const latestVersion = deployment.currentVersion;

  const comparison = github.compareVersions(latestVersion, clientVersion);
  const updateAvailable = comparison > 0;

  res.json({
    updateAvailable,
    clientVersion,
    latestVersion,
    downloadUrl: deployment.downloadUrl,
    releaseNotes: deployment.releaseNotes,
    mandatory: Boolean(deployment.mandatory),
    sha256: deployment.sha256 || '',
    publishedAt: deployment.publishedAt,
    platform: clientPlatform
  });
});

// Current deployment info
router.get('/v1/update/current', (req, res) => {
  const deployment = db.getDeployment();
  res.json(deployment);
});

// Global updater stats
router.get('/v1/update/stats', (req, res) => {
  const stats = db.getStats();
  res.json(stats);
});

module.exports = router;

