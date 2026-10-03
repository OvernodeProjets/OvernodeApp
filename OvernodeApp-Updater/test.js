const assert = require('assert');
const fs = require('fs');
const path = require('path');
const db = require('./db');
const github = require('./github');

const DEPLOYMENT_FILE = path.join(__dirname, 'data', 'deployment.json');

async function runTests() {
  console.log('🧪 Starting OvernodeApp-Updater tests...');

  // Backup initial deployment state to restore after test suite
  let backupDeployment = null;
  if (fs.existsSync(DEPLOYMENT_FILE)) {
    try {
      backupDeployment = fs.readFileSync(DEPLOYMENT_FILE, 'utf8');
    } catch (_) {}
  }

  try {
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
    assert.strictEqual(github.compareVersions('1.1.55', '1.1.50'), 1, '1.1.55 > 1.1.50');
    assert.strictEqual(github.compareVersions('1.1.50', '1.1.55'), -1, '1.1.50 < 1.1.55');
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

    // Test 8: SemVer sorting of multiple releases
    console.log('8. Testing release sorting by SemVer descending...');
    const mockReleases = [
      { version: '1.1.12', isRelease: true },
      { version: '1.1.50', isRelease: true },
      { version: '1.1.14', isRelease: true },
      { version: '1.1.9', isRelease: true }
    ];
    mockReleases.sort((a, b) => github.compareVersions(b.version, a.version));
    assert.strictEqual(mockReleases[0].version, '1.1.50', 'Highest SemVer must be at index 0');
    assert.strictEqual(mockReleases[1].version, '1.1.14', '1.1.14 should come before 1.1.12');
    assert.strictEqual(mockReleases[2].version, '1.1.12', '1.1.12 should come before 1.1.9');
    assert.strictEqual(mockReleases[3].version, '1.1.9', 'Lowest SemVer at end');
    console.log('   ✓ Release sorting test passed');

    // Test 9: Strict Asset Categorization (Windows-only vs macOS-only releases)
    console.log('9. Testing strict platform release asset categorization...');
    const rawWindowsRelease = {
      id: 101,
      tag_name: 'v1.1.55',
      assets: [
        { name: 'Overnode-v1.1.55-Windows-x64.msi', browser_download_url: 'https://gh/v1.1.55.msi', id: 1 },
        { name: 'Overnode-v1.1.55-Windows-x64.zip', browser_download_url: 'https://gh/v1.1.55-win.zip', id: 2 },
        { name: 'checksums-windows.sha256', browser_download_url: 'https://gh/checksums.txt', id: 3 }
      ]
    };

    const rawMacRelease = {
      id: 100,
      tag_name: 'v1.1.50',
      assets: [
        { name: 'Overnode-v1.1.50-macOS-arm64.dmg', browser_download_url: 'https://gh/v1.1.50.dmg', id: 4 },
        { name: 'Overnode-v1.1.50-macOS-arm64.zip', browser_download_url: 'https://gh/v1.1.50-mac.zip', id: 5 },
        { name: 'checksums.sha256', browser_download_url: 'https://gh/checksums.txt', id: 6 }
      ]
    };

    function parseMockRelease(r) {
      const assets = r.assets || [];
      const dmgAsset = assets.find(a => a.name && a.name.toLowerCase().endsWith('.dmg'));
      const macZipAsset = assets.find(a => {
        if (!a.name || !a.name.toLowerCase().endsWith('.zip')) return false;
        const nameLower = a.name.toLowerCase();
        if (nameLower.includes('mac') || nameLower.includes('darwin') || nameLower.includes('apple')) return true;
        return !nameLower.includes('win') && !nameLower.includes('windows');
      });
      const msiAsset = assets.find(a => a.name && a.name.toLowerCase().endsWith('.msi'));
      const winZipAsset = assets.find(a => {
        if (!a.name || !a.name.toLowerCase().endsWith('.zip')) return false;
        const nameLower = a.name.toLowerCase();
        return nameLower.includes('win') || nameLower.includes('windows');
      });
      const exeAsset = assets.find(a => a.name && a.name.toLowerCase().endsWith('.exe'));

      return {
        tag: r.tag_name,
        version: r.tag_name.replace(/^v/, ''),
        hasMacAsset: Boolean(dmgAsset || macZipAsset),
        hasWinAsset: Boolean(msiAsset || winZipAsset || exeAsset),
        dmgUrl: dmgAsset ? dmgAsset.browser_download_url : null,
        macZipUrl: macZipAsset ? macZipAsset.browser_download_url : null,
        msiUrl: msiAsset ? msiAsset.browser_download_url : null,
        winZipUrl: winZipAsset ? winZipAsset.browser_download_url : null,
        isRelease: true
      };
    }

    const parsedWin = parseMockRelease(rawWindowsRelease);
    assert.strictEqual(parsedWin.hasMacAsset, false, 'Windows-only release must NOT have hasMacAsset');
    assert.strictEqual(parsedWin.hasWinAsset, true, 'Windows release must have hasWinAsset');
    assert.strictEqual(parsedWin.dmgUrl, null, 'Windows release dmgUrl must be null');
    assert.strictEqual(parsedWin.macZipUrl, null, 'Windows release macZipUrl must be null');
    assert.strictEqual(parsedWin.msiUrl, 'https://gh/v1.1.55.msi');

    const parsedMac = parseMockRelease(rawMacRelease);
    assert.strictEqual(parsedMac.hasMacAsset, true, 'Mac release must have hasMacAsset');
    assert.strictEqual(parsedMac.hasWinAsset, false, 'Mac-only release must NOT have hasWinAsset');
    assert.strictEqual(parsedMac.msiUrl, null, 'Mac release msiUrl must be null');
    assert.strictEqual(parsedMac.dmgUrl, 'https://gh/v1.1.50.dmg');
    console.log('   ✓ Asset categorization passed');

    // Test 10: macOS client update check must never see Windows v1.1.55
    console.log('10. Testing platform update check isolation (v1.1.55 vs v1.1.50)...');
    const mockAllReleases = [parsedWin, parsedMac];
    
    // macOS query with version 1.1.50
    const macReleases = mockAllReleases.filter(r => r.isRelease && r.hasMacAsset);
    macReleases.sort((a, b) => github.compareVersions(b.version, a.version));
    const latestMac = macReleases[0];
    assert(latestMac, 'Should find macOS release');
    assert.strictEqual(latestMac.version, '1.1.50', 'Latest macOS release must be 1.1.50, NOT 1.1.55');
    const macUpdateAvailable = github.compareVersions(latestMac.version, '1.1.50') > 0;
    assert.strictEqual(macUpdateAvailable, false, 'macOS on 1.1.50 must NOT receive updateAvailable = true');

    // macOS query with version 1.1.49
    const macUpdateForOld = github.compareVersions(latestMac.version, '1.1.49') > 0;
    assert.strictEqual(macUpdateForOld, true, 'macOS on 1.1.49 should receive updateAvailable = true');

    // Windows query with version 1.1.50
    const winReleases = mockAllReleases.filter(r => r.isRelease && r.hasWinAsset);
    winReleases.sort((a, b) => github.compareVersions(b.version, a.version));
    const latestWin = winReleases[0];
    assert(latestWin, 'Should find Windows release');
    assert.strictEqual(latestWin.version, '1.1.55', 'Latest Windows release must be 1.1.55');
    const winUpdateAvailable = github.compareVersions(latestWin.version, '1.1.50') > 0;
    assert.strictEqual(winUpdateAvailable, true, 'Windows on 1.1.50 should receive updateAvailable = true for 1.1.55');

    // Windows query with version 1.1.55
    const winUpToDate = github.compareVersions(latestWin.version, '1.1.55') > 0;
    assert.strictEqual(winUpToDate, false, 'Windows on 1.1.55 should be up to date');
    console.log('   ✓ Platform update check isolation passed');

    console.log('🎉 All OvernodeApp-Updater tests passed successfully!');
  } finally {
    // Restore initial deployment state
    if (backupDeployment) {
      try {
        fs.writeFileSync(DEPLOYMENT_FILE, backupDeployment, 'utf8');
      } catch (_) {}
    }
  }
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});
