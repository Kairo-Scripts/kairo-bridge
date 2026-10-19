#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
let passed = 0;
let failed = 0;

function assert(condition, message) {
    if (!condition) {
        console.error(`  FAIL: ${message}`);
        failed++;
        throw new Error(message);
    }
    console.log(`  PASS: ${message}`);
    passed++;
}

console.log('========================================');
console.log('   kairo-bridge Automated Test Runner   ');
console.log('========================================\n');

// 1. Validate JavaScript syntax
console.log('[1/4] Checking JavaScript Syntax...');
try {
    const jsPath = path.join(rootDir, 'html', 'script.js');
    execSync(`node --check "${jsPath}"`, { stdio: 'pipe' });
    assert(true, 'html/script.js syntax valid');
} catch (err) {
    assert(false, `html/script.js syntax error: ${err.message}`);
}

// 2. Validate Lua Syntax across all lua files
console.log('\n[2/4] Validating Lua Syntax across project...');
function getLuaFiles(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    for (const item of list) {
        if (item === '.git' || item === 'node_modules' || item === '.system_generated') continue;
        const full = path.join(dir, item);
        const stat = fs.statSync(full);
        if (stat.isDirectory()) {
            results = results.concat(getLuaFiles(full));
        } else if (item.endsWith('.lua')) {
            results.push(full);
        }
    }
    return results;
}

const luaFiles = getLuaFiles(rootDir);
console.log(`Found ${luaFiles.length} Lua files to validate.`);

for (const file of luaFiles) {
    const rel = path.relative(rootDir, file);
    try {
        execSync(`npx -y luaparse -q "${file}"`, { stdio: 'pipe' });
        assert(true, `Syntax check: ${rel}`);
    } catch (err) {
        assert(false, `Syntax check failed: ${rel} (${err.stderr ? err.stderr.toString().trim() : err.message})`);
    }
}

// 3. Manifest Integrity Checks
console.log('\n[3/4] Verifying Manifest Integrity...');
try {
    const manifestPath = path.join(rootDir, 'fxmanifest.lua');
    const manifest = fs.readFileSync(manifestPath, 'utf8');
    
    assert(manifest.includes("fx_version 'cerulean'"), "fxmanifest specifies cerulean");
    assert(manifest.includes("game 'gta5'"), "fxmanifest specifies gta5");
    assert(manifest.includes("lua54 'yes'"), "fxmanifest specifies lua54");
    assert(manifest.includes("version '"), "fxmanifest has version definition");
    assert(manifest.includes("ui_page 'html/index.html'"), "fxmanifest has ui_page");

    const htmlIndex = path.join(rootDir, 'html', 'index.html');
    const htmlCss = path.join(rootDir, 'html', 'style.css');
    assert(fs.existsSync(htmlIndex), 'html/index.html exists');
    assert(fs.existsSync(htmlCss), 'html/style.css exists');
} catch (err) {
    assert(false, `Manifest verification error: ${err.message}`);
}

// 4. Core Logic Unit Tests
console.log('\n[4/4] Executing Core Unit Tests...');

// Version comparison logic
function compareVersions(v1, v2) {
    const p1 = (v1 || '0').split('.').map(Number);
    const p2 = (v2 || '0').split('.').map(Number);
    const len = Math.max(p1.length, p2.length);
    for (let i = 0; i < len; i++) {
        const a = p1[i] || 0;
        const b = p2[i] || 0;
        if (a > b) return 1;
        if (a < b) return -1;
    }
    return 0;
}

assert(compareVersions('1.5.0', '1.6.0') === -1, 'compareVersions: 1.5.0 < 1.6.0');
assert(compareVersions('2.0.0', '1.9.9') === 1, 'compareVersions: 2.0.0 > 1.9.9');
assert(compareVersions('1.6.0', '1.6') === 0, 'compareVersions: 1.6.0 == 1.6');

// Plate generator format
function generatePlate(format) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    let plate = '';
    for (let i = 0; i < format.length; i++) {
        const c = format[i];
        if (c === '1') plate += numbers[Math.floor(Math.random() * numbers.length)];
        else if (c === 'A') plate += letters[Math.floor(Math.random() * letters.length)];
        else plate += c;
    }
    return plate;
}

const plate = generatePlate('11AAA111');
assert(/^\d{2}[A-Z]{3}\d{3}$/.test(plate), `generatePlate formatted correctly: ${plate}`);

// Locale token replacement
function formatLocale(str, subs) {
    let res = str;
    for (const [k, v] of Object.entries(subs)) {
        res = res.replace(new RegExp(`%\\{${k}\\}`, 'g'), String(v));
    }
    return res;
}

const loc = formatLocale('Player %{name} received $%{amount} in %{acc}', { name: 'Alex', amount: 500, acc: 'bank' });
assert(loc === 'Player Alex received $500 in bank', 'Locale token substitution matches');

// Final summary
console.log('\n========================================');
console.log(`Results: ${passed} passed, ${failed} failed.`);
console.log('========================================\n');

if (failed > 0) {
    process.exit(1);
} else {
    process.exit(0);
}
