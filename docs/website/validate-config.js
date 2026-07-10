#!/usr/bin/env node

const path = require('path');

const configPath = path.join(__dirname, 'docusaurus.config.js');

console.log('Validating Docusaurus configuration...\n');

try {
  const config = require(configPath);

  if (!config.title) {
    throw new Error('Missing required field: title');
  }

  if (!config.baseUrl) {
    throw new Error('Missing required field: baseUrl');
  }

  if (config.themeConfig && config.themeConfig.footer) {
    const footer = config.themeConfig.footer;

    if (footer.links && Array.isArray(footer.links)) {
      footer.links.forEach((linkGroup, index) => {
        if (linkGroup.items && Array.isArray(linkGroup.items)) {
          linkGroup.items.forEach((item, itemIndex) => {
            if (item.type === 'doc' && item.docId) {
              throw new Error(
                `Invalid footer link at links[${index}].items[${itemIndex}]: ` +
                `Footer links don't support 'type: doc' and 'docId'. ` +
                `Use 'to' for internal links or 'href' for external links.`
              );
            }
            if (!item.to && !item.href && !item.html) {
              throw new Error(
                `Invalid footer link at links[${index}].items[${itemIndex}]: ` +
                `Must have 'to', 'href', or 'html' property`
              );
            }
          });
        }
      });
    }
  }

  console.log('✅ Configuration syntax is valid!');
  console.log(`   Title: ${config.title}`);
  console.log(`   Base URL: ${config.baseUrl}`);
  console.log(`   Footer configured: ${config.themeConfig?.footer ? 'Yes' : 'No'}`);
  process.exit(0);
} catch (error) {
  console.error('❌ Configuration validation failed:');
  console.error(`   ${error.message}`);
  if (error.stack) {
    console.error('\nStack trace:');
    console.error(error.stack);
  }
  process.exit(1);
}
