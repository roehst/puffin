# Mutation Testing Examples

This directory contains examples demonstrating the mutation testing functionality in Puffin.

## Running the Example

```bash
node examples/mutation-testing-example.js
```

## What the Example Does

The example script demonstrates:

1. **Loading the mutation testing service** - Initializes the `MutationTestingService`
2. **Listing available operators** - Shows all mutation operators (ARITHMETIC, COMPARISON, LOGICAL, UNARY, RETURN)
3. **Generating mutants** - Creates mutated versions of sample code
4. **Displaying mutants** - Shows details about each mutation
5. **Simulating test execution** - Demonstrates how tests would be run against mutants
6. **Generating a report** - Shows mutation score and identifies weak test coverage

## Output

You'll see:
- List of available mutation operators and their counts
- Number of mutants generated for the sample code
- Details of the first 5 mutants (location, operator, mutation type)
- A mutation testing report with:
  - Total mutants
  - Killed mutants (detected by tests)
  - Survived mutants (not detected by tests)
  - Mutation score (percentage)
  - Execution time
- List of survived mutants that need better test coverage

## Understanding the Results

- **Mutation Score**: Percentage of mutants killed by tests (higher is better)
- **Killed Mutants**: Bugs that were caught by tests ✓
- **Survived Mutants**: Bugs that weren't caught (areas needing more tests) ✗

A high mutation score (80%+) indicates good test quality, while survived mutants show where to add more tests.

## Integration with Puffin

In a real Puffin application, you would:

1. Use the IPC handlers to call mutation testing from the renderer process
2. Generate mutants for specific files in your project
3. Run your actual test suite against each mutant
4. Review the report to identify weak test coverage
5. Add tests to kill survived mutants

See `docs/MUTATION_TESTING.md` for complete API documentation.
