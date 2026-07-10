const fs = require('fs');
const path = require('path');

const docsWebsiteDir = path.resolve(__dirname, '..');
const versionsFile = path.resolve(docsWebsiteDir, 'versions.json');
const translationsSource = path.resolve(docsWebsiteDir, 'i18n', 'it', 'docusaurus-plugin-content-docs', 'current');
const currentJsonSource = path.resolve(docsWebsiteDir, 'i18n', 'it', 'docusaurus-plugin-content-docs', 'current.json');
const i18nBase = path.resolve(docsWebsiteDir, 'i18n', 'it', 'docusaurus-plugin-content-docs');

let versions = [];
if (fs.existsSync(versionsFile)) {
  try {
    versions = JSON.parse(fs.readFileSync(versionsFile, 'utf8'));
  } catch (error) {
    console.error('Error reading versions.json:', error);
    process.exit(1);
  }
}

if (versions.length === 0) {
  const versionedDocsPath = path.resolve(docsWebsiteDir, 'versioned_docs');
  if (fs.existsSync(versionedDocsPath)) {
    try {
      const entries = fs.readdirSync(versionedDocsPath, { withFileTypes: true });
      versions = entries
        .filter(entry => entry.isDirectory() && entry.name.startsWith('version-'))
        .map(entry => entry.name.replace('version-', ''));
      console.log(`Found ${versions.length} versions from versioned_docs directory: ${versions.join(', ')}`);
    } catch (error) {
      console.warn(`Warning: Could not read versioned_docs directory: ${error.message}`);
    }
  }
}

if (versions.length === 0) {
  console.log('No versions found. Skipping translation sync.');
  process.exit(0);
}

function getAllFiles(dir, baseDir) {
  const files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relativePath = path.relative(baseDir, fullPath);

    if (entry.isDirectory()) {
      files.push(...getAllFiles(fullPath, baseDir));
    } else {
      files.push(relativePath);
    }
  }

  return files;
}

const sourceFiles = getAllFiles(translationsSource, translationsSource);

console.log(`Syncing translations from 'current' to ${versions.length} versions...`);

versions.forEach(version => {
  const versionDir = path.join(i18nBase, `version-${version}`);

  if (!fs.existsSync(versionDir)) {
    fs.mkdirSync(versionDir, { recursive: true });
    console.log(`Created directory: ${versionDir}`);
  }

  sourceFiles.forEach(file => {
    const sourceFile = path.join(translationsSource, file);
    const destFile = path.join(versionDir, file);
    const destDir = path.dirname(destFile);

    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir, { recursive: true });
    }

    if (!fs.existsSync(destFile)) {
      fs.copyFileSync(sourceFile, destFile);
    }
  });
  console.log(`  version-${version}: synced (new files only, existing files preserved)`);

  if (fs.existsSync(currentJsonSource)) {
    const destFileName = `version-${version}.json`;
    const finalDestFile = path.join(i18nBase, destFileName);

    const content = JSON.parse(fs.readFileSync(currentJsonSource, 'utf8'));
    if (content['version.label']) {
      content['version.label'].message = version;
    }

    fs.writeFileSync(finalDestFile, JSON.stringify(content, null, 2) + '\n');
    console.log(`  version-${version}: ${destFileName} updated`);
  }
});

console.log('Translation sync completed!');
