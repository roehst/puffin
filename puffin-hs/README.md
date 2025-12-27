# Puffin - Haskell Edition

A Haskell translation of Puffin, a GUI for Claude Code to help you collaborate on new projects.

## Overview

This is a Haskell implementation of the original Puffin project, providing:
- Type-safe data models for projects, prompts, and user stories
- Functional state management
- Terminal-based UI using Brick
- Git integration
- Claude Code CLI integration

## Prerequisites

- GHC 9.2+ or Stack
- Claude Code CLI installed: `npm install -g @anthropic-ai/claude-code`
- Git

## Building

Using Stack:

```bash
cd puffin-hs
stack build
```

## Running

```bash
stack run puffin-hs-exe /path/to/your/project
```

## Testing

```bash
stack test
```

## Architecture

### Core Modules

- **Puffin.Models**: Type-safe data models for all domain entities
  - `ClaudeModel`: Available Claude models (Opus, Sonnet, Haiku)
  - `ProjectConfig`: Project configuration and settings
  - `Prompt`: Conversation prompts with status tracking
  - `UserStory`: User stories with lifecycle management
  - `GuidanceOptions`: Claude guidance preferences

- **Puffin.State**: Application state management
  - Functional state transitions
  - Immutable state updates
  - Persistent storage (JSON files in `.puffin/`)

- **Puffin.ClaudeService**: Claude Code CLI integration
  - Process spawning and management
  - Streaming response handling
  - JSON message parsing

- **Puffin.GitService**: Git operations
  - Status checking
  - Branch management
  - Commit and merge operations

- **Puffin.UI**: Terminal user interface
  - Built with Brick (declarative terminal UI library)
  - Multiple views: Project, Prompt, Backlog, Architecture, Git
  - Keyboard navigation

## Features Implemented

✅ Core data models with type safety
✅ Application state management
✅ Terminal UI framework
✅ Git service integration
✅ Claude service integration
✅ Project structure
✅ Build configuration
✅ Basic tests

## Features In Progress

🔨 File persistence (loading/saving state)
🔨 Complete UI implementation
🔨 Full Claude streaming support
🔨 User story management
🔨 Architecture documentation view

## Differences from JavaScript Version

- **Type Safety**: All data structures are strongly typed
- **Pure Functions**: State management uses pure functions
- **Immutability**: State updates are immutable
- **Terminal UI**: Uses Brick instead of Electron
- **Functional Composition**: Heavy use of function composition
- **Error Handling**: Uses `Either` and `Maybe` types

## Project Structure

```
puffin-hs/
├── src/
│   └── Puffin/
│       ├── Models.hs          # Core data types
│       ├── State.hs           # State management
│       ├── ClaudeService.hs   # Claude CLI integration
│       ├── GitService.hs      # Git operations
│       └── UI.hs              # Terminal UI
├── app/
│   └── Main.hs                # Entry point
├── test/
│   └── Spec.hs                # Tests
├── package.yaml               # Dependencies
└── stack.yaml                 # Stack configuration
```

## Usage

### Keyboard Controls

- `h` - Home/Project view
- `p` - Prompt view
- `b` - Backlog view
- `a` - Architecture view
- `g` - Git view
- `q` - Quit

### Prompt View

- Type your prompt in the editor
- Press `Enter` to submit to Claude
- View responses in the history panel

### Backlog View

- View all user stories
- Navigate with arrow keys
- Press `Enter` to start working on a story

## Development

### Adding New Features

1. Define data types in `Puffin.Models`
2. Add state management in `Puffin.State`
3. Implement business logic in appropriate service modules
4. Update UI in `Puffin.UI`
5. Write tests in `test/Spec.hs`

### Code Style

- Follow standard Haskell style guidelines
- Use meaningful type signatures
- Document public APIs with Haddock comments
- Prefer pure functions over IO when possible

## License

MIT - Same as the original Puffin project

## Credits

- Original Puffin by jdubray
- Haskell translation maintaining the same philosophy and workflow
- Built with Brick, a declarative terminal UI library
