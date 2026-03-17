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
const functionsMap = new Map();

function scanFunctions(content, filePath) {
  // Only match top-level functions (no leading whitespace) to avoid matching class methods
  const functionRegex = /^(?:[A-Za-z_]\w*\s+)+([A-Za-z_]\w*)\s*\(/gm;
  const keywords = new Set(['if', 'while', 'for', 'switch', 'return', 'else', 'sizeof', 'new', 'delete']);
  
  let match;
  while ((match = functionRegex.exec(content)) !== null) {
    const funcName = match[1];
    if (!keywords.has(funcName)) {
      if (!functionsMap.has(funcName)) {
        functionsMap.set(funcName, []);
      }
      const files = functionsMap.get(funcName);
      if (!files.includes(filePath)) {
        files.push(filePath);
      }
    }
  }
}

function processFile(filePath, rootDir, importStack = []) {
  const absolutePath = path.resolve(rootDir, filePath);
  
  if (!fs.existsSync(absolutePath)) {
    console.error(chalk.red(`\n[Error] File not found: ${absolutePath}`));
    process.exit(1);
  }

  // Circular Import Detection
  if (importStack.includes(absolutePath)) {
    console.error(chalk.red('\n[Error] Circular import detected:'));
    const chain = [...importStack, absolutePath]
      .map(p => path.relative(process.cwd(), p))
      .join('\n-> ');
    console.error(chalk.yellow(chain));
    process.exit(1);
  }

  // Duplicate Guard (Common Dependency)
  if (importedFiles.has(absolutePath)) {
    return '';
  }
  importedFiles.add(absolutePath);

  let content = fs.readFileSync(absolutePath, 'utf8');
  scanFunctions(content, path.relative(process.cwd(), absolutePath));
  const lines = content.split('\n');
  const processedLines = lines.map(line => {
    const importMatch = line.match(/^\/\/ @import "(.*)"/);
    if (importMatch) {
      const relativeImportPath = importMatch[1];
      const nextRootDir = path.dirname(absolutePath);
      return processFile(relativeImportPath, nextRootDir, [...importStack, absolutePath]);
    }
    return line;
  });

  return processedLines.join('\n');
}

async function build() {
  loadConfig();
  importedFiles.clear();
  functionsMap.clear();

  const botName = argv.name || config.botName || 'MQL5_Bot';
  const entryFile = path.resolve(__dirname, config.entryFile);
  const outputDir = path.resolve(__dirname, config.outputDir);
  const outputFile = path.join(outputDir, `${botName}.mq5`);

  console.log(chalk.cyan(`\n🚀 Building ${botName}...`));

  const finalContent = processFile(entryFile, __dirname);

  // Check for duplicate functions
  let hasDuplicates = false;
  for (const [funcName, files] of functionsMap.entries()) {
    if (files.length > 1) {
      if (!hasDuplicates) {
        console.error(chalk.red('\n[Error] Duplicate function detected:\n'));
        hasDuplicates = true;
      }
      files.forEach(file => {
        const fileName = path.basename(file);
        console.error(chalk.yellow(`${fileName}_${funcName}`));
      });
      console.error(chalk.white('\nDetailed locations:'));
      files.forEach(file => console.error(chalk.gray(`- ${file}`)));
      console.error('');
    }
  }

  if (hasDuplicates) {
    process.exit(1);
  }

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
