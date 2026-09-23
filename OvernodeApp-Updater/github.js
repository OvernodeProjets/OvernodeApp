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

function getHeaders(customToken) {
  const token = customToken || GITHUB_TOKEN;
  const headers = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'OvernodeApp-Updater'
  };
  if (token && token.trim().length > 0) {
    headers['Authorization'] = `Bearer ${token.trim()}`;
  }
  return headers;
}

async function fetchLatestCommits(token) {
  try {
    const url = `https://api.github.com/repos/${GITHUB_REPO}/commits?per_page=10`;
    const res = await axios.get(url, { headers: getHeaders(token), timeout: 8000 });
    if (Array.isArray(res.data)) {
      return res.data.map(c => ({
        sha: c.sha,
        shortSha: c.sha.substring(0, 7),
        message: c.commit.message,
        authorName: c.commit.author ? c.commit.author.name : 'Inconnu',
        authorEmail: c.commit.author ? c.commit.author.email : '',
        date: c.commit.author ? c.commit.author.date : new Date().toISOString(),
        htmlUrl: c.html_url
      }));
    }
  } catch (err) {
    console.warn(`[GitHub] Unable to fetch commits from ${GITHUB_REPO}: ${err.message}`);
  }
  return [];
}

async function fetchGitHubReleases(token) {
  const releasesList = [];

  // 1. Try to fetch official GitHub Releases
  try {
    const url = `https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=15`;
    const res = await axios.get(url, { headers: getHeaders(token), timeout: 8000 });
    
    if (Array.isArray(res.data) && res.data.length > 0) {
      res.data.forEach(r => {
        const dmgAsset = r.assets.find(a => a.name.endsWith('.dmg'));
        const zipAsset = r.assets.find(a => a.name.endsWith('.zip'));
        const chosenAsset = dmgAsset || zipAsset;
        releasesList.push({
          id: r.id,
          tag: r.tag_name,
          version: r.tag_name.replace(/^v/, ''),
          name: r.name || r.tag_name,
          body: r.body || '',
          publishedAt: r.published_at || r.created_at,
          downloadUrl: chosenAsset ? chosenAsset.browser_download_url : (r.tarball_url || ''),
          dmgUrl: dmgAsset ? dmgAsset.browser_download_url : null,
          zipUrl: zipAsset ? zipAsset.browser_download_url : null,
          assetId: chosenAsset ? chosenAsset.id : null,
          dmgAssetId: dmgAsset ? dmgAsset.id : null,
          zipAssetId: zipAsset ? zipAsset.id : null,
          assetName: chosenAsset ? chosenAsset.name : 'Archive',
          assetSize: chosenAsset ? chosenAsset.size : 0,
          htmlUrl: r.html_url,
          isRelease: true
        });
      });
    }
  } catch (err) {
    console.warn(`[GitHub] Unable to fetch releases from ${GITHUB_REPO}: ${err.message}`);
  }

  // 2. Fetch latest commits to ensure we always show the newest GitHub state
  const commits = await fetchLatestCommits(token);
  if (commits.length > 0) {
    const latestCommit = commits[0];
    
    // Check if we should derive a release from the latest commit
    const hasMatchingRelease = releasesList.some(r => r.body.includes(latestCommit.shortSha) || r.name.includes(latestCommit.shortSha));
    if (!hasMatchingRelease) {
      const commitTitle = latestCommit.message.split('\n')[0];
      const derivedVersion = '1.1.0';
      releasesList.unshift({
        id: 'commit-' + latestCommit.shortSha,
        tag: 'commit-' + latestCommit.shortSha,
        version: derivedVersion,
        name: `Commit ${latestCommit.shortSha} : ${commitTitle}`,
        body: `• ${latestCommit.message}\n• Auteur: ${latestCommit.authorName}\n• Commit: ${latestCommit.shortSha}`,
        publishedAt: latestCommit.date,
        downloadUrl: `https://github.com/${GITHUB_REPO}/releases/download/v${derivedVersion}/Overnode-v${derivedVersion}-macOS-arm64.dmg`,
        dmgUrl: `https://github.com/${GITHUB_REPO}/releases/download/v${derivedVersion}/Overnode-v${derivedVersion}-macOS-arm64.dmg`,
        zipUrl: `https://github.com/${GITHUB_REPO}/releases/download/v${derivedVersion}/Overnode-v${derivedVersion}-macOS-arm64.zip`,
        assetName: `Overnode-v${derivedVersion}-macOS-arm64.dmg`,
        assetSize: 15400000,
        htmlUrl: latestCommit.htmlUrl,
        isCommit: true,
        shortSha: latestCommit.shortSha
      });
    }
  }

  return releasesList;
}

module.exports = {
  GITHUB_REPO,
  GITHUB_TOKEN,
  getHeaders,
  compareVersions,
  fetchLatestCommits,
  fetchGitHubReleases
};

