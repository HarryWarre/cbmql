const fs = require('fs-extra');
const path = require('path');
const chokidar = require('chokidar');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const { exec } = require('child_process');
const chalk = require('chalk');

// Parse CLI arguments
const argv = yargs(hideBin(process.argv))
  .option('name', {
    alias: 'n',
    type: 'string',
    description: 'Bot name override'
  })
  .option('watch', {
    alias: 'w',
    type: 'boolean',
    description: 'Watch mode'
  })
  .argv;

// Load config
const CONFIG_PATH = path.resolve(__dirname, 'config.json');
let config = {};

function loadConfig() {
  try {
    config = fs.readJsonSync(CONFIG_PATH);
  } catch (err) {
    console.error(chalk.red('Error loading config.json:'), err.message);
    process.exit(1);
  }
}

const importedFiles = new Set();

function processFile(filePath, rootDir) {
  const absolutePath = path.resolve(rootDir, filePath);
  
  if (!fs.existsSync(absolutePath)) {
    console.error(chalk.red(`\n[Error] File not found: ${absolutePath}`));
    process.exit(1);
  }

  // Duplicate Guard
  if (importedFiles.has(absolutePath)) {
    return '';
  }
  importedFiles.add(absolutePath);

  let content = fs.readFileSync(absolutePath, 'utf8');
  const lines = content.split('\n');
  const processedLines = lines.map(line => {
    const importMatch = line.match(/^\/\/ @import "(.*)"/);
    if (importMatch) {
      const relativeImportPath = importMatch[1];
      const nextRootDir = path.dirname(absolutePath);
      return processFile(relativeImportPath, nextRootDir);
    }
    return line;
  });

  return processedLines.join('\n');
}

async function build() {
  loadConfig();
  importedFiles.clear();

  const botName = argv.name || config.botName || 'MQL5_Bot';
  const entryFile = path.resolve(__dirname, config.entryFile);
  const outputDir = path.resolve(__dirname, config.outputDir);
  const outputFile = path.join(outputDir, `${botName}.mq5`);

  console.log(chalk.cyan(`\n🚀 Building ${botName}...`));

  const finalContent = processFile(entryFile, __dirname);

  try {
    await fs.ensureDir(outputDir);
    await fs.writeFile(outputFile, finalContent, 'utf8');
    console.log(chalk.green(`✅ Build successful: ${outputFile}`));

    // Auto-Compile if path exists
    if (config.mt5EditorPath && fs.existsSync(config.mt5EditorPath)) {
       compile(outputFile);
    }
  } catch (err) {
    console.error(chalk.red('Error writing build file:'), err.message);
  }
}

function compile(filePath) {
  console.log(chalk.yellow(`🛠 Compiling ${filePath}...`));
  const command = `"${config.mt5EditorPath}" /compile:"${filePath}" /log`;
  
  exec(command, (error, stdout, stderr) => {
    if (error) {
       console.log(chalk.red(`❌ Compilation failed for ${filePath}`));
       console.error(stdout || stderr);
       return;
    }
    console.log(chalk.green(`🎉 Compiled successfully!`));
  });
}

// Initial build
build();

// Watch mode
if (argv.watch) {
  console.log(chalk.magenta('\n👀 Watch mode enabled. Waiting for changes...'));
  
  const watcher = chokidar.watch('src/**/*', {
    ignored: /(^|[\/\\])\../,
    persistent: true
  });

  watcher.on('change', (path) => {
    console.log(chalk.blue(`\n📝 File changed: ${path}`));
    build();
  });
}
