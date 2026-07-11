// ═══════════════════════════════════════════════════
// HeadBand! — Deck Seed Generator
// Parses "FINAL CHARADES FILE - 14 MAY 2026.xlsx" (column-per-deck layout)
// and emits db/seed-decks.sql for the Supabase SQL Editor.
//
// Usage:  node db/seed-decks.mjs
// No dependencies — reads the xlsx zip container directly.
// ═══════════════════════════════════════════════════
import { readFileSync, writeFileSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const XLSX_PATH = join(ROOT, 'FINAL CHARADES FILE - 14 MAY 2026.xlsx');
const OUT_PATH = join(ROOT, 'db', 'seed-decks.sql');

// Column → deck mapping. Existing game ids preserved (movies…crazy) so the
// paywall localStorage keys (hb_fw_{id} etc.) keep working after migration.
const COLUMN_MAP = {
  A: { id: 'movies',      name: 'Movies',                 icon: '🎬', color: '#DC2D2D', premium: false },
  B: { id: 'animals',     name: 'Animals',                icon: '🦁', color: '#1EC850', premium: false },
  C: { id: 'tv',          name: 'TV Shows',               icon: '📺', color: '#AA28FF', premium: false },
  D: { id: 'famous',      name: 'Famous People',          icon: '⭐', color: '#FFB400', premium: false },
  E: { id: 'food',        name: 'Food & Drink',           icon: '🍕', color: '#FF6900', premium: false },
  F: { id: 'actitout',    name: 'Act It Out',             icon: '🎭', color: '#FF286E', premium: false },
  G: { id: 'sports',      name: 'Sports',                 icon: '⚽', color: '#0082FF', premium: false },
  H: { id: 'jobs',        name: 'Jobs',                   icon: '💼', color: '#00BEA5', premium: false },
  I: { id: 'kids',        name: 'Kids & Family',          icon: '🌈', color: '#3CDC64', premium: true },
  J: { id: 'disney',      name: 'Disney & Pixar',         icon: '🏰', color: '#FF74D4', premium: true },
  K: { id: 'cartoons',    name: 'Cartoon Characters',     icon: '🐰', color: '#FF9F1A', premium: true },
  L: { id: 'rhymes',      name: 'Fairy Tales & Rhymes',   icon: '🧚', color: '#29C7FE', premium: true },
  M: { id: 'bollywood',   name: 'Bollywood Movies',       icon: '🎬', color: '#E600B4', premium: true },
  N: { id: 'crazy',       name: 'Crazy Movies',           icon: '🤪', color: '#8C3CF0', premium: true },
  O: { id: 'brands',      name: 'Famous Brands',          icon: '🏷️', color: '#5865F2', premium: true },
  P: { id: 'music',       name: 'Music Artists',          icon: '🎤', color: '#FF3B30', premium: true },
  Q: { id: 'songs_en',    name: 'English Songs',          icon: '🎵', color: '#35E08E', premium: true },
  R: { id: 'songs_hi',    name: 'Hindi Songs',            icon: '🎶', color: '#FFA502', premium: true },
  S: { id: 'superheroes', name: 'Superheroes & Villains', icon: '🦸', color: '#5F27CD', premium: true },
  T: { id: 'fictional',   name: 'Fictional Characters',   icon: '🕵️', color: '#10AC84', premium: true },
  U: { id: 'places',      name: 'Places & Landmarks',     icon: '🗺️', color: '#0ABDE3', premium: true },
  V: { id: 'videogames',  name: 'Video Games',            icon: '🎮', color: '#C56CF0', premium: true },
  W: { id: 'popculture',  name: 'Pop Culture',            icon: '🔥', color: '#FF6B81', premium: true },
  X: { id: 'books',       name: 'Books & Authors',        icon: '📚', color: '#C47F17', premium: true },
};

// ── Minimal zip reader (xlsx = zip of xml) ──────────────────────
function zipEntries(buf) {
  const eocd = buf.lastIndexOf(Buffer.from('PK\x05\x06', 'latin1'));
  if (eocd < 0) throw new Error('Not a zip file (EOCD missing)');
  let p = buf.readUInt32LE(eocd + 16);
  const entries = {};
  while (p + 4 <= buf.length && buf.readUInt32LE(p) === 0x02014b50) {
    const method = buf.readUInt16LE(p + 10);
    const csize = buf.readUInt32LE(p + 20);
    const nlen = buf.readUInt16LE(p + 28);
    const elen = buf.readUInt16LE(p + 30);
    const clen = buf.readUInt16LE(p + 32);
    const off = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + nlen);
    entries[name] = { method, csize, off };
    p += 46 + nlen + elen + clen;
  }
  return entries;
}

