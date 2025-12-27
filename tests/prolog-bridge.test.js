/**
 * Integration tests for Prolog Bridge
 * 
 * Tests the JavaScript <-> Prolog integration
 */

const { describe, it } = require('node:test');
const assert = require('node:assert');
const prologBridge = require('../src/main/prolog-bridge');
const { execSync } = require('child_process');

// Check if SWI-Prolog is installed
function isPrologInstalled() {
  try {
    execSync('swipl --version', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

describe('Prolog Bridge Integration', { skip: !isPrologInstalled() }, () => {
  describe('validateProject', () => {
    it('should validate a valid project', async () => {
      const project = {
        name: 'Test Project',
        description: 'A test project for validation',
        assumptions: []
      };
      
      const result = await prologBridge.validateProject(project);
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.errors.length, 0);
    });

    it('should reject project without name', async () => {
      const project = {
        description: 'A test project without name'
      };
      
      const result = await prologBridge.validateProject(project);
      assert.strictEqual(result.valid, false);
      assert.ok(result.errors.length > 0);
    });

    it('should reject project without description', async () => {
      const project = {
        name: 'Test Project'
      };
      
      const result = await prologBridge.validateProject(project);
      assert.strictEqual(result.valid, false);
      assert.ok(result.errors.length > 0);
    });
  });

  describe('validatePrompt', () => {
    it('should validate a valid prompt', async () => {
      const prompt = {
        content: 'This is a test prompt',
        branchId: 'specifications'
      };
      
      const result = await prologBridge.validatePrompt(prompt);
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.errors.length, 0);
    });

    it('should reject prompt without content', async () => {
      const prompt = {
        branchId: 'specifications'
      };
      
      const result = await prologBridge.validatePrompt(prompt);
      assert.strictEqual(result.valid, false);
      assert.ok(result.errors.length > 0);
    });
  });

  describe('getModel', () => {
    it('should retrieve opus model', async () => {
      const model = await prologBridge.getModel('opus');
      
      assert.ok(model);
      assert.strictEqual(model.id, 'opus');
      assert.ok(model.name);
      assert.ok(model.description);
      assert.ok(model.tier);
    });

    it('should retrieve sonnet model', async () => {
      const model = await prologBridge.getModel('sonnet');
      
      assert.ok(model);
      assert.strictEqual(model.id, 'sonnet');
    });
  });

  describe('getAllModels', () => {
    it('should return all available models', async () => {
      const models = await prologBridge.getAllModels();
      
      assert.ok(Array.isArray(models));
      assert.ok(models.length >= 3);
      assert.ok(models.includes('opus'));
      assert.ok(models.includes('sonnet'));
      assert.ok(models.includes('haiku'));
    });
  });

  describe('generateId', () => {
    it('should generate a UUID', async () => {
      const id = await prologBridge.generateId();
      
      assert.ok(id);
      assert.ok(typeof id === 'string');
      assert.ok(id.length > 0);
      // UUID format check (basic)
      assert.ok(id.includes('-'));
    });

    it('should generate unique IDs', async () => {
      const id1 = await prologBridge.generateId();
      const id2 = await prologBridge.generateId();
      
      assert.notStrictEqual(id1, id2);
    });
  });
});

// Skip message if Prolog is not installed
if (!isPrologInstalled()) {
  console.log('\n⚠️  SWI-Prolog not installed. Skipping Prolog integration tests.');
  console.log('   Install with: apt-get install swi-prolog\n');
}
