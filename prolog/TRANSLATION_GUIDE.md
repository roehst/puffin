# Prolog Translation Guide

This document explains how Puffin's JavaScript code has been translated to Prolog and how to extend it.

## Philosophy

The translation follows these principles:

1. **Separate Concerns**: JavaScript handles UI and I/O, Prolog handles pure logic
2. **Declarative over Imperative**: Express rules and relationships, not procedures
3. **Pattern Matching**: Leverage Prolog's unification for elegant solutions
4. **Type Safety**: Use structured terms and dicts for type checking

## Translation Patterns

### Validation Rules

**JavaScript** (imperative):
```javascript
function validateProject(project) {
  const errors = []
  if (!project.name) errors.push('Name required')
  if (!project.description) errors.push('Description required')
  return { valid: errors.length === 0, errors }
}
```

**Prolog** (declarative):
```prolog
validate_project(Project, Result) :-
    findall(Error, project_error(Project, Error), Errors),
    (Errors = [] -> Result = valid ; Result = invalid(Errors)).

project_error(Project, 'Name required') :- 
    \+ get_dict(name, Project, _).
project_error(Project, 'Description required') :- 
    \+ get_dict(description, Project, _).
```

### State Management

**JavaScript** (SAM pattern):
```javascript
function acceptor(model, proposal) {
  if (proposal.action === 'init') {
    return { ...model, initialized: true, path: proposal.path }
  }
  return model
}
```

**Prolog** (pattern matching):
```prolog
apply_proposal(Model, Proposal, NewModel) :-
    get_dict(action, Proposal, init),
    get_dict(path, Proposal, Path),
    NewModel = Model.put([initialized: true, path: Path]).
```

### Model Definitions

**JavaScript** (array of objects):
```javascript
const MODELS = [
  { id: 'opus', name: 'Claude Opus', tier: 'premium' },
  { id: 'sonnet', name: 'Claude Sonnet', tier: 'standard' }
]
```

**Prolog** (facts):
```prolog
claude_model(opus, 'Claude Opus', 'Best for complex tasks', premium).
claude_model(sonnet, 'Claude Sonnet', 'Balanced performance', standard).
```

## Integration Patterns

### Calling Prolog from JavaScript

```javascript
const prologBridge = require('./prolog-bridge')

// Validation
const result = await prologBridge.validateProject({
  name: 'My Project',
  description: 'A test project'
})

// Model queries
const model = await prologBridge.getModel('opus')
const allModels = await prologBridge.getAllModels()

// State management
// (Currently done in JavaScript, can be migrated)
```

### Data Conversion

JavaScript objects are converted to Prolog dicts:

```javascript
// JavaScript
{ name: 'Test', value: 42, items: ['a', 'b'] }

// Prolog dict
_{name: 'Test', value: 42, items: ['a', 'b']}
```

## Extending the Prolog Backend

### Adding New Validators

1. Add validation predicate to `validators.pl`:

```prolog
validate_user(User, Result) :-
    findall(Error, user_error(User, Error), Errors),
    (Errors = [] -> Result = valid ; Result = invalid(Errors)).

user_error(User, 'Email required') :-
    \+ get_dict(email, User, _).
user_error(User, 'Invalid email') :-
    get_dict(email, User, Email),
    \+ email_format(Email).
```

2. Export from module:

```prolog
:- module(validators, [
    ...,
    validate_user/2
]).
```

3. Add to bridge (`prolog-bridge.js`):

```javascript
async validateUser(user) {
  const userDict = this.toDict(user)
  const query = `validate_user(${userDict}, Result), ...`
  const result = await this.query(query)
  return this.parseValidationResult(result)
}
```

### Adding New Business Rules

Create a new module in `prolog/`:

```prolog
% rules.pl
:- module(rules, [
    can_user_access/3,
    is_task_complete/2
]).

can_user_access(User, Resource, Access) :-
    get_dict(role, User, Role),
    resource_permission(Resource, Role, Access).

resource_permission(project, admin, read_write).
resource_permission(project, user, read).
```

### Adding Complex Queries

Use Prolog's query capabilities:

```prolog
% Find all incomplete tasks for a user
incomplete_tasks(User, Tasks) :-
    user_id(User, UserId),
    findall(Task, (
        task(Task),
        get_dict(assigned_to, Task, UserId),
        get_dict(status, Task, Status),
        Status \= completed
    ), Tasks).
```

## Testing

### Unit Tests

Add tests to `test.pl`:

```prolog
test_new_feature :-
    write('Testing new feature...'), nl,
    validate_user(user{email: 'test@example.com'}, Result),
    (Result = valid -> 
        write('  ✓ Valid user passes') ; 
        write('  ✗ Test failed')), nl.
```

### Integration Tests

Add tests to `tests/prolog-bridge.test.js`:

```javascript
describe('validateUser', () => {
  it('should validate a valid user', async () => {
    const user = { email: 'test@example.com', name: 'Test' }
    const result = await prologBridge.validateUser(user)
    assert.strictEqual(result.valid, true)
  })
})
```

## Performance Considerations

1. **Indexing**: Prolog indexes first argument - put most specific terms first
2. **Cut (`!`)**: Use judiciously to prevent backtracking
3. **Tail Recursion**: Use for list processing
4. **Tabling**: Use `table` directive for expensive computations

Example:
```prolog
% Efficient with indexing
validate_by_type(project, Data, Result) :- validate_project(Data, Result).
validate_by_type(prompt, Data, Result) :- validate_prompt(Data, Result).
validate_by_type(user, Data, Result) :- validate_user(Data, Result).
```

## Best Practices

1. **Keep predicates pure**: No side effects in logic predicates
2. **Use descriptive names**: `is_valid_project/1` not `check/1`
3. **Document with comments**: Use `%` for single line, `/** */` for blocks
4. **Fail fast**: Put most restrictive checks first
5. **Use dicts**: More readable than positional arguments
6. **Export carefully**: Only export what's needed in the API

## Common Pitfalls

### 1. Variable Scoping

**Wrong**:
```prolog
process(Data) :-
    get_dict(value, Data, Value),
    Value = 42.  % Unifies, doesn't check
```

**Right**:
```prolog
process(Data) :-
    get_dict(value, Data, 42).  % Pattern match directly
```

### 2. List Processing

**Wrong**:
```prolog
sum_list([], Sum) :- Sum = 0.
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum = H + Rest.
```

**Right**:
```prolog
sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.
```

### 3. String Handling

**Wrong**:
```prolog
concat(A, B, C) :- C = A + B.  % Doesn't work
```

**Right**:
```prolog
concat(A, B, C) :- string_concat(A, B, C).
```

## Resources

- [SWI-Prolog Documentation](https://www.swi-prolog.org/pldoc/doc_for?object=manual)
- [Learn Prolog Now!](http://www.learnprolognow.org/)
- [The Power of Prolog](https://www.metalevel.at/prolog)
- Puffin Prolog modules: `prolog/*.pl`
- Interactive examples: `swipl -s prolog/examples.pl`

## Future Enhancements

Potential areas to translate to Prolog:

1. **Workflow Engine**: Define workflows as Prolog rules
2. **Dependency Resolution**: Use constraint solving for build order
3. **Code Analysis**: Parse and analyze code structure
4. **Planning**: Use search to plan implementation steps
5. **Natural Language**: Add NLP predicates for prompt analysis
