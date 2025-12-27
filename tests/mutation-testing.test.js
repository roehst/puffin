/**
 * Tests for MutationTestingService
 *
 * Tests mutation testing functionality including:
 * - Mutant generation with different operators
 * - Test execution against mutants
 * - Mutation score calculation
 * - Report generation
 */

const { describe, it, beforeEach, afterEach } = require('node:test')
const assert = require('node:assert')
const fs = require('fs').promises
const path = require('path')
const os = require('os')

// Import the module under test
const { MutationTestingService, Mutant, MutationResult, MUTATION_OPERATORS } = require('../src/main/mutation-testing.js')

describe('MutationTestingService', () => {
  let service
  let testDir

  beforeEach(async () => {
    // Create a temporary directory for each test
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), 'mutation-test-'))
    service = new MutationTestingService()
    service.setProjectPath(testDir)
  })

  afterEach(async () => {
    // Clean up temporary directory
    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch (e) {
      // Ignore cleanup errors
    }
  })

  describe('setProjectPath', () => {
    it('should set the project path', () => {
      const newPath = '/test/path'
      service.setProjectPath(newPath)
      assert.strictEqual(service.projectPath, newPath)
    })
  })

  describe('getAvailableOperators', () => {
    it('should return all available mutation operators', () => {
      const operators = service.getAvailableOperators()
      
      assert.ok(operators.ARITHMETIC)
      assert.ok(operators.COMPARISON)
      assert.ok(operators.LOGICAL)
      assert.ok(operators.UNARY)
      assert.ok(operators.RETURN)
      
      assert.strictEqual(typeof operators.ARITHMETIC.name, 'string')
      assert.strictEqual(typeof operators.ARITHMETIC.mutationCount, 'number')
    })

    it('should have correct mutation counts', () => {
      const operators = service.getAvailableOperators()
      
      assert.ok(operators.ARITHMETIC.mutationCount > 0)
      assert.ok(operators.COMPARISON.mutationCount > 0)
      assert.ok(operators.LOGICAL.mutationCount > 0)
    })
  })

  describe('generateMutants', () => {
    it('should generate arithmetic mutants', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = `
function add(a, b) {
  return a + b;
}

function subtract(a, b) {
  return a - b;
}
`
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['ARITHMETIC'])
      
      assert.ok(mutants.length > 0)
      assert.ok(mutants.some(m => m.mutation.includes('addition')))
      assert.ok(mutants.some(m => m.mutation.includes('subtraction')))
    })

    it('should generate comparison mutants', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = `
function isEqual(a, b) {
  return a === b;
}

function isGreater(a, b) {
  return a > b;
}
`
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['COMPARISON'])
      
      assert.ok(mutants.length > 0)
      assert.ok(mutants.some(m => m.mutation.includes('equals')))
      assert.ok(mutants.some(m => m.mutation.includes('greater')))
    })

    it('should generate logical mutants', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = `
function checkBoth(a, b) {
  return a && b;
}

function checkEither(a, b) {
  return a || b;
}
`
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['LOGICAL'])
      
      assert.ok(mutants.length > 0)
      assert.ok(mutants.some(m => m.mutation.includes('AND')))
      assert.ok(mutants.some(m => m.mutation.includes('OR')))
    })

    it('should generate return value mutants', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = `
function isTrue() {
  return true;
}

function isFalse() {
  return false;
}

function getZero() {
  return 0;
}
`
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['RETURN'])
      
      assert.ok(mutants.length > 0)
      assert.ok(mutants.some(m => m.mutation.includes('true')))
      assert.ok(mutants.some(m => m.mutation.includes('false')))
    })

    it('should generate all mutants when no operators specified', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = `
function calculate(a, b) {
  if (a > b && a === 10) {
    return true;
  }
  return a + b;
}
`
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile)
      
      assert.ok(mutants.length > 0)
      
      // Should have mutants from multiple operators
      const operators = new Set(mutants.map(m => m.operator))
      assert.ok(operators.size > 1)
    })

    it('should store mutants with correct metadata', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = 'function test() { return 1 + 2; }'
      await fs.writeFile(testFile, code, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['ARITHMETIC'])
      
      const mutant = mutants[0]
      assert.strictEqual(typeof mutant.id, 'number')
      assert.strictEqual(mutant.filePath, testFile)
      assert.strictEqual(typeof mutant.originalCode, 'string')
      assert.strictEqual(typeof mutant.mutatedCode, 'string')
      assert.strictEqual(typeof mutant.operator, 'string')
      assert.strictEqual(typeof mutant.mutation, 'string')
      assert.strictEqual(typeof mutant.line, 'number')
      assert.ok(mutant.line > 0)
    })

    it('should handle files with no mutatable code', async () => {
      const testFile = path.join(testDir, 'test.js')
      const code = '/* Comment block */\nconst x = 2;'
      await fs.writeFile(testFile, code, 'utf-8')

      // Only use operators that won't match this code
      const mutants = await service.generateMutants(testFile, ['LOGICAL'])
      
      assert.strictEqual(mutants.length, 0)
    })

    it('should throw error for non-existent file', async () => {
      const nonExistentFile = path.join(testDir, 'nonexistent.js')

      await assert.rejects(
        async () => {
          await service.generateMutants(nonExistentFile)
        },
        /Failed to generate mutants/
      )
    })
  })

  describe('testMutant', () => {
    it('should test a mutant and restore original code', async () => {
      const testFile = path.join(testDir, 'test.js')
      const originalCode = 'function test() { return 1 + 2; }'
      await fs.writeFile(testFile, originalCode, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['ARITHMETIC'])
      assert.ok(mutants.length > 0)

      const mutant = mutants[0]
      
      // Create a simple test command that always succeeds
      const result = await service.testMutant(mutant, 'node --version')

      // Check that original code was restored
      const restoredCode = await fs.readFile(testFile, 'utf-8')
      assert.strictEqual(restoredCode, originalCode)

      // Check result structure
      assert.ok(result instanceof MutationResult)
      assert.strictEqual(result.mutant, mutant)
      assert.strictEqual(typeof result.killed, 'boolean')
      assert.strictEqual(typeof result.testOutput, 'string')
      assert.ok(result.timestamp)
    })

    it('should mark mutant as killed when tests fail', async () => {
      const testFile = path.join(testDir, 'test.js')
      const originalCode = 'function test() { return 1 + 2; }'
      await fs.writeFile(testFile, originalCode, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['ARITHMETIC'])
      const mutant = mutants[0]
      
      // Use a command that fails (exit code 1)
      const result = await service.testMutant(mutant, 'node -e "process.exit(1)"')

      assert.strictEqual(result.killed, true)
    })

    it('should mark mutant as survived when tests pass', async () => {
      const testFile = path.join(testDir, 'test.js')
      const originalCode = 'function test() { return 1 + 2; }'
      await fs.writeFile(testFile, originalCode, 'utf-8')

      const mutants = await service.generateMutants(testFile, ['ARITHMETIC'])
      const mutant = mutants[0]
      
      // Use a command that succeeds (exit code 0)
      const result = await service.testMutant(mutant, 'node --version')

      assert.strictEqual(result.killed, false)
    })
  })

  describe('generateReport', () => {
    it('should generate correct mutation score', () => {
      // Create mock results
      const mutant1 = new Mutant(0, 'test.js', 'original', 'mutated1', 'Op1', 'Mut1', 1)
      const mutant2 = new Mutant(1, 'test.js', 'original', 'mutated2', 'Op2', 'Mut2', 2)
      const mutant3 = new Mutant(2, 'test.js', 'original', 'mutated3', 'Op3', 'Mut3', 3)

      service.results = [
        new MutationResult(mutant1, true, 'output1'),
        new MutationResult(mutant2, true, 'output2'),
        new MutationResult(mutant3, false, 'output3')
      ]

      const report = service.generateReport(1000)

      assert.strictEqual(report.summary.totalMutants, 3)
      assert.strictEqual(report.summary.killedMutants, 2)
      assert.strictEqual(report.summary.survivedMutants, 1)
      assert.strictEqual(report.summary.mutationScore, '66.67')
      assert.strictEqual(report.summary.duration, 1000)
    })

    it('should handle zero mutants', () => {
      service.results = []

      const report = service.generateReport(500)

      assert.strictEqual(report.summary.totalMutants, 0)
      assert.strictEqual(report.summary.killedMutants, 0)
      assert.strictEqual(report.summary.survivedMutants, 0)
      assert.strictEqual(report.summary.mutationScore, '0.00')
    })

    it('should include detailed results', () => {
      const mutant = new Mutant(0, 'test.js', 'original', 'mutated', 'TestOp', 'TestMut', 5)
      service.results = [
        new MutationResult(mutant, true, 'output')
      ]

      const report = service.generateReport(100)

      assert.strictEqual(report.results.length, 1)
      assert.strictEqual(report.results[0].mutantId, 0)
      assert.strictEqual(report.results[0].filePath, 'test.js')
      assert.strictEqual(report.results[0].line, 5)
      assert.strictEqual(report.results[0].operator, 'TestOp')
      assert.strictEqual(report.results[0].mutation, 'TestMut')
      assert.strictEqual(report.results[0].killed, true)
    })

    it('should list survived mutants separately', () => {
      const mutant1 = new Mutant(0, 'test.js', 'original', 'mutated1', 'Op1', 'Mut1', 1)
      const mutant2 = new Mutant(1, 'test.js', 'original', 'mutated2', 'Op2', 'Mut2', 2)
      
      service.results = [
        new MutationResult(mutant1, true, 'output1'),
        new MutationResult(mutant2, false, 'output2')
      ]

      const report = service.generateReport(100)

      assert.strictEqual(report.survivedMutants.length, 1)
      assert.strictEqual(report.survivedMutants[0].mutantId, 1)
      assert.strictEqual(report.survivedMutants[0].operator, 'Op2')
    })
  })

  describe('reset', () => {
    it('should clear mutants and results', async () => {
      const testFile = path.join(testDir, 'test.js')
      await fs.writeFile(testFile, 'function test() { return 1 + 2; }', 'utf-8')

      await service.generateMutants(testFile, ['ARITHMETIC'])
      assert.ok(service.mutants.length > 0)

      service.reset()

      assert.strictEqual(service.mutants.length, 0)
      assert.strictEqual(service.results.length, 0)
    })
  })

  describe('Mutant class', () => {
    it('should create mutant with correct properties', () => {
      const mutant = new Mutant(
        1,
        'test.js',
        'original code',
        'mutated code',
        'Test Operator',
        'Test mutation',
        10
      )

      assert.strictEqual(mutant.id, 1)
      assert.strictEqual(mutant.filePath, 'test.js')
      assert.strictEqual(mutant.originalCode, 'original code')
      assert.strictEqual(mutant.mutatedCode, 'mutated code')
      assert.strictEqual(mutant.operator, 'Test Operator')
      assert.strictEqual(mutant.mutation, 'Test mutation')
      assert.strictEqual(mutant.line, 10)
    })
  })

  describe('MutationResult class', () => {
    it('should create result with timestamp', () => {
      const mutant = new Mutant(1, 'test.js', 'orig', 'mut', 'op', 'mut', 1)
      const result = new MutationResult(mutant, true, 'output')

      assert.strictEqual(result.mutant, mutant)
      assert.strictEqual(result.killed, true)
      assert.strictEqual(result.testOutput, 'output')
      assert.ok(result.timestamp)
      assert.ok(Date.parse(result.timestamp))
    })
  })

  describe('MUTATION_OPERATORS', () => {
    it('should export mutation operators', () => {
      assert.ok(MUTATION_OPERATORS)
      assert.ok(MUTATION_OPERATORS.ARITHMETIC)
      assert.ok(MUTATION_OPERATORS.COMPARISON)
      assert.ok(MUTATION_OPERATORS.LOGICAL)
      assert.ok(MUTATION_OPERATORS.UNARY)
      assert.ok(MUTATION_OPERATORS.RETURN)
    })

    it('should have valid mutation structures', () => {
      Object.values(MUTATION_OPERATORS).forEach(operator => {
        assert.ok(operator.name)
        assert.ok(Array.isArray(operator.mutations))
        
        operator.mutations.forEach(mutation => {
          assert.ok(mutation.from !== undefined)
          assert.ok(mutation.to !== undefined)
          assert.ok(mutation.description)
        })
      })
    })
  })
})
