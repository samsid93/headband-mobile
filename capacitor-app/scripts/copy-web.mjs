/**
 * Copies the shipping web build into www/ so the native apps bundle exactly what
 * whambam.games serves. Runs before every `cap sync` (see package.json).
 *
 * The web app is a single self-contained HTML file plus a handful of assets, so
 * there is no build step — this is a straight copy with a manifest, which keeps
 * www/ from silently drifting out of date the way it did before.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const www = path.resolve(here, '..', 'www');

// source in repo root -> name inside www/
const FILES = [
  ['headband-game-web.html', 'index.html'],
  ['terms.html',             'terms.html'],
  ['privacy.html',           'privacy.html'],
  ['legal-style.css',        'legal-style.css'],
  ['logo.png',               'logo.png'],
  ['splash.png',             'splash.png'],
  ['splash-desktop.png',     'splash-desktop.png'],
  ['mode-poster.svg',        'mode-poster.svg'],
  ['mode-poster-desktop.png','mode-poster-desktop.png'],
];

fs.mkdirSync(www, { recursive: true });

let copied = 0;
const missing = [];
for (const [from, to] of FILES) {
  const src = path.join(repo, from);
  if (!fs.existsSync(src)) { missing.push(from); continue; }
  fs.copyFileSync(src, path.join(www, to));
  copied++;
}

if (missing.length) {
  console.error('copy-web: missing source files:\n  ' + missing.join('\n  '));
  process.exit(1);
}

// Anything left in www/ that we did not just write is stale — a renamed or
// removed asset would otherwise keep shipping inside the app forever.
const expected = new Set(FILES.map(([, to]) => to));
for (const name of fs.readdirSync(www)) {
  if (!expected.has(name)) {
    fs.rmSync(path.join(www, name), { recursive: true, force: true });
    console.log('copy-web: removed stale ' + name);
  }
}

console.log(`copy-web: ${copied} files copied into www/`);
