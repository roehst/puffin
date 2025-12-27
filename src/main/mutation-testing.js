/**
 * Puffin - Mutation Testing Service
 *
 * Provides mutation testing capabilities for code quality assessment.
 * Inserts mutations (bugs) into code, runs tests, and counts killings.
 *
 * Mutation testing helps assess test suite effectiveness by:
 * 1. Creating mutants (modified versions of code with injected bugs)
 * 2. Running tests against each mutant
 * 3. Tracking which mutants are "killed" (detected) by tests
 * 4. Reporting mutation score (killed/total)
 */

const fs = require('fs').promises
const path = require('path')
const { spawn } = require('child_process')

/**
 * Mutation operators for different code patterns
 * Each operator defines how to mutate code
 */
const MUTATION_OPERATORS = {
  // Arithmetic operators
  ARITHMETIC: {
    name: 'Arithmetic Operator Replacement',
    mutations: [
      { from: '+', to: '-', description: 'Replace addition with subtraction' },
      { from: '-', to: '+', description: 'Replace subtraction with addition' },
      { from: '*', to: '/', description: 'Replace multiplication with division' },
      { from: '/', to: '*', description: 'Replace division with multiplication' },
      { from: '%', to: '*', description: 'Replace modulo with multiplication' }
    ]
  },

  // Comparison operators
  COMPARISON: {
    name: 'Comparison Operator Replacement',
    mutations: [
      { from: '===', to: '!==', description: 'Replace equals with not equals' },
      { from: '!==', to: '===', description: 'Replace not equals with equals' },
      { from: '<', to: '<=', description: 'Replace less than with less than or equal' },
      { from: '<=', to: '<', description: 'Replace less than or equal with less than' },
      { from: '>', to: '>=', description: 'Replace greater than with greater than or equal' },
      { from: '>=', to: '>', description: 'Replace greater than or equal with greater than' },
      { from: '==', to: '!=', description: 'Replace loose equals with not equals' },
      { from: '!=', to: '==', description: 'Replace loose not equals with equals' }
    ]
  },

  // Logical operators
  LOGICAL: {
    name: 'Logical Operator Replacement',
    mutations: [
      { from: '&&', to: '||', description: 'Replace AND with OR' },
      { from: '||', to: '&&', description: 'Replace OR with AND' }
    ]
  },

  // Unary operators
  UNARY: {
    name: 'Unary Operator Replacement',
    mutations: [
      { from: '++', to: '--', description: 'Replace increment with decrement' },
      { from: '--', to: '++', description: 'Replace decrement with increment' }
    ]
  },

  // Return value mutations
  RETURN: {
    name: 'Return Value Mutation',
    mutations: [
      { from: /return true/g, to: 'return false', description: 'Replace return true with false' },
      { from: /return false/g, to: 'return true', description: 'Replace return false with true' },
      { from: /return 0/g, to: 'return 1', description: 'Replace return 0 with 1' },
      { from: /return 1/g, to: 'return 0', description: 'Replace return 1 with 0' }
    ]
  }
}

/**
 * Result of a mutation test run
 */
class MutationResult {
  constructor(mutant, killed, testOutput) {
    this.mutant = mutant
    this.killed = killed
    this.testOutput = testOutput
    this.timestamp = new Date().toISOString()
  }
}

/**
 * Represents a single mutant (mutated code)
 */
class Mutant {
  constructor(id, filePath, originalCode, mutatedCode, operator, mutation, line) {
    this.id = id
    this.filePath = filePath
    this.originalCode = originalCode
    this.mutatedCode = mutatedCode
    this.operator = operator
    this.mutation = mutation
    this.line = line
  }
}

class MutationTestingService {
  constructor() {
    this.projectPath = null
    this.mutants = []
    this.results = []
  }

  /**
   * Set the project path for mutation testing
   * @param {string} projectPath - Path to the project directory
   */
  setProjectPath(projectPath) {
    this.projectPath = projectPath
  }

