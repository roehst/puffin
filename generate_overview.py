#!/usr/bin/env python3
"""
OVERVIEW.md Generator for Puffin Project

This script analyzes the Puffin codebase and generates a comprehensive OVERVIEW.md
document with B-method style specifications and Mermaid diagrams.

B-method flavor includes:
- Abstract machine specifications
- Refinement layers
- Invariants and properties
- State machines and operations
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Set, Tuple
from collections import defaultdict


# Configuration constants
MAX_DIAGRAM_NODES = 10  # Maximum nodes to show in component diagrams
MAX_FUNCTIONS_DISPLAY = 10  # Maximum functions to list before truncating
MAX_ITEMS_PREVIEW = 5  # Maximum items to show in preview lists before truncating


# Regex patterns for code analysis
# Match: const {items} = require('module') or let name = require('module')
REQUIRE_PATTERN = r"(?:const|let|var)\s+(?:\{([^}]+)\}|(\w+))\s*=\s*require\(['\"]([^'\"]+)['\"]\)"
# Match: import {items} from 'module' or import name from 'module'
IMPORT_PATTERN = r"import\s+(?:\{([^}]+)\}|(\w+))\s+from\s+['\"]([^'\"]+)['\"]"
# Match: module.exports = {items} or module.exports = name
MODULE_EXPORTS_PATTERN = r"module\.exports\s*=\s*(?:\{([^}]+)\}|(\w+))"
# Match: export default class/function/const name or export class/function name
EXPORT_PATTERN = r"export\s+(?:default\s+)?(?:class|function|const|let|var)?\s*(\w+)"
# Match: class ClassName or class ClassName extends ParentClass
CLASS_PATTERN = r"class\s+(\w+)(?:\s+extends\s+(\w+))?\s*\{"
# Match: function functionName() or async function functionName()
FUNCTION_PATTERN = r"(?:async\s+)?function\s+(\w+)\s*\([^)]*\)"
# Match: const functionName = () => or let functionName = async () =>
ARROW_FUNCTION_PATTERN = r"(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?\([^)]*\)\s*=>"
# Match: const CONSTANT_NAME = (uppercase with underscores)
CONST_UPPER_PATTERN = r"const\s+([A-Z_][A-Z0-9_]*)\s*="
# Match: JSDoc style block comments
JSDOC_PATTERN = r"^\/\*\*\s*\n((?:\s*\*.*\n)+)\s*\*\/"
# Match: Single-line comments at start of file
SINGLE_LINE_COMMENT_PATTERN = r"^//\s*(.+)"


class FileAnalyzer:
    """Analyzes JavaScript source files to extract structure and dependencies.
    
    This analyzer extracts:
    - Import/require statements and dependencies
    - Export declarations (module.exports, ES6 exports)
    - Class definitions with inheritance
    - Function declarations (regular and arrow functions)
    - Constants (uppercase naming convention)
    - File descriptions from header comments
    
    Attributes:
        file_path (str): Full path to the source file
        relative_path (str): Path relative to project root
        content (str): File contents
        imports (list): List of import/require statements
        exports (list): List of exported identifiers
        classes (list): List of class definitions with inheritance info
        functions (list): List of function names
        constants (list): List of constant names
        description (str): File description from header comments
    """
    
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.relative_path = None
        self.content = ""
        self.imports = []
        self.exports = []
        self.classes = []
        self.functions = []
        self.constants = []
        self.description = ""
        
    def analyze(self, base_path: str):
        """Analyze the file and extract relevant information."""
        self.relative_path = os.path.relpath(self.file_path, base_path)
        
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                self.content = f.read()
        except Exception as e:
            print(f"Warning: Could not read {self.file_path}: {e}")
            return
        
        # Extract imports
        self._extract_imports()
        
        # Extract exports
        self._extract_exports()
        
        # Extract classes
        self._extract_classes()
        
        # Extract functions
        self._extract_functions()
        
        # Extract constants
        self._extract_constants()
        
        # Extract description from comments
        self._extract_description()
    
    def _extract_imports(self):
        """Extract import statements."""
        # Match require() statements
        for match in re.finditer(REQUIRE_PATTERN, self.content):
            if match.group(1):  # Destructured import
                items = [item.strip() for item in match.group(1).split(',')]
                self.imports.append({'type': 'destructured', 'items': items, 'from': match.group(3)})
            else:  # Default import
                self.imports.append({'type': 'default', 'name': match.group(2), 'from': match.group(3)})
        
        # Match ES6 import statements
        for match in re.finditer(IMPORT_PATTERN, self.content):
            if match.group(1):  # Named imports
                items = [item.strip() for item in match.group(1).split(',')]
                self.imports.append({'type': 'named', 'items': items, 'from': match.group(3)})
            else:  # Default import
                self.imports.append({'type': 'default', 'name': match.group(2), 'from': match.group(3)})
    
    def _extract_exports(self):
        """Extract export statements."""
        # Match module.exports
        match = re.search(MODULE_EXPORTS_PATTERN, self.content)
        if match:
            if match.group(1):  # Object exports
                items = [item.strip().split(':')[0].strip() for item in match.group(1).split(',')]
                self.exports = items
            else:  # Single export
                self.exports = [match.group(2)]
        
        # Match ES6 exports
        for match in re.finditer(EXPORT_PATTERN, self.content):
            if match.group(1) and match.group(1) not in self.exports:
                self.exports.append(match.group(1))
    
    def _extract_classes(self):
        """Extract class definitions."""
        for match in re.finditer(CLASS_PATTERN, self.content):
            self.classes.append({
                'name': match.group(1),
                'extends': match.group(2) if match.group(2) else None
            })
    
    def _extract_functions(self):
        """Extract function definitions."""
        # Match function declarations
        for match in re.finditer(FUNCTION_PATTERN, self.content):
            if match.group(1) not in self.functions:
                self.functions.append(match.group(1))
        
        # Match arrow functions assigned to variables
        for match in re.finditer(ARROW_FUNCTION_PATTERN, self.content):
            if match.group(1) not in self.functions:
                self.functions.append(match.group(1))
    
    def _extract_constants(self):
        """Extract constant definitions (uppercase naming convention)."""
        for match in re.finditer(CONST_UPPER_PATTERN, self.content):
            if match.group(1) not in self.constants:
                self.constants.append(match.group(1))
    
    def _extract_description(self):
        """Extract description from file header comments."""
        # Look for JSDoc style comments at the start
        match = re.search(JSDOC_PATTERN, self.content, re.MULTILINE)
        if match:
            lines = match.group(1).split('\n')
            desc_lines = []
            for line in lines:
                line = re.sub(r'^\s*\*\s?', '', line).strip()
                if line and not line.startswith('@'):
                    desc_lines.append(line)
            self.description = ' '.join(desc_lines)
        
        # Fallback to single line comment at start
        if not self.description:
            match = re.search(SINGLE_LINE_COMMENT_PATTERN, self.content, re.MULTILINE)
            if match:
                self.description = match.group(1).strip()


class OverviewGenerator:
    """Generates the OVERVIEW.md document with B-method specifications.
    
    Uses B-method inspired formal specification approach including:
    - Abstract machine specifications (SETS, CONSTANTS, VARIABLES, INVARIANTS, OPERATIONS)
    - Refinement layers from abstract to concrete implementation
    - State machine specifications with formal transitions
    - Formal properties (invariants, liveness, safety)
    - Mermaid diagrams for visual architecture representation
    
    Generated sections:
    1. Abstract Machine Specification
    2. Architecture Overview (with diagrams)
    3. System Components
    4. State Machine Specifications
    5. Refinement Layers
    6. Module Catalog
    7. Dependency Graph
    8. Formal Properties & Invariants
    9. Security Considerations
    10. Extensibility (Plugin System)
    11. Conclusion
    """
    
    def __init__(self, base_path: str):
        self.base_path = base_path
        self.files: List[FileAnalyzer] = []
        self.categories: Dict[str, List[FileAnalyzer]] = defaultdict(list)
        
    def scan_files(self):
        """Scan all JavaScript files in the project."""
        src_path = os.path.join(self.base_path, 'src')
        
        for root, dirs, files in os.walk(src_path):
            # Skip node_modules and other directories
            dirs[:] = [d for d in dirs if d not in ['node_modules', '.git', 'dist', 'build']]
            
            for file in files:
                if file.endswith('.js'):
                    file_path = os.path.join(root, file)
                    analyzer = FileAnalyzer(file_path)
                    analyzer.analyze(self.base_path)
                    self.files.append(analyzer)
                    
                    # Categorize files
                    category = self._categorize_file(analyzer.relative_path)
                    self.categories[category].append(analyzer)
    
    def _categorize_file(self, relative_path: str) -> str:
        """Categorize a file based on its path."""
        if 'main' in relative_path:
            if 'plugins' in relative_path:
                return 'Main Process - Plugin System'
            return 'Main Process - Core'
        elif 'renderer' in relative_path:
            if 'components' in relative_path:
                return 'Renderer Process - Components'
            elif 'sam' in relative_path:
                return 'Renderer Process - SAM Pattern'
            elif 'plugins' in relative_path:
                return 'Renderer Process - Plugin System'
            elif 'lib' in relative_path:
                return 'Renderer Process - Libraries'
            return 'Renderer Process - Core'
        elif 'shared' in relative_path:
            return 'Shared Utilities'
        return 'Other'
    
    def generate_overview(self) -> str:
        """Generate the complete OVERVIEW.md document."""
        sections = []
        
        # Header
        sections.append(self._generate_header())
        
        # Abstract Machine Specification (B-method style)
        sections.append(self._generate_abstract_machine())
        
        # Architecture Overview with Mermaid
        sections.append(self._generate_architecture_diagram())
        
        # System Components
        sections.append(self._generate_components())
        
        # State Machine Specifications
        sections.append(self._generate_state_machines())
        
        # Refinement Layers
        sections.append(self._generate_refinements())
        
        # Module Catalog
        sections.append(self._generate_module_catalog())
        
        # Dependency Graph
        sections.append(self._generate_dependency_graph())
        
        return '\n\n'.join(sections)
    
    def _generate_header(self) -> str:
        """Generate the document header."""
        # Try to detect project name from package.json or use directory name
        project_name = "PUFFIN"
        try:
            package_json_path = os.path.join(self.base_path, 'package.json')
            if os.path.exists(package_json_path):
                with open(package_json_path, 'r', encoding='utf-8') as f:
                    package_data = json.load(f)
                    project_name = package_data.get('name', 'PUFFIN').upper()
        except Exception:
            # Fallback to directory name
            project_name = os.path.basename(self.base_path).upper()
        
        return f"""# {project_name} - System Overview

