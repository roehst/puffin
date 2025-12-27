# Puffin Prolog Implementation

This directory contains the Prolog translation of Puffin's core business logic.

## Overview

The Puffin application has been translated to Prolog to leverage logic programming for:
- **Validation**: Declarative rule-based validation of entities
- **State Management**: Clean state transitions using the SAM pattern
- **Business Rules**: Logic programming for complex decision-making
- **Type Safety**: Stronger guarantees through Prolog's unification and pattern matching

## Architecture

```
JavaScript (Electron)  <-->  Node.js Bridge  <-->  Prolog Backend
     (UI Layer)              (Integration)         (Logic Layer)
```

The JavaScript/Electron frontend handles all UI concerns, while the Prolog backend provides:
- Pure logic and business rules
- Validation predicates
- State management
- Model definitions

## Modules

### `puffin.pl` - Main Module
Entry point that re-exports all submodules.

```prolog
?- use_module('puffin.pl').
?- puffin_info.
```

### `validators.pl` - Validation Predicates
Declarative validation for:
- Projects
- Prompts
- GUI elements
- Branches
- File paths
- String sanitization

**Examples:**
```prolog
% Validate a project
?- validate_project(
     project{name: 'My Project', description: 'A test project', assumptions: []},
     Result).
Result = valid.

% Validate an invalid project
?- validate_project(project{description: 'No name'}, Result).
Result = invalid(['Project name is required']).

% Check file path security
?- is_valid_file_path('valid/path/file.txt').
true.

?- is_valid_file_path('../etc/passwd').
false.
```

### `models.pl` - Claude Model Definitions
Defines available Claude models and their properties.

**Examples:**
```prolog
% Query a model
?- claude_model(opus, Name, Description, Tier).
Name = 'Claude Opus',
Description = 'Most capable, best for complex tasks',
Tier = premium.

% Get default model
?- default_model(Model).
Model = opus.

% List all models
?- all_models(Models).
Models = [opus, sonnet, haiku].
```

### `state.pl` - State Management
Implements the SAM (State-Action-Model) pattern in Prolog.

**Examples:**
```prolog
% Get initial model
?- initial_model(Model).
Model = model{initialized: false, ...}.

% Apply a proposal
?- initial_model(M),
   apply_proposal(M, proposal{action: init, project_path: '/test', project_name: 'Test'}, NewM),
   get_dict(initialized, NewM, Init).
Init = true.

% State transitions
?- transition(uninitialized, init, NextState).
NextState = initializing.
```

### `formatters.pl` - Formatting Utilities
String formatting, date formatting, and data transformations.

**Examples:**
```prolog
% Generate UUID
?- generate_id(Id).
Id = "550e8400-e29b-41d4-a716-446655440000".

% Truncate text
?- truncate('This is a very long text that should be truncated', 20, Result).
Result = "This is a very lo...".

% Format file size
?- format_file_size(1024, Size).
Size = "1.00 KB".
```

## Running Tests

Run the test suite:

```bash
cd prolog
swipl -g "halt" test.pl
```

You should see output like:
```
=== Puffin Prolog Test Suite ===

Testing validators...
  ✓ Valid project passes
  ✓ Invalid project detected
  ...
```

## Integration with JavaScript

The `prolog-bridge.js` module provides a Node.js interface to the Prolog backend:

```javascript
const prologBridge = require('./src/main/prolog-bridge');

// Validate a project
const result = await prologBridge.validateProject({
  name: 'My Project',
  description: 'A test project',
  assumptions: []
});
// result: { valid: true, errors: [] }

// Get a model
const model = await prologBridge.getModel('opus');
// model: { id: 'opus', name: 'Claude Opus', ... }

// Generate ID
const id = await prologBridge.generateId();
// id: "550e8400-e29b-41d4-a716-446655440000"
```

## Requirements

- **SWI-Prolog 9.0+**: Install with `apt-get install swi-prolog` (Linux) or from [swi-prolog.org](https://www.swi-prolog.org/)
- **Node.js 18+**: For the JavaScript bridge

## Interactive REPL

Start an interactive Prolog session:

```bash
cd prolog
swipl puffin.pl
```

Then query interactively:
```prolog
?- puffin_info.
?- validate_project(project{name: 'Test', description: 'A test'}, R).
?- claude_model(opus, N, D, T).
```

Press `Ctrl+D` to exit.

## Design Principles

1. **Pure Logic**: All predicates are pure (no side effects) for better testability
2. **Declarative**: Validation rules are expressed declaratively, not procedurally
3. **Pattern Matching**: Leverage Prolog's unification for elegant solutions
4. **Composability**: Small, focused predicates that compose well
5. **Type Safety**: Use dicts and structured terms for type safety

## Future Enhancements

Potential areas for expansion:
- **Query Optimization**: Add indexing for large datasets
- **Constraint Solving**: Use CLP(FD) for complex scheduling
- **Rule Learning**: Add machine learning capabilities
- **Distributed Computing**: Scale with Prolog's concurrent features
- **Natural Language**: Integrate NLP for better prompt understanding

## Contributing

When adding new Prolog modules:
1. Create a new `.pl` file with proper module declaration
2. Export predicates in the module declaration
3. Add tests to `test.pl`
4. Re-export from `puffin.pl` if part of the public API
5. Update this README with examples

## License

MIT
