#!/usr/bin/env node

/**
 * Mutation Testing Example
 * 
 * This script demonstrates how to use the MutationTestingService
 * to test code quality through mutation testing.
 */

const path = require('path')
const { MutationTestingService } = require('../src/main/mutation-testing.js')

async function main() {
  console.log('Mutation Testing Example\n')
  console.log('========================\n')

  // Initialize the service
  const service = new MutationTestingService()
  const projectPath = path.resolve(__dirname, '..')
  service.setProjectPath(projectPath)

  // 1. Show available operators
  console.log('1. Available Mutation Operators:')
  const operators = service.getAvailableOperators()
  Object.entries(operators).forEach(([key, op]) => {
    console.log(`   ${key}: ${op.name} (${op.mutationCount} mutations)`)
  })
  console.log()

  // 2. Generate mutants for a sample file
  console.log('2. Generating mutants for tests/mutation-testing.test.js...')
  
  try {
    // Create a simple test file
    const fs = require('fs').promises
    const sampleFile = path.join(projectPath, 'examples', 'sample-code.js')
    
    // Ensure examples directory exists
    await fs.mkdir(path.join(projectPath, 'examples'), { recursive: true })
    
    // Write sample code
    const sampleCode = `
// Sample code for mutation testing
function add(a, b) {
  return a + b;
}

function isPositive(n) {
  return n > 0;
}

function isEven(n) {
  return n % 2 === 0;
}

function greet(name) {
  if (name && name.length > 0) {
    return 'Hello, ' + name;
  }
  return 'Hello, stranger';
}

module.exports = { add, isPositive, isEven, greet };
`
    await fs.writeFile(sampleFile, sampleCode, 'utf-8')
    
    const mutants = await service.generateMutants(sampleFile)
    console.log(`   Generated ${mutants.length} mutants`)
    console.log()

    // 3. Show some example mutants
    console.log('3. Sample Mutants:')
    mutants.slice(0, 5).forEach(m => {
      console.log(`   Mutant #${m.id}:`)
      console.log(`     Location: Line ${m.line}`)
      console.log(`     Operator: ${m.operator}`)
      console.log(`     Mutation: ${m.mutation}`)
      console.log()
    })

    // 4. Simulate test results (since we don't have real tests for the sample)
    console.log('4. Simulating Mutation Testing...')
    console.log('   (In a real scenario, this would run actual tests)')
    console.log()

    // Create mock results for demonstration
    const mockResults = mutants.map((mutant, index) => {
      // Simulate: 80% of mutants are killed
      const killed = Math.random() < 0.8
      return {
        mutant,
        killed,
        testOutput: killed ? 'Tests failed (mutant killed)' : 'All tests passed (mutant survived)'
      }
    })

    service.results = mockResults

    // 5. Generate and display report
    const report = service.generateReport(5000) // 5 seconds simulated duration
    
    console.log('5. Mutation Testing Report:')
    console.log('   ' + '='.repeat(50))
    console.log(`   Total Mutants:    ${report.summary.totalMutants}`)
    console.log(`   Killed:           ${report.summary.killedMutants} ✓`)
    console.log(`   Survived:         ${report.summary.survivedMutants} ✗`)
    console.log(`   Mutation Score:   ${report.summary.mutationScore}%`)
    console.log(`   Duration:         ${report.summary.duration}ms`)
    console.log('   ' + '='.repeat(50))
    console.log()

    // 6. Show survived mutants (areas needing better tests)
    if (report.survivedMutants.length > 0) {
      console.log('6. Survived Mutants (areas needing better test coverage):')
      report.survivedMutants.forEach(m => {
        console.log(`   Line ${m.line}: ${m.mutation}`)
      })
      console.log()
      console.log('   💡 Tip: Add tests to catch these mutations!')
    } else {
      console.log('6. Perfect! All mutants were killed! 🎉')
    }

    console.log()
    console.log('Example completed successfully!')
    
  } catch (error) {
    console.error('Error:', error.message)
    process.exit(1)
  }
}

// Run the example
main().catch(console.error)
