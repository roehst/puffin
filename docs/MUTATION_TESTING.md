# Mutation Testing Module

## Overview

The Mutation Testing module provides automated mutation testing capabilities for assessing test suite quality. It works by:

1. **Generating mutants** - Creating modified versions of code with injected bugs
2. **Running tests** - Executing tests against each mutant
3. **Counting kills** - Tracking which mutants are detected (killed) by tests
4. **Reporting scores** - Calculating mutation score (percentage of mutants killed)

## Mutation Operators

The module supports five types of mutation operators:

### 1. Arithmetic Operator Replacement
Mutates arithmetic operations to test mathematical logic:
- `+` ↔ `-` (addition/subtraction swap)
- `*` ↔ `/` (multiplication/division swap)
- `%` → `*` (modulo to multiplication)

### 2. Comparison Operator Replacement
Mutates comparison logic:
- `===` ↔ `!==` (equality checks)
- `<` ↔ `<=` (less than variants)
- `>` ↔ `>=` (greater than variants)
- `==` ↔ `!=` (loose equality)

### 3. Logical Operator Replacement
Mutates boolean logic:
- `&&` ↔ `||` (AND/OR swap)

### 4. Unary Operator Replacement
Mutates increment/decrement:
- `++` ↔ `--` (increment/decrement swap)

### 5. Return Value Mutation
Mutates return values:
- `return true` ↔ `return false`
- `return 0` ↔ `return 1`

## Usage

### From Node.js Code

```javascript
const { MutationTestingService } = require('./src/main/mutation-testing.js')

// Initialize service
const service = new MutationTestingService()
service.setProjectPath('/path/to/project')

// Get available operators
const operators = service.getAvailableOperators()
console.log('Available operators:', operators)

// Generate mutants for a file
const mutants = await service.generateMutants('src/calculator.js', ['ARITHMETIC', 'COMPARISON'])
console.log(`Generated ${mutants.length} mutants`)

// Run mutation testing
const report = await service.runMutationTesting('npm test')

// View results
console.log(`Mutation Score: ${report.summary.mutationScore}%`)
console.log(`Killed: ${report.summary.killedMutants}`)
console.log(`Survived: ${report.summary.survivedMutants}`)
console.log(`Total: ${report.summary.totalMutants}`)

// List survived mutants (these indicate weak test coverage)
report.survivedMutants.forEach(mutant => {
  console.log(`Survived mutant at ${mutant.filePath}:${mutant.line}`)
  console.log(`  Operator: ${mutant.operator}`)
  console.log(`  Mutation: ${mutant.mutation}`)
})
```

### From Electron IPC (Renderer Process)

```javascript
// Get available operators
const { operators } = await window.api.invoke('mutation:getOperators')

// Generate mutants
const { mutants, count } = await window.api.invoke('mutation:generateMutants', {
  filePath: 'src/calculator.js',
  operators: ['ARITHMETIC'] // optional, defaults to all
})

// Run mutation testing
const { report } = await window.api.invoke('mutation:runTests', {
  testCommand: 'npm test' // optional, defaults to 'npm test'
})

// Get current report (without running tests)
const { report } = await window.api.invoke('mutation:getReport')

// Reset state
await window.api.invoke('mutation:reset')
```

## Example Workflow

```javascript
// 1. Generate mutants for a specific file
const mutants = await service.generateMutants('src/math-utils.js')
console.log(`Generated ${mutants.length} mutants to test`)

// 2. Run tests against each mutant
const report = await service.runMutationTesting('npm test')

// 3. Analyze results
console.log(`\nMutation Testing Report`)
console.log(`======================`)
console.log(`Total Mutants: ${report.summary.totalMutants}`)
console.log(`Killed: ${report.summary.killedMutants}`)
console.log(`Survived: ${report.summary.survivedMutants}`)
console.log(`Mutation Score: ${report.summary.mutationScore}%`)
console.log(`Duration: ${report.summary.duration}ms`)

// 4. Identify weak spots in test coverage
if (report.survivedMutants.length > 0) {
  console.log(`\nSurvived Mutants (add tests for these):`)
  report.survivedMutants.forEach(m => {
    console.log(`  ${m.filePath}:${m.line} - ${m.mutation}`)
  })
}
```

## Understanding Results

### Mutation Score
The mutation score is the percentage of mutants killed by tests:
- **100%** - Perfect! All mutations detected
- **80-99%** - Good test coverage
- **60-79%** - Acceptable, room for improvement
- **< 60%** - Weak test coverage, add more tests

### Killed Mutants
A mutant is "killed" when tests fail after the mutation is applied. This is good - it means your tests detected the bug.

### Survived Mutants
A mutant "survives" when all tests pass despite the mutation. This indicates:
- Missing test cases
- Weak assertions
- Dead code (code that doesn't affect behavior)

## Best Practices

1. **Start small** - Begin with one file or module
2. **Focus on critical code** - Prioritize business logic and complex algorithms
3. **Use specific operators** - Start with ARITHMETIC and COMPARISON
4. **Review survived mutants** - These show where to add tests
5. **Run regularly** - Include in CI/CD for ongoing quality assurance

## API Reference

### MutationTestingService

#### Methods

- `setProjectPath(path)` - Set the project directory
- `getAvailableOperators()` - Get list of available mutation operators
- `generateMutants(filePath, operators)` - Generate mutants for a file
- `testMutant(mutant, testCommand)` - Test a single mutant
- `runMutationTesting(testCommand)` - Run tests against all mutants
- `generateReport(duration)` - Generate mutation testing report
- `reset()` - Clear all mutants and results

#### Report Structure

```javascript
{
  summary: {
    totalMutants: 10,
    killedMutants: 8,
    survivedMutants: 2,
    mutationScore: "80.00",
    duration: 15000
  },
  results: [
    {
      mutantId: 0,
      filePath: "src/math.js",
      line: 5,
      operator: "Arithmetic Operator Replacement",
      mutation: "Replace addition with subtraction",
      killed: true,
      timestamp: "2025-12-27T16:00:00.000Z"
    }
  ],
  survivedMutants: [
    {
      mutantId: 9,
      filePath: "src/math.js",
      line: 15,
      operator: "Comparison Operator Replacement",
      mutation: "Replace equals with not equals"
    }
  ]
}
```

## IPC Handlers

The following IPC handlers are available for use in the Electron renderer process:

- `mutation:getOperators` - Get available mutation operators
- `mutation:generateMutants` - Generate mutants for a file
- `mutation:runTests` - Run mutation testing
- `mutation:getReport` - Get current report
- `mutation:reset` - Reset mutation testing state

## Integration with Puffin

The mutation testing module integrates seamlessly with Puffin's architecture:

1. **Service layer** - `MutationTestingService` in `src/main/mutation-testing.js`
2. **IPC handlers** - Exposed through `setupMutationTestingHandlers` in `src/main/ipc-handlers.js`
3. **Tests** - Comprehensive test suite in `tests/mutation-testing.test.js`

## Future Enhancements

Potential improvements for future versions:

- Additional mutation operators (assignment, conditional boundaries)
- Parallel test execution for faster results
- HTML report generation
- Integration with coverage tools
- Mutation caching to skip equivalent mutants
- Configuration file support