**Generated:** Automated documentation from source code analysis  
**Method:** B-method inspired formal specification  
**Purpose:** High-level system specification with refinement layers

---

## Executive Summary

Puffin is an Electron-based desktop application that provides a structured workflow interface for Claude Code, Anthropic's AI coding assistant CLI. The system implements a hierarchical, backlog-driven development methodology that enhances collaboration between human developers (cloders) and AI agents.

**Core Philosophy:** Transform unstructured prompt-based interactions into a traceable, process-oriented workflow with clear separation of concerns through architectural layers.

**Key Architectural Patterns:**
- SAM (State-Action-Model) Pattern for predictable state management
- Electron multi-process architecture (Main + Renderer processes)
- Plugin system for extensibility
- Event-driven communication via IPC (Inter-Process Communication)
"""
    
    def _generate_abstract_machine(self) -> str:
        """Generate abstract machine specification in B-method style."""
        return """---

## 1. Abstract Machine Specification

### MACHINE Puffin_System

**SETS**
```
PROCESS_TYPE = {main, renderer}
VIEW_STATE = {config, prompt, designer, backlog, architecture, cli_output}
PROMPT_STATE = {idle, composing, submitted, streaming, completed, error}
STORY_STATUS = {pending, in_progress, completed, archived}
GIT_OPERATION = {commit, push, pull, merge, branch}
```