  /**
   * Generate mutants for a given file
   * @param {string} filePath - Path to the file to mutate
   * @param {string[]} operators - Array of operator names to apply (default: all)
   * @returns {Promise<Mutant[]>} Array of generated mutants
   */
  async generateMutants(filePath, operators = null) {
    try {
      // Read the original file
      const absolutePath = path.isAbsolute(filePath) ? filePath : path.join(this.projectPath, filePath)
      const originalCode = await fs.readFile(absolutePath, 'utf-8')
      const lines = originalCode.split('\n')

      const mutants = []
      let mutantId = 0

      // Determine which operators to use
      const operatorsToUse = operators
        ? operators.map(op => MUTATION_OPERATORS[op]).filter(Boolean)
        : Object.values(MUTATION_OPERATORS)

      // Apply each mutation operator
      for (const operator of operatorsToUse) {
        for (const mutation of operator.mutations) {
          // Find all occurrences of the pattern
          const occurrences = this.findOccurrences(originalCode, mutation.from)

          for (const occurrence of occurrences) {
            // Create a mutant for each occurrence
            const mutatedCode = this.applyMutation(originalCode, mutation, occurrence)
            
            if (mutatedCode !== originalCode) {
              const lineNumber = this.getLineNumber(originalCode, occurrence.index)
              
              mutants.push(new Mutant(
                mutantId++,
                filePath,
                originalCode,
                mutatedCode,
                operator.name,
                mutation.description,
                lineNumber
              ))
            }
          }
        }
      }

      this.mutants = mutants
      return mutants
    } catch (error) {
      throw new Error(`Failed to generate mutants: ${error.message}`)
    }
  }

  /**
   * Find all occurrences of a pattern in code
   * @param {string} code - The source code
   * @param {string|RegExp} pattern - Pattern to search for
   * @returns {Array} Array of occurrence objects with index and match
   * @private
   */
  findOccurrences(code, pattern) {
    const occurrences = []

    if (pattern instanceof RegExp) {
      let match
      const regex = new RegExp(pattern.source, 'g')
      while ((match = regex.exec(code)) !== null) {
        occurrences.push({ index: match.index, match: match[0] })
      }
    } else {
      let index = code.indexOf(pattern)
      while (index !== -1) {
        occurrences.push({ index, match: pattern })
        index = code.indexOf(pattern, index + 1)
      }
    }

    return occurrences
  }

  /**
   * Apply a mutation to code at a specific occurrence
   * @param {string} code - Original code
   * @param {Object} mutation - Mutation to apply
   * @param {Object} occurrence - Occurrence information
   * @returns {string} Mutated code
   * @private
   */
  applyMutation(code, mutation, occurrence) {
    const before = code.substring(0, occurrence.index)
    const after = code.substring(occurrence.index + occurrence.match.length)
    const replacement = typeof mutation.to === 'string' ? mutation.to : mutation.to
    
    return before + replacement + after
  }

  /**
   * Get line number for a character index in code
   * @param {string} code - The source code
   * @param {number} index - Character index
   * @returns {number} Line number (1-based)
   * @private
   */
  getLineNumber(code, index) {
    const beforeIndex = code.substring(0, index)
    return beforeIndex.split('\n').length
  }

