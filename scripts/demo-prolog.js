#!/usr/bin/env node

/**
 * Puffin Prolog Demo
 * 
 * Demonstrates the Prolog backend integration
 */

const prologBridge = require('../src/main/prolog-bridge');

console.log('\n🦜 Puffin Prolog Backend Demo\n');
console.log('==============================\n');

async function demo() {
  try {
    // Demo 1: Project Validation
    console.log('1️⃣  Project Validation');
    console.log('   -------------------');
    
    const validProject = {
      name: 'AI Assistant',
      description: 'An intelligent assistant powered by Claude',
      assumptions: ['Users have internet connection', 'API keys are configured']
    };
    
    console.log('   Testing valid project:', JSON.stringify(validProject, null, 2));
    const projectResult = await prologBridge.validateProject(validProject);
    console.log('   ✅ Result:', projectResult.valid ? 'VALID' : 'INVALID');
    if (!projectResult.valid) {
      console.log('   Errors:', projectResult.errors);
    }
    
    const invalidProject = { description: 'Missing name' };
    console.log('\n   Testing invalid project:', JSON.stringify(invalidProject, null, 2));
    const invalidResult = await prologBridge.validateProject(invalidProject);
    console.log('   ❌ Result:', invalidResult.valid ? 'VALID' : 'INVALID');
    console.log('   Errors:', invalidResult.errors);
    
    // Demo 2: Prompt Validation
    console.log('\n2️⃣  Prompt Validation');
    console.log('   ------------------');
    
    const validPrompt = {
      content: 'Implement user authentication with JWT tokens',
      branchId: 'backend'
    };
    
    console.log('   Testing valid prompt:', JSON.stringify(validPrompt, null, 2));
    const promptResult = await prologBridge.validatePrompt(validPrompt);
    console.log('   ✅ Result:', promptResult.valid ? 'VALID' : 'INVALID');
    
    // Demo 3: Claude Models
    console.log('\n3️⃣  Claude Models');
    console.log('   ---------------');
    
    const models = await prologBridge.getAllModels();
    console.log('   Available models:', models.join(', '));
    
    for (const modelId of models) {
      const model = await prologBridge.getModel(modelId);
      if (model) {
        console.log(`   • ${model.name} (${model.tier}): ${model.description}`);
      }
    }
    
    // Demo 4: UUID Generation
    console.log('\n4️⃣  UUID Generation');
    console.log('   ----------------');
    
    const id1 = await prologBridge.generateId();
    const id2 = await prologBridge.generateId();
    const id3 = await prologBridge.generateId();
    
    console.log('   Generated UUIDs:');
    console.log('   •', id1);
    console.log('   •', id2);
    console.log('   •', id3);
    
    // Summary
    console.log('\n✨ Summary');
    console.log('   --------');
    console.log('   The Prolog backend successfully provides:');
    console.log('   ✓ Declarative validation rules');
    console.log('   ✓ Model definitions and queries');
    console.log('   ✓ Utility functions (UUID generation)');
    console.log('   ✓ Seamless JavaScript integration');
    
    console.log('\n🎉 Demo completed successfully!\n');
    
  } catch (error) {
    console.error('\n❌ Demo failed:', error.message);
    if (!error.message.includes('spawn')) {
      console.error('   Make sure SWI-Prolog is installed: apt-get install swi-prolog\n');
    }
    process.exit(1);
  }
}

demo();