**CONSTANTS**
```
MAX_CONTEXT_WINDOW = 200000  /* Claude's token limit */
AUTOSAVE_INTERVAL = 30000    /* milliseconds */
DEFAULT_BRANCH_PREFIX = "feature/"
```

**VARIABLES**
```
current_project_path : STRING
project_configuration : CONFIGURATION
conversation_history : SEQ(PROMPT_RESPONSE)
user_stories : SET(USER_STORY)
active_view : VIEW_STATE
prompt_fsm_state : PROMPT_STATE
claude_session : PROCESS
```

**INVARIANTS**
```
INV1: current_project_path ≠ ∅ => ∃ .puffin directory
INV2: prompt_fsm_state = streaming => claude_session ≠ null
INV3: ∀ story ∈ user_stories: story.status ∈ STORY_STATUS
INV4: active_view ∈ VIEW_STATE
INV5: |conversation_history| ≥ 0
```

**OPERATIONS**

#### initialize_project(path)
```
PRE: path is valid directory path
POST: current_project_path = path ∧ 
      .puffin directory created ∧
      default configuration loaded
```

#### submit_prompt(prompt_text, branch)
```
PRE: prompt_fsm_state = composing ∧
     claude_session initialized ∧
     prompt_text ≠ ∅
POST: prompt_fsm_state = submitted ∧
      prompt added to conversation_history ∧
      claude_session receives prompt
```

