const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const DATA_DIR = path.join(__dirname, 'data');
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const SETTINGS_FILE = path.join(DATA_DIR, 'settings.json');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const DEPLOYMENT_FILE = path.join(DATA_DIR, 'deployment.json');
const STATS_FILE = path.join(DATA_DIR, 'stats.json');
const GODPACK_FILE = path.join(DATA_DIR, 'godpack.json');

function readJSON(file, defaultVal) {
  try {
    if (fs.existsSync(file)) {
      return JSON.parse(fs.readFileSync(file, 'utf8'));
    }
  } catch (err) {
    console.error('[DB] Error reading ' + file + ':', err.message);
  }
  return defaultVal;
}

function writeJSON(file, data) {
  const tmp = file + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), 'utf8');
  fs.renameSync(tmp, file);
}

// SECURITY: Hash a console code for secure storage
function hashCode(code) {
  return crypto.createHash('sha256').update(code.trim().toUpperCase()).digest('hex');
}

// 1. Console Code Management
function getOrInitConsoleCode() {
  // Allow override from environment
  const envCode = process.env.CONSOLE_CODE;
  if (envCode && envCode.trim().length > 0) {
    // Store hash, return plaintext for this session
    const settings = readJSON(SETTINGS_FILE, {});
    settings.consoleCodeHash = hashCode(envCode);
    settings.updatedAt = new Date().toISOString();
    delete settings.consoleCode; // Remove any legacy plaintext
    writeJSON(SETTINGS_FILE, settings);
    return envCode.trim();
  }

  const settings = readJSON(SETTINGS_FILE, {});

  // SECURITY MIGRATION: If legacy plaintext code exists, hash it and remove plaintext
  if (settings.consoleCode && !settings.consoleCodeHash) {
    const code = settings.consoleCode;
    settings.consoleCodeHash = hashCode(code);
    delete settings.consoleCode;
    settings.updatedAt = new Date().toISOString();
    writeJSON(SETTINGS_FILE, settings);
    return code;
  }

  // If hash exists but no plaintext, generate a fresh code
  // (code is only shown at startup, hash is stored)
  const randPart1 = crypto.randomBytes(2).toString('hex').toUpperCase();
  const randPart2 = crypto.randomBytes(2).toString('hex').toUpperCase();
  const newCode = 'UP-' + randPart1 + '-' + randPart2;

  settings.consoleCodeHash = hashCode(newCode);
  delete settings.consoleCode; // Ensure no plaintext
  if (!settings.createdAt) settings.createdAt = new Date().toISOString();
  settings.updatedAt = new Date().toISOString();
  writeJSON(SETTINGS_FILE, settings);

  return newCode;
}

const CONSOLE_CODE = getOrInitConsoleCode();

// SECURITY: Only display console code outside production
if (process.env.NODE_ENV !== 'production') {
  console.log('');
  console.log('============================================================');
  console.log(' [OvernodeApp-Updater] CONSOLE SETUP CODE:');
  console.log('  >> ' + CONSOLE_CODE + ' <<');
  console.log(' (Use this secret code during web registration)');
  console.log('============================================================');
  console.log('');
} else {
  console.log('[OvernodeApp-Updater] Console code initialized (hidden in production). Set CONSOLE_CODE env var to override.');
}

// 2. User Management
function getUsers() {
  return readJSON(USERS_FILE, []);
}

function findUserByUsername(username) {
  const users = getUsers();
  return users.find(function(u) { return u.username.toLowerCase() === username.trim().toLowerCase(); });
}

async function createUser(username, password) {
  const users = getUsers();
  const existing = findUserByUsername(username);
  if (existing) {
    throw new Error('Cet utilisateur existe deja.');
  }

  const salt = await bcrypt.genSalt(12);
  const passwordHash = await bcrypt.hash(password, salt);

  const newUser = {
    id: crypto.randomUUID(),
    username: username.trim(),
    passwordHash: passwordHash,
    createdAt: new Date().toISOString()
  };

  users.push(newUser);
  writeJSON(USERS_FILE, users);
  return { id: newUser.id, username: newUser.username };
}

async function verifyUser(username, password) {
  const user = findUserByUsername(username);
  if (!user) return null;
  const match = await bcrypt.compare(password, user.passwordHash);
  if (!match) return null;
  return { id: user.id, username: user.username };
}

