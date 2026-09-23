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

function readJSON(file, defaultVal) {
  try {
    if (fs.existsSync(file)) {
      return JSON.parse(fs.readFileSync(file, 'utf8'));
    }
  } catch (err) {
    console.error(`[DB] Error reading ${file}:`, err.message);
  }
  return defaultVal;
}

function writeJSON(file, data) {
  const tmp = file + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), 'utf8');
  fs.renameSync(tmp, file);
}

// 1. Console Code Management
function getOrInitConsoleCode() {
  const envCode = process.env.CONSOLE_CODE;
  if (envCode && envCode.trim().length > 0) {
    return envCode.trim();
  }

  const settings = readJSON(SETTINGS_FILE, {});
  if (settings.consoleCode) {
    return settings.consoleCode;
  }

  // Generate a friendly uppercase formatted code: UP-XXXX-XXXX
  const randPart1 = crypto.randomBytes(2).toString('hex').toUpperCase();
  const randPart2 = crypto.randomBytes(2).toString('hex').toUpperCase();
  const newCode = `UP-${randPart1}-${randPart2}`;

  settings.consoleCode = newCode;
  settings.createdAt = new Date().toISOString();
  writeJSON(SETTINGS_FILE, settings);

  return newCode;
}

const CONSOLE_CODE = getOrInitConsoleCode();

console.log('\n============================================================');
console.log(' [OvernodeApp-Updater] 🔑 CONSOLE SETUP CODE:');
console.log(` >> ${CONSOLE_CODE} <<`);
console.log(' (Use this secret code during web registration)');
console.log('============================================================\n');

// 2. User Management
function getUsers() {
  return readJSON(USERS_FILE, []);
}

function findUserByUsername(username) {
  const users = getUsers();
  return users.find(u => u.username.toLowerCase() === username.trim().toLowerCase());
}

async function createUser(username, password) {
  const users = getUsers();
  const existing = findUserByUsername(username);
  if (existing) {
    throw new Error('Cet utilisateur existe déjà.');
  }

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);

  const newUser = {
    id: crypto.randomUUID(),
    username: username.trim(),
    passwordHash,
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

function verifyConsoleCode(providedCode) {
  if (!providedCode) return false;
  return providedCode.trim().toUpperCase() === CONSOLE_CODE.trim().toUpperCase();
}

// 3. Deployment Management
const DEFAULT_DEPLOYMENT = {
  currentVersion: '1.0.0',
  downloadUrl: 'https://github.com/overnode-network/OvernodeApp/releases/download/v1.0.0/Overnode-v1.0.0-macOS-arm64.zip',
  releaseNotes: 'Version initiale stable de l\'application Overnode pour macOS Apple Silicon.',
  publishedAt: new Date().toISOString(),
  sha256: '',
  mandatory: false,
  pushedBy: 'system',
  history: []
};

function getDeployment() {
  return readJSON(DEPLOYMENT_FILE, DEFAULT_DEPLOYMENT);
}

function pushNewVersion({ version, downloadUrl, releaseNotes, sha256, mandatory, pushedBy }) {
  const deployment = getDeployment();

  // Save current into history before updating
  if (!deployment.history) deployment.history = [];
  deployment.history.unshift({
    version: deployment.currentVersion,
    downloadUrl: deployment.downloadUrl,
    releaseNotes: deployment.releaseNotes,
    publishedAt: deployment.publishedAt,
    pushedBy: deployment.pushedBy || 'system'
  });
  if (deployment.history.length > 20) {
    deployment.history = deployment.history.slice(0, 20);
  }

  deployment.currentVersion = version.replace(/^v/, '');
  deployment.downloadUrl = downloadUrl;
  deployment.releaseNotes = releaseNotes || `Mise à jour v${deployment.currentVersion}`;
  deployment.sha256 = sha256 || '';
  deployment.mandatory = Boolean(mandatory);
  deployment.publishedAt = new Date().toISOString();
  deployment.pushedBy = pushedBy || 'admin';

  writeJSON(DEPLOYMENT_FILE, deployment);
  return deployment;
}

// 4. Stats Management
function recordUpdateCheck(clientVersion, clientPlatform) {
  const stats = readJSON(STATS_FILE, { totalChecks: 0, lastCheckAt: null, versions: {} });
  stats.totalChecks = (stats.totalChecks || 0) + 1;
  stats.lastCheckAt = new Date().toISOString();
  const vKey = clientVersion || 'unknown';
  stats.versions[vKey] = (stats.versions[vKey] || 0) + 1;
  writeJSON(STATS_FILE, stats);
}

function getStats() {
  return readJSON(STATS_FILE, { totalChecks: 0, lastCheckAt: null, versions: {} });
}

module.exports = {
  CONSOLE_CODE,
  verifyConsoleCode,
  createUser,
  verifyUser,
  getUsers,
  getDeployment,
  pushNewVersion,
  recordUpdateCheck,
  getStats
};

