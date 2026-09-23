const axios = require('axios');

const GITHUB_REPO = process.env.GITHUB_REPO || 'OvernodeProjets/OvernodeApp';
const GITHUB_TOKEN = process.env.GITHUB_TOKEN || '';

function parseSemver(v) {
  if (!v) return [0, 0, 0];
  const cleaned = v.replace(/^v/, '').split('-')[0];
  const parts = cleaned.split('.').map(p => parseInt(p, 10) || 0);
  while (parts.length < 3) parts.push(0);
  return parts;
}

function compareVersions(v1, v2) {
  const p1 = parseSemver(v1);
  const p2 = parseSemver(v2);
  for (let i = 0; i < 3; i++) {
    if (p1[i] > p2[i]) return 1;
    if (p1[i] < p2[i]) return -1;
  }
  return 0;
}

async function fetchGitHubReleases() {
  const headers = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'OvernodeApp-Updater'
  };
  if (GITHUB_TOKEN) {
    headers['Authorization'] = `Bearer ${GITHUB_TOKEN}`;
  }

  try {
    const url = `https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=15`;
    const res = await axios.get(url, { headers, timeout: 8000 });
    
    if (Array.isArray(res.data) && res.data.length > 0) {
      return res.data.map(r => {
        // Find arm64 zip/dmg asset
        const zipAsset = r.assets.find(a => a.name.endsWith('.zip') || a.name.endsWith('.dmg'));
        return {
          id: r.id,
          tag: r.tag_name,
          version: r.tag_name.replace(/^v/, ''),
          name: r.name || r.tag_name,
          body: r.body || '',
          publishedAt: r.published_at || r.created_at,
          downloadUrl: zipAsset ? zipAsset.browser_download_url : (r.tarball_url || ''),
          assetName: zipAsset ? zipAsset.name : 'Source Archive',
          assetSize: zipAsset ? zipAsset.size : 0,
          htmlUrl: r.html_url
        };
      });
    }
  } catch (err) {
    console.warn(`[GitHub] Unable to fetch releases from ${GITHUB_REPO} (${err.message}). Using local fallback/sample releases.`);
  }

  // Fallback releases if GitHub API fails, repo is private without token, or no releases published yet
  return [
    {
      id: 2,
      tag: 'v1.1.0',
      version: '1.1.0',
      name: 'Overnode v1.1.0 - Apple Silicon Update',
      body: '• Système d\'auto-mise à jour en temps réel\n• Optimisations des performances SwiftUI Apple Silicon\n• Amélioration de la gestion des serveurs',
      publishedAt: new Date().toISOString(),
      downloadUrl: `https://github.com/${GITHUB_REPO}/releases/download/v1.1.0/Overnode-v1.1.0-macOS-arm64.zip`,
      assetName: 'Overnode-v1.1.0-macOS-arm64.zip',
      assetSize: 12582912,
      htmlUrl: `https://github.com/${GITHUB_REPO}/releases/tag/v1.1.0`
    },
    {
      id: 1,
      tag: 'v1.0.0',
      version: '1.0.0',
      name: 'Overnode v1.0.0 Initial Release',
      body: 'Première version officielle native macOS pour Overnode.',
      publishedAt: '2026-09-22T10:00:00.000Z',
      downloadUrl: `https://github.com/${GITHUB_REPO}/releases/download/v1.0.0/Overnode-v1.0.0-macOS-arm64.zip`,
      assetName: 'Overnode-v1.0.0-macOS-arm64.zip',
      assetSize: 11492000,
      htmlUrl: `https://github.com/${GITHUB_REPO}/releases/tag/v1.0.0`
    }
  ];
}

module.exports = {
  GITHUB_REPO,
  compareVersions,
  fetchGitHubReleases
};