// SECURITY: Verify console code using constant-time hash comparison
function verifyConsoleCode(providedCode) {
  if (!providedCode) return false;
  
  // Check against in-memory code for this session
  if (CONSOLE_CODE && providedCode.trim().toUpperCase() === CONSOLE_CODE.trim().toUpperCase()) {
    return true;
  }
  
  // Also verify against stored hash (constant-time via hash comparison)
  const settings = readJSON(SETTINGS_FILE, {});
  if (settings.consoleCodeHash) {
    const inputHash = hashCode(providedCode);
    return crypto.timingSafeEqual(
      Buffer.from(inputHash, 'hex'),
      Buffer.from(settings.consoleCodeHash, 'hex')
    );
  }
  return false;
}

// 3. Deployment Management
const DEFAULT_DEPLOYMENT = {
  currentVersion: '1.0.0',
  downloadUrl: 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.0.0/Overnode-v1.0.0-macOS-arm64.dmg',
  windowsDownloadUrl: 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.0.0/Overnode-v1.0.0-Windows-x64.msi',
  releaseNotes: 'Version initiale stable de l\'application Overnode.',
  publishedAt: new Date().toISOString(),
  sha256: '',
  mandatory: false,
  pushedBy: 'system',
  history: []
};

function isWindowsPlatform(platform) {
  if (!platform) return false;
  const p = platform.toLowerCase();
  return p.startsWith('win') || p.includes('windows');
}

function getDeployment(platform) {
  const deployment = readJSON(DEPLOYMENT_FILE, DEFAULT_DEPLOYMENT);
  if (!deployment.platforms) deployment.platforms = {};

  const isWin = isWindowsPlatform(platform);

  if (isWin) {
    const winPlat = deployment.platforms.windows || {};
    let winUrl = winPlat.downloadUrl || deployment.windowsDownloadUrl;
    if (!winUrl && deployment.windows && deployment.windows.downloadUrl) {
      winUrl = deployment.windows.downloadUrl;
    }
    if (!winUrl && deployment.downloadUrl) {
      winUrl = deployment.downloadUrl
        .replace(/\.(dmg|zip)$/i, '.msi')
        .replace(/macOS-arm64/i, 'Windows-x64');
    }
    const winVer = (winPlat.currentVersion || deployment.windowsVersion || deployment.currentVersion || '1.0.0').replace(/^v/, '');
    return {
      currentVersion: winVer,
      downloadUrl: winUrl || deployment.downloadUrl,
      rawDownloadUrl: winUrl || deployment.downloadUrl,
      releaseNotes: winPlat.releaseNotes || deployment.releaseNotes || ('Mise a jour v' + winVer),
      sha256: winPlat.sha256 || deployment.windowsSha256 || deployment.sha256 || '',
      mandatory: Boolean(winPlat.mandatory ?? deployment.mandatory),
      publishedAt: winPlat.publishedAt || deployment.publishedAt,
      pushedBy: winPlat.pushedBy || deployment.pushedBy || 'admin',
      platform: 'win-x64'
    };
  }

  // macOS / Default
  const macPlat = deployment.platforms.macos || {};
  let macUrl = macPlat.downloadUrl || deployment.downloadUrl;
  // Never serve a Windows installer (.msi) as macOS downloadUrl
  if (macUrl && (macUrl.toLowerCase().endsWith('.msi') || macUrl.includes('Windows-x64'))) {
    macUrl = macPlat.downloadUrl && !macPlat.downloadUrl.toLowerCase().endsWith('.msi') ? macPlat.downloadUrl : '';
  }
  const macVer = (macPlat.currentVersion || (deployment.downloadUrl && !deployment.downloadUrl.toLowerCase().endsWith('.msi') ? deployment.currentVersion : '1.0.0')).replace(/^v/, '');
  return {
    currentVersion: macVer,
    downloadUrl: macUrl,
    rawDownloadUrl: macUrl,
    windowsDownloadUrl: deployment.windowsDownloadUrl || deployment.platforms?.windows?.downloadUrl || null,
    releaseNotes: macPlat.releaseNotes || deployment.releaseNotes || ('Mise a jour v' + macVer),
    sha256: macPlat.sha256 || deployment.sha256 || '',
    mandatory: Boolean(macPlat.mandatory ?? deployment.mandatory),
    publishedAt: macPlat.publishedAt || deployment.publishedAt,
    pushedBy: macPlat.pushedBy || deployment.pushedBy || 'admin',
    platform: 'darwin-arm64'
  };
}

