# CBMQL - MQL5 EA Bundler & Build Tool

> A modern, modular build system for MetaTrader 5 Expert Advisors with watch mode, auto-compilation, and developer-friendly features.

![Node.js](https://img.shields.io/badge/Node.js-16+-green)
![License](https://img.shields.io/badge/License-ISC-blue)
![Status](https://img.shields.io/badge/Status-Active%20Development-yellow)

## 🎯 What is CBMQL?

**CBMQL** is a bundler and build tool specifically designed for **MQL5 Expert Advisors (EAs)** - automated trading bots that run on MetaTrader 5. It enables developers to:

- 📦 **Modularize Code**: Break large EAs into reusable modules
- ⚡ **Auto-Compile**: Automatically compile to `.ex5` using MT5 Editor
- 👀 **Watch Mode**: Hot-reload on file changes for fast development
- 🔧 **Configuration-Driven**: Simple `config.json` setup
- 🚀 **Production-Ready**: Build optimized trading bots for deployment

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- MetaTrader 5 (with Editor) installed on your system
- Basic knowledge of MQL5

### Installation

```bash
# Clone the repository
git clone https://github.com/HarryWarre/cbmql.git
cd cbmql

# Install dependencies
npm install
```

### Basic Setup

1. **Configure your bot** in `config.json`:
```json
{
  "botName": "MyAwesomeBot",
  "version": "1.0.0",
  "author": "Your Name",
  "entryFile": "./src/main.mq5",
  "outputDir": "./dist",
  "mt5EditorPath": "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe"
}
```

2. **Build your bot**:
```bash
# Single build
npm run build

# Watch mode (auto-rebuild on changes)
npm run dev
```

3. **Deploy to MetaTrader 5**:
- Open MetaTrader 5 → Experts folder
- Copy `.ex5` file from `dist/` folder
- Restart MT5 or reload the EA

## 📁 Project Structure

```
cbmql/
├── src/
│   ├── main.mq5              # Entry point
│   └── modules/
│       ├── Defines.mqh       # Constants & definitions
│       ├── TradeLogic.mqh    # Trading strategy logic
│       └── ...
├── dist/                     # Compiled output (.ex5)
├── bundler.js               # Build engine
├── config.json              # Configuration
├── package.json             # Dependencies
├── TODO.md                  # Development roadmap
└── README.md
```

## 🔧 Usage

### Build Commands

```bash
# Development build with watch mode
npm run dev

# Production build (one-time)
npm run build

# Build with custom bot name
npm run build -- --name "CustomBotName"

# Specify config file
npm run build -- --config ./custom-config.json
```

### Import System

Use custom import directives to include modules:

```mql5
// @import "./modules/Defines.mqh"
// @import "./modules/TradeLogic.mqh"

int OnInit() {
  Print("Bot Version: ", BOT_VERSION);
  return INIT_SUCCEEDED;
}
```

**Features:**
- ✅ Recursive imports
- ✅ Automatic MT5 compilation

## 🎓 Example: Creating Your First EA

### Step 1: Create Module Structure

**src/modules/Defines.mqh**
```mql5
#define BOT_VERSION "1.0.0"
#define RISK_PERCENT 2.0
#define MAX_TRADES 5
```

**src/modules/TradeLogic.mqh**
```mql5
void ExecuteStrategy() {
  // Your trading logic here
  Print("Executing strategy with ", BOT_VERSION);
}
```

### Step 2: Create Main Entry Point

**src/main.mq5**
```mql5
// @import "./modules/Defines.mqh"
// @import "./modules/TradeLogic.mqh"

int OnInit() {
  Print("Bot Initialized: ", BOT_VERSION);
  return INIT_SUCCEEDED;
}

void OnTick() {
  ExecuteStrategy();
}
```

### Step 3: Build

```bash
npm run dev  # Start watch mode for development
```

The bundler will merge all imports and create a complete `.ex5` file ready for MetaTrader 5!

## 🐛 Troubleshooting

### Build fails: "File not found"
- Check that import paths are relative to the current file, not the root
- Use `./` prefix for relative imports

### MT5 Editor not compiling automatically
- Verify `mt5EditorPath` in `config.json` is correct
- Ensure MT5 Editor is installed (not just MetaTrader 5 terminal)
- Check Windows permissions for the editor path

### Watch mode not triggering rebuilds
- Ensure file has `.mq5` or `.mqh` extension
- Check that files are being saved to `src/` directory
- Try restarting the watcher (`Ctrl+C` and run `npm run dev` again)

## 🤝 Contributing

We're actively developing CBMQL! Here's how you can help:

1. **Report Issues**: Found a bug? [Create an issue](https://github.com/HarryWarre/cbmql/issues)
2. **Feature Requests**: Have an idea? [Suggest it here](https://github.com/HarryWarre/cbmql/discussions)
3. **Pull Requests**: Want to contribute code? Fork and submit a PR
4. **Documentation**: Help improve docs and tutorials

## 📝 Development Workflow

```bash
# 1. Create a feature branch
git checkout -b feature/your-feature

# 2. Make changes and test
npm run dev

# 3. Commit with our commit convention
git commit -m "Feature | Your Feature
[+] Add new functionality"

# 4. Push and create a PR
git push origin feature/your-feature
```

## 📋 Commit Convention

We follow a simple commit format:

```
<Category> | <Short Description>
[+] Added features
[-] Removed features
[~] Changed/Modified features
[!] Bug fixes
[*] Performance improvements
```

**Examples:**
```
All | Init tool
[+] Add repository

Feature | Add circular dependency detection
[+] Detect circular imports
[!] Prevent infinite loops in bundler

Performance | Optimize file caching
[*] Reduce build time by 40%
[~] Implement hash-based caching
```

## 📊 Project Statistics

- **Language**: JavaScript/MQL5

## 📚 Resources

- [MQL5 Official Documentation](https://www.mql5.com/en/docs)
- [MetaTrader 5 EA Development](https://www.mql5.com/en/code)
- [Node.js Documentation](https://nodejs.org/en/docs/)
- [Our Development Roadmap](./TODO.md)

## 📄 License

ISC License - See LICENSE file for details

## 👥 Authors

- **Project Lead**: Harry Warre
- **Maintainers**: [Contributors](https://github.com/HarryWarre/cbmql/graphs/contributors)

## 🙏 Support

- 📖 **Documentation**: Check [README](./README.md) and [TODO.md](./TODO.md)
- 🐛 **Report Bugs**: [GitHub Issues](https://github.com/HarryWarre/cbmql/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/HarryWarre/cbmql/discussions)
- 📧 **Email**: [Contact us]

---

**Start building better trading bots today with CBMQL! 🚀**