#### derive_user_stories(specification)
```
PRE: specification ≠ ∅ ∧
     claude_session active
POST: ∃ stories ⊆ user_stories:
      stories derived from specification ∧
      ∀ s ∈ stories: s.status = pending
```

#### execute_git_operation(operation, params)
```
PRE: operation ∈ GIT_OPERATION ∧
     current_project_path has .git directory
POST: git operation completed ∧
      operation logged in history
```
"""
    
    def _generate_architecture_diagram(self) -> str:
        """Generate architecture overview with mermaid diagram."""
        return """---

## 2. Architecture Overview

### 2.1 System Context Diagram

```mermaid
graph TB
    User[User/Cloder] --> |Interacts| Puffin[Puffin Application]
    Puffin --> |Spawns & Controls| Claude[Claude Code CLI]
    Puffin --> |Reads/Writes| Files[Project Files]
    Puffin --> |Manages| PuffinState[.puffin State Directory]
    Puffin --> |Executes| Git[Git Operations]
    Claude --> |Modifies| Files
    Claude --> |Streams| Response[JSON Response Stream]
    Response --> |Parsed by| Puffin
    PuffinState --> |Stores| Config[config.json]
    PuffinState --> |Stores| History[history.json]
    PuffinState --> |Stores| Arch[architecture.md]
    
    style Puffin fill:#4A90E2,stroke:#2E5C8A,color:#fff
    style Claude fill:#E67E22,stroke:#A0522D,color:#fff
    style PuffinState fill:#27AE60,stroke:#1E8449,color:#fff
```

### 2.2 Multi-Process Architecture

```mermaid
graph LR
    subgraph "Electron Application"
        Main[Main Process<br/>Node.js Runtime]
        Renderer[Renderer Process<br/>Chromium Browser]
        Preload[Preload Script<br/>Secure Bridge]
    end
    
    Main <--> |IPC Channel| Preload
    Preload <--> |Context Bridge| Renderer
    Main --> |Spawns| Claude[Claude CLI Process]
    Main --> |File I/O| FS[File System]
    Renderer --> |Updates| DOM[DOM / UI]
    
    style Main fill:#2C3E50,stroke:#1A252F,color:#fff
    style Renderer fill:#8E44AD,stroke:#6C3483,color:#fff
    style Preload fill:#16A085,stroke:#117864,color:#fff
```

### 2.3 State Management (SAM Pattern)

