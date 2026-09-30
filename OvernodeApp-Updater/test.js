const assert = require('assert');
const db = require('./db');
const github = require('./github');

async function runTests() {
  console.log('🧪 Starting OvernodeApp-Updater tests...');

  // Test 1: Console Code verification
  console.log('1. Testing console code verification...');
  assert(db.verifyConsoleCode(db.CONSOLE_CODE), 'Valid console code should match');
  assert(!db.verifyConsoleCode('WRONG-CODE-999'), 'Invalid console code should be rejected');
  assert(!db.verifyConsoleCode(''), 'Empty console code should be rejected');
  console.log('   ✓ Console code verification passed');

  // Test 2: User creation and verification
  console.log('2. Testing user creation and authentication...');
  const testUsername = 'testadmin_' + Date.now();
  const testPassword = 'Password123!';
  const user = await db.createUser(testUsername, testPassword);
  assert.strictEqual(user.username, testUsername);

  const authSuccess = await db.verifyUser(testUsername, testPassword);
  assert(authSuccess, 'Should verify correct credentials');

  const authFail = await db.verifyUser(testUsername, 'WrongPass');
  assert(!authFail, 'Should reject invalid password');
  console.log('   ✓ User management passed');

  // Test 3: Semver comparison
  console.log('3. Testing semver comparison...');
  assert.strictEqual(github.compareVersions('1.1.0', '1.0.0'), 1, '1.1.0 > 1.0.0');
  assert.strictEqual(github.compareVersions('1.0.0', '1.1.0'), -1, '1.0.0 < 1.1.0');
  assert.strictEqual(github.compareVersions('1.0.0', '1.0.0'), 0, '1.0.0 == 1.0.0');
  assert.strictEqual(github.compareVersions('2.0.0', '1.9.9'), 1, '2.0.0 > 1.9.9');
  console.log('   ✓ Semver comparison passed');

  // Test 4: Deployment push and retrieval
  console.log('4. Testing deployment push...');
  const pushed = db.pushNewVersion({
    version: '1.2.0',
    downloadUrl: 'https://example.com/Overnode-v1.2.0.zip',
    releaseNotes: 'Test release v1.2.0',
    sha256: 'abc123sha256',
    mandatory: true,
    pushedBy: testUsername
  });
  assert.strictEqual(pushed.currentVersion, '1.2.0');
  assert.strictEqual(pushed.downloadUrl, 'https://example.com/Overnode-v1.2.0.zip');
  assert.strictEqual(pushed.mandatory, true);

  const retrieved = db.getDeployment();
  assert.strictEqual(retrieved.currentVersion, '1.2.0');
  console.log('   ✓ Deployment push passed');

  // Test 5: Update check stats
  console.log('5. Testing update check stats...');
  db.recordUpdateCheck('1.0.0', 'darwin-arm64');
  db.recordUpdateCheck('1.0.0', 'win-x64');
  const stats = db.getStats();
  assert(stats.totalChecks >= 2, 'Stats totalChecks should be >= 2');
  assert(stats.platforms && stats.platforms['win-x64'] >= 1, 'Windows platform stats should be recorded');
  console.log('   ✓ Update check stats passed');

  // Test 6: Windows platform deployment support
  console.log('6. Testing Windows platform deployment...');
  db.pushNewVersion({
    version: '1.3.0',
    downloadUrl: 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.3.0/Overnode-v1.3.0-macOS-arm64.dmg',
    windowsDownloadUrl: 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.3.0/Overnode-v1.3.0-Windows-x64.msi',
    releaseNotes: 'Multi-platform release v1.3.0',
    mandatory: false,
    pushedBy: testUsername
  });
  const macDeployment = db.getDeployment('darwin-arm64');
  assert.strictEqual(macDeployment.downloadUrl, 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.3.0/Overnode-v1.3.0-macOS-arm64.dmg');
  
  const winDeployment = db.getDeployment('win-x64');
  assert.strictEqual(winDeployment.downloadUrl, 'https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.3.0/Overnode-v1.3.0-Windows-x64.msi');
  console.log('   ✓ Windows deployment test passed');

  // Test 7: Independent platform deployment
  console.log('7. Testing independent platform deployment...');
  db.pushNewVersion({
    platform: 'windows',
    version: '1.4.0',
    downloadUrl: 'https://example.com/Overnode-v1.4.0-Windows-x64.msi',
    releaseNotes: 'Windows only v1.4.0',
    pushedBy: testUsername
  });
  const winOnly = db.getDeployment('win-x64');
  const macUntouched = db.getDeployment('darwin-arm64');
  assert.strictEqual(winOnly.currentVersion, '1.4.0');
  assert.strictEqual(macUntouched.currentVersion, '1.3.0');
  console.log('   ✓ Independent platform push passed');

  console.log('🎉 All OvernodeApp-Updater tests passed successfully!');
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

