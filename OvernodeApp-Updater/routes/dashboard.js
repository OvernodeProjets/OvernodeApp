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
    const allDeployments = db.getAllDeployments();
    const macDeployment = allDeployments.macos;
    const winDeployment = allDeployments.windows;
    const stats = db.getStats();
    
    // Fetch both commits and releases
    const commits = await github.fetchLatestCommits();
    const releases = await github.fetchGitHubReleases();

    const latestRelease = releases[0] || null;
    const latestCommit = commits[0] || null;

    // Detect latest platform-specific releases
    const latestMacRelease = releases.find(r => r.hasMacAsset || r.dmgUrl || r.macZipUrl) || null;
    const latestWinRelease = releases.find(r => r.hasWinAsset || r.msiUrl || r.winZipUrl || r.windowsDownloadUrl) || null;
    
    const macComparison = latestMacRelease ? github.compareVersions(latestMacRelease.version, macDeployment.currentVersion) : 0;
    const winComparison = latestWinRelease ? github.compareVersions(latestWinRelease.version, winDeployment.currentVersion) : 0;

    const activeTab = req.query.platform || 'macos'; // 'macos', 'windows', 'all'

    res.render('dashboard', {
      user: { id: req.session.userId, username: req.session.username },
      deployment: macDeployment,
      macDeployment,
      winDeployment,
      stats,
      releases,
      commits,
      latestRelease,
      latestMacRelease,
      latestWinRelease,
      latestCommit,
      hasNewerMacRelease: macComparison > 0,
      hasNewerWinRelease: winComparison > 0,
      activeTab,
      activeSection: req.query.section || 'deploy',
      godPackUsers: db.getGodPackUsers(),
      repo: github.GITHUB_REPO,
      successMessage: req.query.success || null,
      errorMessage: req.query.error || null
    });
  } catch (err) {
    console.error('[Dashboard] Error rendering dashboard:', err);
    res.status(500).send('Erreur interne: ' + err.message);
  }
});

// "Push to app" Action (supports platform: 'macos', 'windows', or 'all')
router.post('/deploy', (req, res) => {
  const { platform, version, downloadUrl, windowsDownloadUrl, releaseNotes, sha256, mandatory } = req.body;

  const targetPlatform = platform || 'all';

  if (!version || (!downloadUrl && !windowsDownloadUrl)) {
    return res.redirect('/?platform=' + encodeURIComponent(targetPlatform) + '&error=Version+et+URL+de+t%C3%A9l%C3%A9chargement+requises');
  }

  try {
    db.pushNewVersion({
      platform: targetPlatform,
      version,
      downloadUrl: downloadUrl || windowsDownloadUrl,
      windowsDownloadUrl: windowsDownloadUrl || downloadUrl,
      releaseNotes,
      sha256,
      mandatory: mandatory === 'on' || mandatory === 'true',
      pushedBy: req.session.username || 'admin'
    });

    const platLabel = targetPlatform === 'macos' ? 'macOS' : (targetPlatform === 'windows' ? 'Windows' : 'macOS & Windows');
    console.log(`[Deployment] 🚀 New version v${version} pushed for ${platLabel} by ${req.session.username}`);
    res.redirect(`/?platform=${encodeURIComponent(targetPlatform)}&success=Version+v${encodeURIComponent(version)}+d%C3%A9ploy%C3%A9e+avec+succ%C3%A8s+pour+${encodeURIComponent(platLabel)}`);
  } catch (err) {
    res.redirect(`/?platform=${encodeURIComponent(targetPlatform)}&error=` + encodeURIComponent(err.message));
  }
});

// "Add God Pack Discord ID" Action
router.post('/godpack/add', (req, res) => {
  const { discordId, note } = req.body;
  const cleanId = String(discordId || '').trim();
  if (!cleanId) {
    return res.redirect('/?section=godpack&error=' + encodeURIComponent('Identifiant Discord requis.'));
  }

  try {
    db.addGodPackUser(cleanId, note, req.session.username || 'admin');
    console.log(`[GodPack] 👑 Added Discord ID ${cleanId} to God Pack VIPs by ${req.session.username}`);
    res.redirect('/?section=godpack&success=' + encodeURIComponent(`ID Discord ${cleanId} ajouté avec succès au Pack God.`));
  } catch (err) {
    res.redirect('/?section=godpack&error=' + encodeURIComponent(err.message));
  }
});

// "Remove God Pack Discord ID" Action
router.post('/godpack/remove', (req, res) => {
  const { discordId } = req.body;
  const cleanId = String(discordId || '').trim();
  if (!cleanId) {
    return res.redirect('/?section=godpack&error=' + encodeURIComponent('Identifiant Discord requis.'));
  }

  try {
    db.removeGodPackUser(cleanId);
    console.log(`[GodPack] 🗑️ Removed Discord ID ${cleanId} from God Pack VIPs by ${req.session.username}`);
    res.redirect('/?section=godpack&success=' + encodeURIComponent(`ID Discord ${cleanId} retiré du Pack God.`));
  } catch (err) {
    res.redirect('/?section=godpack&error=' + encodeURIComponent(err.message));
  }
});

module.exports = router;

