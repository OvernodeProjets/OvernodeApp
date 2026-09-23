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
  const stats = db.getStats();
  assert(stats.totalChecks >= 1, 'Stats totalChecks should be >= 1');
  console.log('   ✓ Update check stats passed');

  console.log('🎉 All OvernodeApp-Updater tests passed successfully!');
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

