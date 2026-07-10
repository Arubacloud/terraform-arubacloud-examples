#!/usr/bin/env node
/**
 * Preprocesses docs/ (project root) into docs/website/docs/ for Docusaurus.
 *
 * What it does:
 *  1. Walks docs/ recursively (skipping docs/website/ itself)
 *  2. Renames index.md -> intro.md
 *  3. Resolves {% include-markdown "path" %} directives by inlining file content
 *  4. Converts MkDocs admonitions (!!! type "title") to Docusaurus admonitions (:::type)
 *  5. Writes the processed files to docs/website/docs/
 */

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = path.resolve(__dirname, '../../');     // docs/
const TARGET_DIR = path.resolve(__dirname, '../docs');    // docs/website/docs/

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function resolveIncludes(content, filePath) {
  // Split on fenced code blocks to avoid processing directives inside them.
  // Odd-indexed segments are inside code fences; even-indexed are outside.
  const parts = content.split(/(```[\s\S]*?```|~~~[\s\S]*?~~~)/g);
  return parts.map((part, i) => {
    if (i % 2 === 1) return part; // inside a code fence — leave as-is
    return part.replace(
      /\{%-?\s*include-markdown\s+"([^"]+)"\s*-?%\}/g,
      (match, includePath) => {
        const absolutePath = path.resolve(path.dirname(filePath), includePath);
        try {
          return fs.readFileSync(absolutePath, 'utf8');
        } catch (e) {
          console.warn(`  [warn] Could not include ${absolutePath}: ${e.message}`);
          return `> *Content not found: ${includePath}*\n`;
        }
      }
    );
  }).join('');
}

function rewriteReadmeLinks(content, targetRelPath) {
  // README files cross-link to sibling apps via ../appname/README.md.
  // After inlining, those paths are invalid in the Docusaurus docs tree.
  // Rewrite them to the correct doc page path relative to the current file.
  //
  // e.g. in examples/authentik.md: ../keycloak/README.md -> ./keycloak
  const dir = path.dirname(targetRelPath); // e.g. "examples"
  const parts = content.split(/(```[\s\S]*?```|~~~[\s\S]*?~~~)/g);
  return parts.map((part, i) => {
    if (i % 2 === 1) return part;
    return part.replace(
      /\[([^\]]+)\]\(\.\.\/([^/]+)\/README\.md\)/g,
      (match, text, appName) => {
        const docPath = path.join(dir, appName).replace(/\\/g, '/');
        return `[${text}](/${docPath})`;
      }
    );
  }).join('');
}

function convertAutolinks(content) {
  // MDX treats <https://...> as JSX and chokes on slashes in URL paths.
  // Convert to standard markdown links so MDX can parse them cleanly.
  // Only touch text outside fenced code blocks (same split trick as resolveIncludes).
  const parts = content.split(/(```[\s\S]*?```|~~~[\s\S]*?~~~)/g);
  return parts.map((part, i) => {
    if (i % 2 === 1) return part;
    return part.replace(/<(https?:\/\/[^\s>]+)>/g, '[$1]($1)');
  }).join('');
}

function convertAdmonitions(content) {
  // Convert MkDocs admonitions to Docusaurus admonitions.
  // Input:  !!! warning "Title"\n    indented content\n
  // Output: :::warning[Title]\ncontent\n:::\n
  return content.replace(
    /^!!! (\w+)(?: "([^"]+)")?\n((?:(?:    |\t)[^\n]*\n?)*)/gm,
    (match, type, title, body) => {
      const cleanBody = body.replace(/^(?:    |\t)/gm, '').trimEnd();
      const titleStr = title ? `[${title}]` : '';
      return `:::${type}${titleStr}\n${cleanBody}\n:::\n`;
    }
  );
}

function walkDir(dir, callback, relBase) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relPath = relBase ? `${relBase}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      if (entry.name === 'website') continue;
      walkDir(fullPath, callback, relPath);
    } else if (entry.name.endsWith('.md')) {
      callback(relPath, fullPath);
    }
  }
}

// Clean and recreate target directory
if (fs.existsSync(TARGET_DIR)) {
  fs.rmSync(TARGET_DIR, { recursive: true });
}
ensureDir(TARGET_DIR);

let count = 0;

walkDir(SOURCE_DIR, (relPath, sourceFile) => {
  const targetRelPath = relPath === 'index.md' ? 'intro.md' : relPath;
  const targetFile = path.join(TARGET_DIR, targetRelPath);

  let content = fs.readFileSync(sourceFile, 'utf8');
  content = resolveIncludes(content, sourceFile);
  content = rewriteReadmeLinks(content, targetRelPath);
  content = convertAutolinks(content);
  content = convertAdmonitions(content);

  ensureDir(path.dirname(targetFile));
  fs.writeFileSync(targetFile, content);

  const arrow = relPath !== targetRelPath ? ` -> ${targetRelPath}` : '';
  console.log(`  ${relPath}${arrow}`);
  count++;
});

console.log(`\nProcessed ${count} files into ${TARGET_DIR}`);