```mermaid
stateDiagram-v2
    [*] --> Action: User Intent
    Action --> Model: Proposal
    Model --> State: Updated Model
    State --> View: State Representation
    View --> [*]: Rendered UI
    View --> Action: Next Action
    
    note right of Model
        Accepts/Rejects proposals
        Maintains invariants
        Single source of truth
    end note
    
    note right of State
        Derives representation
        Controls FSM transitions
        Triggers next actions
    end note
```
"""
    
    def _generate_components(self) -> str:
        """Generate component specifications."""
        sections = ["---\n\n## 3. System Components\n"]
        
        category_number = 1
        for category in sorted(self.categories.keys()):
            files = self.categories[category]
            if not files:
                continue
                
            sections.append(f"### 3.{category_number} {category}\n")
            category_number += 1
            
            # Create component diagram for this category
            sections.append("```mermaid")
            sections.append("graph TD")
            
            for i, file_analyzer in enumerate(files[:MAX_DIAGRAM_NODES]):
                file_name = os.path.basename(file_analyzer.relative_path).replace('.js', '')
                node_id = f"C{i}"
                sections.append(f"    {node_id}[{file_name}]")
            
            sections.append("```\n")
            
            # List components
            for file_analyzer in files:
                sections.append(self._format_component(file_analyzer))
        
        return '\n'.join(sections)
    
    def _format_component(self, analyzer: FileAnalyzer) -> str:
        """Format a single component specification."""
        parts = [f"#### `{analyzer.relative_path}`\n"]
        
        if analyzer.description:
            parts.append(f"**Description:** {analyzer.description}\n")
        
        if analyzer.classes:
            parts.append(f"**Classes:** {', '.join(c['name'] for c in analyzer.classes)}")
        
        if analyzer.functions:
            funcs = ', '.join(analyzer.functions[:MAX_ITEMS_PREVIEW])
            if len(analyzer.functions) > MAX_ITEMS_PREVIEW:
                funcs += f" ... (+{len(analyzer.functions) - MAX_ITEMS_PREVIEW} more)"
            parts.append(f"**Functions:** {funcs}")
        
        if analyzer.exports:
            exports = ', '.join(analyzer.exports[:MAX_ITEMS_PREVIEW])
            if len(analyzer.exports) > MAX_ITEMS_PREVIEW:
                exports += f" ... (+{len(analyzer.exports) - MAX_ITEMS_PREVIEW} more)"
            parts.append(f"**Exports:** {exports}")
        
        return '\n'.join(parts) + '\n'
    
    def _generate_state_machines(self) -> str:
        """Generate state machine specifications."""
        return """---

## 4. State Machine Specifications

### 4.1 Application FSM

```mermaid
stateDiagram-v2
    [*] --> Uninitialized
    Uninitialized --> Initializing: initialize
    Initializing --> Ready: success
    Initializing --> Error: failure
    Ready --> Ready: user_action
    Error --> Initializing: retry
    Ready --> [*]: shutdown
```

**States:**
- `Uninitialized`: No project loaded
- `Initializing`: Loading project configuration
- `Ready`: Application ready for user interaction
- `Error`: Initialization failed

**Transitions:**
- `initialize`: Load project and configuration
- `success`: Configuration loaded successfully
- `failure`: Configuration load failed
- `user_action`: Any valid user action in ready state
- `retry`: Attempt to reinitialize after error

### 4.2 Prompt Execution FSM

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Composing: user_starts_typing
    Composing --> Composing: user_types
    Composing --> Idle: user_clears
    Composing --> Submitted: user_submits
    Submitted --> Streaming: claude_responds
    Streaming --> Streaming: chunk_received
    Streaming --> Completed: stream_ends
    Streaming --> Error: stream_error
    Completed --> Idle: reset
    Error --> Idle: reset
    
    note right of Streaming
        Real-time token streaming
        Tool execution monitoring
        Context window tracking
    end note
```

**States:**
- `Idle`: No active prompt
- `Composing`: User typing prompt
- `Submitted`: Prompt sent to Claude CLI
- `Streaming`: Receiving response stream
- `Completed`: Response fully received
- `Error`: Error during prompt execution

### 4.3 User Story Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Pending: derive_from_spec
    Pending --> InProgress: start_implementation
    InProgress --> Completed: mark_complete
    Completed --> Archived: auto_archive_after_2weeks
    Pending --> Archived: manual_archive
    Archived --> [*]
    
    note right of InProgress
        Generates implementation thread
        Verifies acceptance criteria
        Tracks progress
    end note
```
"""
    
    def _generate_refinements(self) -> str:
        """Generate refinement layer specifications."""
        return """---

## 5. Refinement Layers (B-Method Style)

### Refinement Level 0: Abstract Specification

**Abstract State:**
```
STATE = ⟨ project, history, stories ⟩
```

**Abstract Operations:**
```
• initialize(path) → STATE
• prompt(text) → RESPONSE
• manage_stories(operation) → STORIES
```

### Refinement Level 1: Process Architecture

