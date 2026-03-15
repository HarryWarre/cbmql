# CBMQL - Development Roadmap

## 📋 Project Overview

**CBMQL** is a bundler and build tool for **MQL5 Expert Advisors (EA)** - automated trading bots for MetaTrader 5. It enables modular development of trading strategies by supporting file imports, automated compilation, and watch mode development.

### Current Architecture
- **Bundler**: Processes custom `// @import "path"` directives to merge modules
- **Config-based**: Reads `config.json` for bot name, entry file, output directory, and MT5 compiler path
- **Watch Mode**: Auto-rebuilds on file changes using `chokidar`
- **Auto-Compile**: Optional automatic compilation via MT5 Editor when available

---

## 🎯 Priority 1: Core Quality & Stability

### 1.1 Add Comprehensive Testing
- [ ] Unit tests for `processFile()` and import resolution
- [ ] Test circular dependency detection
- [ ] Test duplicate import handling
- [ ] Integration tests with sample MQL5 projects
- [ ] **Tech**: Jest or Vitest framework
- **Why**: Core bundler logic is untested; even small bugs could break EA compilation

### 1.2 Error Handling & Validation
- [ ] Detect and prevent circular imports with meaningful error messages
- [ ] Validate syntax of MQL5 files before bundling
- [ ] Report line numbers when imports fail
- [ ] Validate config.json schema at startup
- [ ] Better error messages for missing MT5 editor paths
- **Why**: Current errors are cryptic; developers waste time debugging build issues

### 1.3 Performance Optimization
- [ ] Cache file hashes to skip re-processing unchanged files
- [ ] Implement incremental builds in watch mode
- [ ] Profile bundling time on large projects (1000+ lines)
- **Why**: Watch mode rebuilds entire project every change; scales poorly

---

## 🚀 Priority 2: Developer Experience

### 2.1 Better CLI & Configuration
- [ ] Support `.env` files for sensitive paths (MT5 editor, templates)
- [ ] Add `--config` flag to specify custom config paths
- [ ] Add `--output` flag to override output directory
- [ ] Add `--verbose` flag for debugging build issues
- [ ] Support multiple build profiles (dev, staging, prod)
- **Why**: Current setup is rigid; hard to adapt to different workflows

### 2.2 Development Server Features
- [ ] Add `--serve` mode: starts local server showing build status/logs
- [ ] Real-time build notifications (visual + sound)
- [ ] Build history/logs viewable in browser
- [ ] Hot reload indicator in output file header
- **Why**: Developers need feedback loop; watch mode is silent by default

### 2.3 Documentation & Templates
- [ ] Add starter templates:
  - Basic breakeven EA
  - RSI strategy template
  - Moving average crossover template
  - Risk management helper functions
- [ ] Auto-generate project scaffold with `cbmql init` command
- [ ] Add TypeScript support for build tool itself (migrate from JS)
- [ ] Comprehensive README with examples
- **Why**: Onboarding new traders is slow; no templates to start from

---

## 🛠️ Priority 3: Advanced Features

### 3.1 Module System Enhancements
- [ ] Support for namespacing to avoid function collisions
  ```
  // @import "./modules/TradeLogic.mqh" as TradeLogic
  ```
- [ ] Auto-generate module dependency graph visualization
- [ ] Unused code detection/warnings
- [ ] Module versioning with semantic version checking
- **Why**: Large teams need conflict prevention; monolithic EA structure causes issues

### 3.2 Compilation & Build Optimization
- [ ] Support for multiple MT5 builds (x86/x64) simultaneously
- [ ] Parallel compilation for multiple EAs
- [ ] Build artifact versioning (embed git hash/timestamp)
- [ ] Minification option for release builds
- [ ] Symbol stripping for obfuscation (optional)
- **Why**: Professional traders need release management; current tool is basic

### 3.3 Testing & Backtesting Integration
- [ ] Generate backtest configuration files automatically
- [ ] Export EA parameters to CSV for batch testing
- [ ] Parse MT5 backtest results and generate reports
- [ ] Integration with backtesting cloud services
- **Why**: Traders spend 70% time on testing; no tooling support

### 3.4 Version Control & Collaboration
- [ ] Git integration: auto-tag releases, create changelogs
- [ ] Conflict resolution helpers for merged imports
- [ ] Code review checklist for EA changes
- [ ] Audit logging: track all modifications
- **Why**: Financial code needs strict governance

---

## 📊 Priority 4: Professional Features

### 4.1 Monitoring & Analytics
- [ ] Build metrics dashboard (build time, success rate, etc.)
- [ ] Compilation error tracking over time
- [ ] Module health scores (test coverage, complexity)
- [ ] Deployment history tracking
- **Why**: Production systems need observability

### 4.2 Security & Compliance
- [ ] Scan for hardcoded credentials in code
- [ ] Code signing support for trusted EAs
- [ ] License key embedding for paid EAs
- [ ] Compliance checklist generator
- **Why**: Financial software needs security controls

### 4.3 Package Management
- [ ] Create `cbmql.lock` file to pin module versions
- [ ] Support for external module repositories
- [ ] NPM-style package publishing for MQL5 modules
- [ ] Dependency update checker
- **Why**: Ecosystem growth needs package management

---

## 🐛 Known Issues & Technical Debt

1. **Watch Mode**: Rebuilds entire project on any file change (inefficient)
2. **No async support**: File I/O blocks the main thread
3. **Limited error context**: Line numbers not preserved in bundled output
4. **No source maps**: Difficult to debug issues in production bundles
5. **Hard-coded paths**: Config paths are not Windows-agnostic
6. **No input validation**: Config and CLI args don't validate schema

---

## 📈 Success Metrics

- Build time < 500ms for standard projects (100+ lines)
- Watch mode response < 1s
- Zero circular import issues
- 80%+ test coverage
- 1000+ GitHub stars (if open-sourced)

---

## 🏗️ Architecture Improvements

### Recommended Refactoring Path
1. **Phase 1** (Weeks 1-2): Testing framework + core validation
2. **Phase 2** (Weeks 3-4): CLI overhaul + configuration system
3. **Phase 3** (Weeks 5-6): Watch mode optimization + dev server
4. **Phase 4** (Weeks 7-8): Module system v2
5. **Phase 5** (Weeks 9+): Advanced features (profiling, versioning, etc.)

---

## 🎓 Learning Resources

- MQL5 Documentation: https://www.mql5.com/en/docs
- MetaTrader 5 EA Development: https://www.mql5.com/en/code
- Node.js Best Practices: https://nodejs.org/en/docs/guides/
- TypeScript Migration Guide: https://www.typescriptlang.org/docs/

---

## 📝 Notes

- Consider open-sourcing this project - there's demand in the trading bot community
- Large potential for monetization: premium templates, cloud builds, backtest integration
- Strong market for educational content around this tool
- Could expand to support other trading platforms (cTrader, Rust EA, etc.)