  /**
   * Run tests against a mutant
   * @param {Mutant} mutant - The mutant to test
   * @param {string} testCommand - Command to run tests (default: 'npm test')
   * @returns {Promise<MutationResult>} Result of the mutation test
   */
  async testMutant(mutant, testCommand = 'npm test') {
    const absolutePath = path.isAbsolute(mutant.filePath)
      ? mutant.filePath
      : path.join(this.projectPath, mutant.filePath)

    try {
      // Save original code
      const originalCode = await fs.readFile(absolutePath, 'utf-8')

      // Write mutated code
      await fs.writeFile(absolutePath, mutant.mutatedCode, 'utf-8')

      // Run tests
      const testResult = await this.runTests(testCommand)

      // Restore original code
      await fs.writeFile(absolutePath, originalCode, 'utf-8')

      // Mutant is killed if tests fail (exit code !== 0)
      const killed = testResult.exitCode !== 0
      const result = new MutationResult(mutant, killed, testResult.output)

      this.results.push(result)
      return result
    } catch (error) {
      // Restore original code in case of error
      try {
        const originalCode = mutant.originalCode
        await fs.writeFile(absolutePath, originalCode, 'utf-8')
      } catch (restoreError) {
        // Ignore restore errors
      }

      throw new Error(`Failed to test mutant: ${error.message}`)
    }
  }

  /**
   * Run test command
   * @param {string} command - Test command to run
   * @returns {Promise<{exitCode: number, output: string}>}
   * @private
   */
  async runTests(command) {
    return new Promise((resolve, reject) => {
      const [cmd, ...args] = command.split(' ')
      const testProcess = spawn(cmd, args, {
        cwd: this.projectPath,
        shell: true
      })

      let output = ''

      testProcess.stdout.on('data', (data) => {
        output += data.toString()
      })

      testProcess.stderr.on('data', (data) => {
        output += data.toString()
      })

      testProcess.on('close', (code) => {
        resolve({ exitCode: code, output })
      })

      testProcess.on('error', (error) => {
        reject(error)
      })
    })
  }

  /**
   * Run mutation testing on all generated mutants
   * @param {string} testCommand - Command to run tests
   * @returns {Promise<Object>} Mutation testing report
   */
  async runMutationTesting(testCommand = 'npm test') {
    if (this.mutants.length === 0) {
      throw new Error('No mutants generated. Call generateMutants() first.')
    }

    this.results = []
    const startTime = Date.now()

    for (const mutant of this.mutants) {
      try {
        await this.testMutant(mutant, testCommand)
      } catch (error) {
        console.error(`Error testing mutant ${mutant.id}:`, error.message)
      }
    }

    const endTime = Date.now()
    const duration = endTime - startTime

    return this.generateReport(duration)
  }

  /**
   * Generate mutation testing report
   * @param {number} duration - Duration in milliseconds
   * @returns {Object} Report object
   */
  generateReport(duration) {
    const totalMutants = this.results.length
    const killedMutants = this.results.filter(r => r.killed).length
    const survivedMutants = totalMutants - killedMutants
    const mutationScore = totalMutants > 0 ? (killedMutants / totalMutants) * 100 : 0

    return {
      summary: {
        totalMutants,
        killedMutants,
        survivedMutants,
        mutationScore: mutationScore.toFixed(2),
        duration
      },
      results: this.results.map(r => ({
        mutantId: r.mutant.id,
        filePath: r.mutant.filePath,
        line: r.mutant.line,
        operator: r.mutant.operator,
        mutation: r.mutant.mutation,
        killed: r.killed,
        timestamp: r.timestamp
      })),
      survivedMutants: this.results
        .filter(r => !r.killed)
        .map(r => ({
          mutantId: r.mutant.id,
          filePath: r.mutant.filePath,
          line: r.mutant.line,
          operator: r.mutant.operator,
          mutation: r.mutant.mutation
        }))
    }
  }

  /**
   * Get all available mutation operators
   * @returns {Object} Mutation operators
   */
  getAvailableOperators() {
    return Object.keys(MUTATION_OPERATORS).reduce((acc, key) => {
      acc[key] = {
        name: MUTATION_OPERATORS[key].name,
        mutationCount: MUTATION_OPERATORS[key].mutations.length
      }
      return acc
    }, {})
  }

  /**
   * Reset mutation testing state
   */
  reset() {
    this.mutants = []
    this.results = []
  }
}

module.exports = { MutationTestingService, Mutant, MutationResult, MUTATION_OPERATORS }