**Refined State:**
```
STATE = ⟨ main_process, renderer_process, ipc_channel ⟩

main_process = ⟨ claude_service, puffin_state, ipc_handlers ⟩
renderer_process = ⟨ sam_model, sam_state, components ⟩
ipc_channel = ⟨ requests, responses, events ⟩
```

**Refined Operations:**
```
initialize(path) =̂
    main_process.load_configuration(path) ∥
    main_process.initialize_claude_service() ∥
    renderer_process.render_initial_view()

prompt(text) =̂
    renderer_process.dispatch_action(submit_prompt, text) ⟹
    ipc_channel.send_request(execute_prompt, text) ⟹
    main_process.claude_service.spawn_process(text) ⟹
    main_process.stream_response() ⟹
    ipc_channel.send_events(response_chunks) ⟹
    renderer_process.update_view()
```

### Refinement Level 2: Component Implementation

**Components mapped to files:**

```
main_process.claude_service ↦ src/main/claude-service.js
main_process.puffin_state ↦ src/main/puffin-state.js
main_process.ipc_handlers ↦ src/main/ipc-handlers.js
renderer_process.sam_model ↦ src/renderer/sam/model.js
renderer_process.sam_state ↦ src/renderer/sam/state.js
renderer_process.components.prompt ↦ src/renderer/components/prompt-editor/
```

### Refinement Verification

**Proof Obligations:**
1. Each refinement preserves abstract invariants
2. Each refined operation simulates abstract operation
3. No new deadlocks introduced at lower levels
4. All concrete states map to valid abstract states

```
∀ concrete_state ∈ CONCRETE_STATE:
    ∃ abstract_state ∈ ABSTRACT_STATE:
        abstraction(concrete_state) = abstract_state ∧
        satisfies_invariants(abstract_state)
```
"""
    
    def _generate_module_catalog(self) -> str:
        """Generate detailed module catalog."""
        sections = ["---\n\n## 6. Module Catalog\n"]
        sections.append("Complete listing of all modules with their specifications.\n")
        
        # Group by category
        category_number = 1
        for category in sorted(self.categories.keys()):
            files = self.categories[category]
            sections.append(f"### 6.{category_number} {category}\n")
            category_number += 1
            
            for file_analyzer in sorted(files, key=lambda x: x.relative_path):
                sections.append(f"#### {file_analyzer.relative_path}\n")
                
                if file_analyzer.description:
                    sections.append(f"{file_analyzer.description}\n")
                
                if file_analyzer.classes:
                    sections.append("**Classes:**")
                    for cls in file_analyzer.classes:
                        extends = f" extends {cls['extends']}" if cls['extends'] else ""
                        sections.append(f"- `{cls['name']}`{extends}")
                    sections.append("")
                
                if file_analyzer.functions:
                    sections.append(f"**Functions:** {len(file_analyzer.functions)}")
                    if len(file_analyzer.functions) <= MAX_FUNCTIONS_DISPLAY:
                        for func in file_analyzer.functions:
                            sections.append(f"- `{func}()`")
                    else:
                        for func in file_analyzer.functions[:MAX_FUNCTIONS_DISPLAY]:
                            sections.append(f"- `{func}()`")
                        sections.append(f"- ... and {len(file_analyzer.functions) - MAX_FUNCTIONS_DISPLAY} more")
                    sections.append("")
                
                if file_analyzer.constants:
                    sections.append(f"**Constants:** {', '.join(file_analyzer.constants)}\n")
                
                if file_analyzer.imports:
                    sections.append(f"**Dependencies:** {len(file_analyzer.imports)} imports\n")
                
                if file_analyzer.exports:
                    sections.append(f"**Exports:** {', '.join(file_analyzer.exports)}\n")
                
                sections.append("---\n")
        
        return '\n'.join(sections)
    
    def _generate_dependency_graph(self) -> str:
        """Generate system dependency graph."""
        return """---

## 7. Dependency Graph

### 7.1 High-Level Module Dependencies