function getAllDeployments() {
  const deployment = readJSON(DEPLOYMENT_FILE, DEFAULT_DEPLOYMENT);
  return {
    macos: getDeployment('darwin-arm64'),
    windows: getDeployment('win-x64'),
    root: deployment
  };
}

function pushNewVersion(opts) {
  var targetPlatform = (opts.platform || 'all').toLowerCase(); // 'macos', 'windows', or 'all'
  var version = (opts.version || '').replace(/^v/, '').trim();
  var downloadUrl = opts.downloadUrl;
  var windowsDownloadUrl = opts.windowsDownloadUrl;
  var releaseNotes = opts.releaseNotes;
  var sha256 = opts.sha256 || '';
  var mandatory = Boolean(opts.mandatory);
  var pushedBy = opts.pushedBy || 'admin';

  const deployment = readJSON(DEPLOYMENT_FILE, DEFAULT_DEPLOYMENT);
  if (!deployment.platforms) deployment.platforms = {};
  if (!deployment.history) deployment.history = [];

  const now = new Date().toISOString();

  if (targetPlatform === 'macos' || targetPlatform === 'darwin' || targetPlatform === 'darwin-arm64') {
    // macOS only push
    deployment.history.unshift({
      platform: 'macos',
      version: deployment.platforms?.macos?.currentVersion || deployment.currentVersion,
      downloadUrl: deployment.platforms?.macos?.downloadUrl || deployment.downloadUrl,
      releaseNotes: deployment.platforms?.macos?.releaseNotes || deployment.releaseNotes,
      publishedAt: deployment.platforms?.macos?.publishedAt || deployment.publishedAt,
      pushedBy: deployment.platforms?.macos?.pushedBy || 'system'
    });

    deployment.currentVersion = version;
    deployment.downloadUrl = downloadUrl;
    deployment.releaseNotes = releaseNotes || ('Mise a jour macOS v' + version);
    deployment.sha256 = sha256;
    deployment.mandatory = mandatory;
    deployment.publishedAt = now;
    deployment.pushedBy = pushedBy;

    deployment.platforms.macos = {
      currentVersion: version,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes || ('Mise a jour macOS v' + version),
      sha256: sha256,
      mandatory: mandatory,
      publishedAt: now,
      pushedBy: pushedBy
    };
  } else if (targetPlatform === 'windows' || targetPlatform === 'win' || targetPlatform === 'win-x64') {
    // Windows only push
    const targetWinUrl = windowsDownloadUrl || downloadUrl;
    deployment.history.unshift({
      platform: 'windows',
      version: deployment.platforms?.windows?.currentVersion || deployment.windowsVersion || deployment.currentVersion,
      downloadUrl: deployment.platforms?.windows?.downloadUrl || deployment.windowsDownloadUrl || targetWinUrl,
      releaseNotes: deployment.platforms?.windows?.releaseNotes || deployment.releaseNotes,
      publishedAt: deployment.platforms?.windows?.publishedAt || deployment.publishedAt,
      pushedBy: deployment.platforms?.windows?.pushedBy || 'system'
    });

    deployment.windowsDownloadUrl = targetWinUrl;
    deployment.windowsVersion = version;

    deployment.platforms.windows = {
      currentVersion: version,
      downloadUrl: targetWinUrl,
      releaseNotes: releaseNotes || ('Mise a jour Windows v' + version),
      sha256: sha256,
      mandatory: mandatory,
      publishedAt: now,
      pushedBy: pushedBy
    };
  } else {
    // Both platforms push
    deployment.history.unshift({
      platform: 'all',
      version: deployment.currentVersion,
      downloadUrl: deployment.downloadUrl,
      windowsDownloadUrl: deployment.windowsDownloadUrl || null,
      releaseNotes: deployment.releaseNotes,
      publishedAt: deployment.publishedAt,
      pushedBy: deployment.pushedBy || 'system'
    });

    deployment.currentVersion = version;
    deployment.downloadUrl = downloadUrl;
    if (windowsDownloadUrl) {
      deployment.windowsDownloadUrl = windowsDownloadUrl;
    } else if (downloadUrl && downloadUrl.endsWith('.dmg')) {
      deployment.windowsDownloadUrl = downloadUrl.replace(/\.dmg$/, '.msi').replace(/macOS-arm64/i, 'Windows-x64');
    }
    deployment.windowsVersion = version;
    deployment.releaseNotes = releaseNotes || ('Mise a jour v' + version);
    deployment.sha256 = sha256;
    deployment.mandatory = mandatory;
    deployment.publishedAt = now;
    deployment.pushedBy = pushedBy;

    deployment.platforms.macos = {
      currentVersion: version,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes || ('Mise a jour macOS v' + version),
      sha256: sha256,
      mandatory: mandatory,
      publishedAt: now,
      pushedBy: pushedBy
    };

    deployment.platforms.windows = {
      currentVersion: version,
      downloadUrl: deployment.windowsDownloadUrl || downloadUrl,
      releaseNotes: releaseNotes || ('Mise a jour Windows v' + version),
      sha256: sha256,
      mandatory: mandatory,
      publishedAt: now,
      pushedBy: pushedBy
    };
  }

  if (deployment.history.length > 30) {
    deployment.history = deployment.history.slice(0, 30);
  }

  writeJSON(DEPLOYMENT_FILE, deployment);
  return deployment;
}