function readEntry(buf, e) {
  const nlen = buf.readUInt16LE(e.off + 26);
  const elen = buf.readUInt16LE(e.off + 28);
  const start = e.off + 30 + nlen + elen;
  const data = buf.subarray(start, start + e.csize);
  return e.method === 0 ? data : inflateRawSync(data);
}

// ── xlsx parsing ────────────────────────────────────────────────
function decodeXml(s) {
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(+n));
}

const zip = readFileSync(XLSX_PATH);
const entries = zipEntries(zip);
const sharedXml = readEntry(zip, entries['xl/sharedStrings.xml']).toString('utf8');
const sheetXml = readEntry(zip, entries['xl/worksheets/sheet1.xml']).toString('utf8');

const strings = [];
for (const m of sharedXml.matchAll(/<si>(.*?)<\/si>/gs)) strings.push(decodeXml(m[1]));

// column letter → array of words (rows 2+)
const wordsByCol = {};
const rows = sheetXml.match(/<row[^>]*>.*?<\/row>/gs) ?? [];
rows.forEach((row, ri) => {
  if (ri === 0) return; // header row — mapping is hardcoded above
  for (const c of row.matchAll(/<c r="([A-Z]+)\d+"(?:[^>]*?t="(\w+)")?[^>]*>(?:<v>(.*?)<\/v>)?/g)) {
    const [, col, type, raw] = c;
    if (raw === undefined) continue;
    const val = (type === 's' ? strings[+raw] : raw).trim();
    if (!val) continue;
    (wordsByCol[col] ??= []).push(val);
  }
});

// ── Emit SQL ────────────────────────────────────────────────────
const esc = (s) => s.replace(/'/g, "''");
const lines = [
  '-- Generated by db/seed-decks.mjs — do not edit by hand.',
  `-- Source: FINAL CHARADES FILE - 14 MAY 2026.xlsx (${new Date().toISOString()})`,
  '',
  'begin;',
  '',
];

const cols = Object.keys(COLUMN_MAP);
let totalWords = 0;
let dupesDropped = 0;

// decks (upsert — reruns are safe)
lines.push('insert into public.decks (id, name, icon, color, is_premium, sort) values');
lines.push(cols.map((col, i) => {
  const d = COLUMN_MAP[col];
  return `  ('${d.id}', '${esc(d.name)}', '${d.icon}', '${d.color}', ${d.premium}, ${i + 1})`;
}).join(',\n'));
lines.push(`on conflict (id) do update set
  name = excluded.name, icon = excluded.icon, color = excluded.color,
  is_premium = excluded.is_premium, sort = excluded.sort, active = true;`);
lines.push('');

// words — wipe & reload per seeded deck, batched inserts
lines.push(`delete from public.words where deck_id in (${cols.map(c => `'${COLUMN_MAP[c].id}'`).join(', ')});`);
lines.push('');

const BATCH = 500;
for (const col of cols) {
  const d = COLUMN_MAP[col];
  const raw = wordsByCol[col] ?? [];
  const seen = new Set();
  const words = raw.filter(w => {
    const k = w.toLowerCase();
    if (seen.has(k)) { dupesDropped++; return false; }
    seen.add(k);
    return true;
  });
  totalWords += words.length;
  lines.push(`-- ${d.id}: ${words.length} words${raw.length !== words.length ? ` (${raw.length - words.length} dupes dropped)` : ''}`);
  for (let i = 0; i < words.length; i += BATCH) {
    lines.push('insert into public.words (deck_id, text) values');
    lines.push(words.slice(i, i + BATCH).map(w => `  ('${d.id}', '${esc(w)}')`).join(',\n') + ';');
  }
  lines.push('');
}

lines.push('commit;');
lines.push('');

writeFileSync(OUT_PATH, lines.join('\n'), 'utf8');

console.log(`Decks:  ${cols.length}`);
for (const col of cols) {
  const d = COLUMN_MAP[col];
  console.log(`  ${d.id.padEnd(12)} ${String((wordsByCol[col] ?? []).length).padStart(4)} words ${d.premium ? '[PREMIUM]' : '[FREE]'}`);
}
console.log(`Words:  ${totalWords} (${dupesDropped} duplicates dropped)`);
console.log(`Wrote:  ${OUT_PATH}`);