```mermaid
graph TB
    subgraph "Main Process"
        Main[main.js]
        ClaudeService[claude-service.js]
        PuffinState[puffin-state.js]
        IPCHandlers[ipc-handlers.js]
        GitService[git-service.js]
        PluginMgr[Plugin System]
    end
    
    subgraph "Renderer Process"
        App[app.js]
        SAMModel[SAM Model]
        SAMState[SAM State]
        SAMActions[SAM Actions]
        Components[UI Components]
        PluginLoader[Plugin Loader]
    end
    
    subgraph "Shared"
        Validators[validators.js]
        Models[models.js]
        Constants[constants.js]
    end
    
    Main --> ClaudeService
    Main --> PuffinState
    Main --> IPCHandlers
    Main --> GitService
    Main --> PluginMgr
    
    IPCHandlers --> ClaudeService
    IPCHandlers --> PuffinState
    IPCHandlers --> GitService
    
    App --> SAMModel
    App --> Components
    SAMModel --> SAMState
    SAMState --> SAMActions
    SAMActions --> SAMModel
    Components --> SAMActions
    Components --> PluginLoader
    
    SAMModel --> |IPC| IPCHandlers
    Components --> |IPC| IPCHandlers
    
    ClaudeService --> Validators
    PuffinState --> Validators
    Components --> Models
    SAMModel --> Constants
    
    style Main fill:#2C3E50,stroke:#1A252F,color:#fff
    style App fill:#8E44AD,stroke:#6C3483,color:#fff
    style Validators fill:#27AE60,stroke:#1E8449,color:#fff
```

### 7.2 Data Flow

```mermaid
sequenceDiagram
    participant User
    participant UI as Renderer UI
    participant SAM as SAM Pattern
    participant IPC as IPC Bridge
    participant Main as Main Process
    participant Claude as Claude CLI
    
    User->>UI: Submit Prompt
    UI->>SAM: dispatch(submitPrompt)
    SAM->>SAM: validate & update model
    SAM->>IPC: send(execute-prompt)
    IPC->>Main: forward request
    Main->>Claude: spawn with prompt
    
    loop Streaming Response
        Claude-->>Main: chunk
        Main-->>IPC: emit(response-chunk)
        IPC-->>SAM: handle chunk
        SAM-->>UI: update view
        UI-->>User: display
    end
    
    Claude-->>Main: complete
    Main-->>IPC: emit(response-complete)
    IPC-->>SAM: handle complete
    SAM-->>UI: final update
```

---

## 8. Formal Properties & Invariants

### System Invariants

**SI-1: Single Active Claude Process**
```
∀ t: time : |active_claude_processes(t)| ≤ 1
```

**SI-2: State Consistency**
```
renderer_state.prompt_status = 'streaming' ⟹
main_process.claude_session ≠ null
```

**SI-3: History Monotonicity**
```
∀ t₁, t₂: time : t₁ < t₂ ⟹
|conversation_history(t₁)| ≤ |conversation_history(t₂)|
```

**SI-4: Project Path Invariant**
```
application_state = 'ready' ⟹
current_project_path ≠ null ∧
exists(current_project_path + '/.puffin')
```

### Liveness Properties

**L-1: Progress Guarantee**
```
prompt_submitted ⟹ ◇(response_received ∨ error_reported)
```
(Eventually, every submitted prompt gets a response or error)

**L-2: UI Responsiveness**
```
user_action ⟹ ◇(ui_updated)
```
(Every user action eventually results in UI update)

### Safety Properties

**S-1: No Lost Messages**
```
∀ msg: message : sent(msg) ⟹ ◇received(msg)
```

**S-2: State Machine Determinism**
```
∀ state, event : next_state(state, event) is unique
```

---

## 9. Security Considerations

### Secure IPC Bridge (Preload Script)

The preload script creates a secure bridge between Main and Renderer processes:

```
Renderer Context (Untrusted) ←→ Context Bridge ←→ Main Process (Trusted)
```

**Security Properties:**
- No direct Node.js API access from renderer
- Validated IPC message schemas
- No arbitrary code execution paths
- File system access restricted to project directory

### Input Validation Chain

```mermaid
graph LR
    Input[User Input] --> UI[UI Validation]
    UI --> SAM[SAM Model Validation]
    SAM --> IPC[IPC Schema Validation]
    IPC --> Main[Main Process Validation]
    Main --> FS[File System Operation]
    
    style UI fill:#E74C3C,stroke:#C0392B
    style SAM fill:#E74C3C,stroke:#C0392B
    style IPC fill:#E74C3C,stroke:#C0392B
    style Main fill:#E74C3C,stroke:#C0392B
```

