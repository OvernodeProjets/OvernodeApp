const express = require('express');
const router = express.Router();
const axios = require('axios');
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

  // Use the updater server direct download proxy to allow downloading from private GitHub repository without 404
  const host = req.get('host') || 'zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr';
  const proto = req.get('x-forwarded-proto') || req.protocol || 'https';
  const proxyDownloadUrl = `${proto}://${host}/api/v1/update/download`;

  res.json({
    updateAvailable,
    clientVersion,
    latestVersion,
    downloadUrl: proxyDownloadUrl,
    rawDownloadUrl: deployment.downloadUrl,
    releaseNotes: deployment.releaseNotes,
    mandatory: Boolean(deployment.mandatory),
    sha256: deployment.sha256 || '',
    publishedAt: deployment.publishedAt,
    platform: clientPlatform
  });
});

// Proxy download endpoint: streams release assets directly from GitHub using server token
router.get('/v1/update/download', async (req, res) => {
  const deployment = db.getDeployment();
  const requestedType = req.query.type || 'dmg'; // 'dmg' or 'zip'

  try {
    const releases = await github.fetchGitHubReleases();
    const rel = releases.find(r => r.isRelease && r.version === deployment.currentVersion) || releases.find(r => r.isRelease) || releases[0];
    
    if (rel && rel.id && typeof rel.id === 'number') {
      const targetAssetId = requestedType === 'zip' ? (rel.zipAssetId || rel.assetId) : (rel.dmgAssetId || rel.assetId);
      
      if (targetAssetId) {
        const streamUrl = `https://api.github.com/repos/${github.GITHUB_REPO}/releases/assets/${targetAssetId}`;
        const ghResponse = await axios.get(streamUrl, {
          headers: {
            ...github.getHeaders(),
            'Accept': 'application/octet-stream'
          },
          responseType: 'stream',
          timeout: 60000
        });

        const filename = (requestedType === 'zip') 
          ? `Overnode-v${deployment.currentVersion}-macOS-arm64.zip` 
          : `Overnode-v${deployment.currentVersion}-macOS-arm64.dmg`;

        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Content-Type', requestedType === 'zip' ? 'application/zip' : 'application/x-apple-diskimage');
        return ghResponse.data.pipe(res);
      }
    }
  } catch (err) {
    console.error('[Download Proxy] Error streaming asset from GitHub:', err.message);
  }

  // Fallback to configured URL
  res.redirect(deployment.downloadUrl);
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