// 4. Stats Management
function recordUpdateCheck(clientVersion, clientPlatform) {
  const stats = readJSON(STATS_FILE, { totalChecks: 0, lastCheckAt: null, versions: {}, platforms: {} });
  stats.totalChecks = (stats.totalChecks || 0) + 1;
  stats.lastCheckAt = new Date().toISOString();
  const vKey = clientVersion || 'unknown';
  stats.versions[vKey] = (stats.versions[vKey] || 0) + 1;
  const pKey = clientPlatform || 'unknown';
  if (!stats.platforms) stats.platforms = {};
  stats.platforms[pKey] = (stats.platforms[pKey] || 0) + 1;
  writeJSON(STATS_FILE, stats);
}

function getStats() {
  return readJSON(STATS_FILE, { totalChecks: 0, lastCheckAt: null, versions: {}, platforms: {} });
}

// 5. God Pack Discord IDs Management
function getGodPackUsers() {
  const data = readJSON(GODPACK_FILE, []);
  return data.map(item => {
    if (typeof item === 'string') {
      return { discordId: item.trim(), note: '', addedBy: 'admin', addedAt: new Date().toISOString() };
    }
    return item;
  });
}

function addGodPackUser(discordId, note, addedBy) {
  const cleanId = String(discordId || '').trim();
  if (!cleanId) throw new Error('ID Discord requis.');
  const list = getGodPackUsers();
  const existingIndex = list.findIndex(u => u.discordId === cleanId);
  const now = new Date().toISOString();
  if (existingIndex >= 0) {
    list[existingIndex].note = note ? String(note).trim() : list[existingIndex].note;
    list[existingIndex].updatedAt = now;
  } else {
    list.unshift({
      discordId: cleanId,
      note: note ? String(note).trim() : '',
      addedBy: addedBy || 'admin',
      addedAt: now
    });
  }
  writeJSON(GODPACK_FILE, list);
  return list;
}

function removeGodPackUser(discordId) {
  const cleanId = String(discordId || '').trim();
  let list = getGodPackUsers();
  list = list.filter(u => u.discordId !== cleanId);
  writeJSON(GODPACK_FILE, list);
  return list;
}

function isGodPackUser(discordId) {
  if (!discordId) return false;
  const cleanId = String(discordId).trim();
  const list = getGodPackUsers();
  return list.some(u => u.discordId === cleanId);
}

module.exports = {
  CONSOLE_CODE: CONSOLE_CODE,
  verifyConsoleCode: verifyConsoleCode,
  createUser: createUser,
  verifyUser: verifyUser,
  getUsers: getUsers,
  getDeployment: getDeployment,
  getAllDeployments: getAllDeployments,
  pushNewVersion: pushNewVersion,
  recordUpdateCheck: recordUpdateCheck,
  getStats: getStats,
  getGodPackUsers: getGodPackUsers,
  addGodPackUser: addGodPackUser,
  removeGodPackUser: removeGodPackUser,
  isGodPackUser: isGodPackUser
};