---

## 10. Extensibility: Plugin System

### Plugin Architecture

```mermaid
graph TB
    PluginAPI[Plugin API]
    PluginMgr[Plugin Manager]
    PluginLoader[Plugin Loader]
    PluginRegistry[Plugin Registry]
    
    Plugin1[Plugin A]
    Plugin2[Plugin B]
    Plugin3[Plugin C]
    
    PluginMgr --> PluginLoader
    PluginMgr --> PluginRegistry
    PluginLoader --> Plugin1
    PluginLoader --> Plugin2
    PluginLoader --> Plugin3
    
    Plugin1 --> PluginAPI
    Plugin2 --> PluginAPI
    Plugin3 --> PluginAPI
    
    PluginAPI --> |Contributes| Views[Views]
    PluginAPI --> |Contributes| Commands[Commands]
    PluginAPI --> |Contributes| Providers[Data Providers]
```

**Plugin Specification:**
```
PLUGIN = ⟨ manifest, activate, deactivate, contributions ⟩

manifest = {
    id: STRING,
    version: SEMVER,
    dependencies: SET(PLUGIN_ID),
    activationEvents: SET(EVENT)
}

contributions = {
    views: SET(VIEW_CONTRIBUTION),
    commands: SET(COMMAND_CONTRIBUTION),
    providers: SET(PROVIDER_CONTRIBUTION)
}
```

---

## 11. Conclusion

This overview presents Puffin as a formally specified system with clear architectural layers, state machines, and refinement relationships. The B-method inspired approach provides:

1. **Formal Specifications**: Clear contracts for each component
2. **Refinement Layers**: Traceable implementation from abstract to concrete
3. **Invariant Properties**: Mathematically expressible system constraints
4. **Visual Models**: Mermaid diagrams for architecture understanding

**Next Steps for Readers:**
- Review module catalog (Section 6) for detailed component specifications
- Examine state machines (Section 4) for behavior understanding
- Consult dependency graph (Section 7) for integration points
- Reference security considerations (Section 9) for secure development

---

*Generated by automated source code analysis*  
*Project: Puffin - A GUI for Claude Code*  
*Repository: https://github.com/roehst/puffin*
"""


def main():
    """Main entry point for the overview generator."""
    import sys
    
    # Get the base path of the project (script directory or command line arg)
    if len(sys.argv) > 1:
        base_path = os.path.abspath(sys.argv[1])
        if not os.path.isdir(base_path):
            print(f"Error: '{base_path}' is not a valid directory")
            sys.exit(1)
    else:
        base_path = os.path.dirname(os.path.abspath(__file__))
    
    # Verify we're in a Puffin project (has src directory)
    src_path = os.path.join(base_path, 'src')
    if not os.path.isdir(src_path):
        print(f"Error: No 'src' directory found in {base_path}")
        print("This script should be run from the Puffin project root directory")
        print("Usage: python3 generate_overview.py [project_path]")
        sys.exit(1)
    
    print("Puffin OVERVIEW.md Generator")
    print("=" * 50)
    print(f"Analyzing project at: {base_path}")
    print()
    
    # Create generator and scan files
    generator = OverviewGenerator(base_path)
    
    print("Scanning JavaScript files...")
    generator.scan_files()
    print(f"Found {len(generator.files)} source files")
    print()
    
    print("Categories found:")
    for category, files in sorted(generator.categories.items()):
        print(f"  - {category}: {len(files)} files")
    print()
    
    # Generate overview
    print("Generating OVERVIEW.md...")
    overview_content = generator.generate_overview()
    
    # Write to file
    output_path = os.path.join(base_path, 'OVERVIEW.md')
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(overview_content)
    except IOError as e:
        print(f"Error: Failed to write OVERVIEW.md: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Unexpected error while writing file: {e}")
        sys.exit(1)
    
    print(f"✓ OVERVIEW.md generated successfully!")
    print(f"  Location: {output_path}")
    print(f"  Size: {len(overview_content)} characters")
    print()
    print("Done!")


if __name__ == '__main__':
    main()
