const express = require('express');
const router = express.Router();
const axios = require('axios');
const db = require('../db');
const github = require('../github');

function isWindowsPlatform(platform) {
  if (!platform) return false;
  const p = platform.toLowerCase();
  return p.startsWith('win') || p.includes('windows');
}

// GET /api/v1/update/check?version=1.0.0&platform=darwin-arm64 (macOS)
// GET /api/v1/update/check?version=1.0.0&platform=win-x64 (Windows)
router.get('/v1/update/check', async (req, res) => {
  const clientVersion = (req.query.version || '0.0.0').trim();
  const clientPlatform = (req.query.platform || 'darwin-arm64').trim();
  const isWindows = isWindowsPlatform(clientPlatform);

  // Log stats
  db.recordUpdateCheck(clientVersion, clientPlatform);

  const deployment = db.getDeployment(clientPlatform);
  let latestVersion = deployment.currentVersion;
  let rawDownloadUrl = deployment.downloadUrl;
  let releaseNotes = deployment.releaseNotes;
  let sha256 = deployment.sha256 || '';
  let mandatory = Boolean(deployment.mandatory);
  let publishedAt = deployment.publishedAt;

  // Check if GitHub has a newer release asset
  try {
    const releases = await github.fetchGitHubReleases();
    const platformReleases = releases.filter(r => r.isRelease && (isWindows ? r.hasWinAsset : r.hasMacAsset));
    platformReleases.sort((a, b) => github.compareVersions(b.version, a.version));
    const latestPlatformRel = platformReleases[0];
    if (latestPlatformRel) {
      if (github.compareVersions(latestPlatformRel.version, latestVersion) > 0 || !rawDownloadUrl) {
        latestVersion = latestPlatformRel.version;
        rawDownloadUrl = isWindows 
          ? (latestPlatformRel.msiUrl || latestPlatformRel.winZipUrl || latestPlatformRel.windowsDownloadUrl) 
          : (latestPlatformRel.dmgUrl || latestPlatformRel.macZipUrl || latestPlatformRel.macDownloadUrl || latestPlatformRel.downloadUrl);
        releaseNotes = latestPlatformRel.body || releaseNotes;
        publishedAt = latestPlatformRel.publishedAt || publishedAt;
      }
    }
  } catch (err) {
    console.warn('[Update Check] GitHub releases check fallback:', err.message);
  }

  const comparison = github.compareVersions(latestVersion, clientVersion);
  const updateAvailable = comparison > 0;

  // Use the updater server direct download proxy to allow downloading from private GitHub repository without 404
  const host = req.get('host') || 'zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr';
  const proto = req.get('x-forwarded-proto') || req.protocol || 'https';
  const defaultType = isWindows ? 'msi' : 'dmg';
  const proxyDownloadUrl = `${proto}://${host}/api/v1/update/download?platform=${encodeURIComponent(clientPlatform)}&type=${defaultType}`;

  res.json({
    updateAvailable,
    clientVersion,
    latestVersion,
    downloadUrl: proxyDownloadUrl,
    rawDownloadUrl,
    releaseNotes,
    mandatory,
    sha256,
    publishedAt,
    platform: clientPlatform
  });
});

// Proxy download endpoint: streams release assets directly from GitHub using server token
router.get('/v1/update/download', async (req, res) => {
  const clientPlatform = (req.query.platform || '').trim();
  const isWindows = isWindowsPlatform(clientPlatform);
  const deployment = db.getDeployment(clientPlatform);
  const requestedType = req.query.type || (isWindows ? 'msi' : 'dmg'); // 'msi', 'dmg', 'zip', 'exe'

  try {
    const releases = await github.fetchGitHubReleases();
    const platformReleases = releases.filter(r => r.isRelease && (isWindows ? r.hasWinAsset : r.hasMacAsset));
    platformReleases.sort((a, b) => github.compareVersions(b.version, a.version));

    // Prefer release matching deployment.currentVersion, or latest available for this platform
    const rel = platformReleases.find(r => r.version === deployment.currentVersion) || platformReleases[0];
    
    if (rel && rel.id && typeof rel.id === 'number') {
      let targetAssetId = null;
      let filename = null;
      let contentType = null;

      if (isWindows) {
        if (requestedType === 'zip') {
          targetAssetId = rel.winZipAssetId || rel.msiAssetId;
          filename = `Overnode-v${rel.version}-Windows-x64.zip`;
          contentType = 'application/zip';
        } else if (requestedType === 'exe') {
          targetAssetId = rel.exeAssetId || rel.msiAssetId;
          filename = `Overnode-v${rel.version}-Windows-x64.exe`;
          contentType = 'application/vnd.microsoft.portable-executable';
        } else {
          // Default Windows installer is MSI
          targetAssetId = rel.msiAssetId || rel.winZipAssetId;
          filename = `Overnode-v${rel.version}-Windows-x64.msi`;
          contentType = 'application/x-msi';
        }
      } else {
        // macOS
        if (requestedType === 'zip') {
          targetAssetId = rel.macZipAssetId || rel.dmgAssetId;
          filename = `Overnode-v${rel.version}-macOS-arm64.zip`;
          contentType = 'application/zip';
        } else {
          // Default macOS installer is DMG
          targetAssetId = rel.dmgAssetId || rel.macZipAssetId;
          filename = `Overnode-v${rel.version}-macOS-arm64.dmg`;
          contentType = 'application/x-apple-diskimage';
        }
      }
      
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

        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Content-Type', contentType);
        return ghResponse.data.pipe(res);
      }
    }
  } catch (err) {
    console.error('[Download Proxy] Error streaming asset from GitHub:', err.message);
  }

  // Fallback to configured URL
  if (deployment.downloadUrl) {
    return res.redirect(deployment.downloadUrl);
  }
  res.status(404).send('Mise à jour introuvable pour cette plateforme.');
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

// God Pack Verification API
// GET /api/v1/godpack/check/:discordId or GET /api/v1/godpack/check?discordId=...
router.get(['/v1/godpack/check/:discordId', '/v1/godpack/check'], (req, res) => {
  const discordId = (req.params.discordId || req.query.discordId || '').trim();
  if (!discordId) {
    return res.status(400).json({ error: 'Discord ID parameter required', hasGodPack: false });
  }
  const hasGodPack = db.isGodPackUser(discordId);
  res.json({
    discordId,
    hasGodPack
  });
});

// GET /api/v1/godpack/list
router.get('/v1/godpack/list', (req, res) => {
  const users = db.getGodPackUsers();
  res.json({
    total: users.length,
    users: users.map(u => ({ discordId: u.discordId, note: u.note }))
  });
});

module.exports = router;

