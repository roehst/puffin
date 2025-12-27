/**
 * Puffin Prolog Bridge
 * 
 * Node.js bridge for interfacing between the JavaScript frontend
 * and the Prolog backend via SWI-Prolog's swipl command.
 */

const { spawn } = require('child_process');
const path = require('path');

class PrologBridge {
  constructor() {
    this.prologPath = path.join(__dirname, 'prolog');
    this.prologModule = path.join(this.prologPath, 'puffin.pl');
  }

  /**
   * Execute a Prolog query and return the result
   * @param {string} query - Prolog query to execute
   * @returns {Promise<any>} Query result
   */
  async query(query) {
    return new Promise((resolve, reject) => {
      const swipl = spawn('swipl', [
        '-g', query,
        '-g', 'halt',
        '-t', 'halt(1)',
        this.prologModule
      ]);

      let stdout = '';
      let stderr = '';

      swipl.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      swipl.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      swipl.on('close', (code) => {
        if (code === 0) {
          resolve(this.parseOutput(stdout));
        } else {
          reject(new Error(`Prolog query failed: ${stderr}`));
        }
      });
    });
  }

  /**
   * Parse Prolog output to JavaScript object
   * @param {string} output - Raw output from Prolog
   * @returns {any} Parsed result
   */
  parseOutput(output) {
    try {
      // Simple parsing - just return the trimmed output
      // In a real implementation, you'd parse Prolog terms properly
      return output.trim();
    } catch (error) {
      return output;
    }
  }

  /**
   * Validate a project using Prolog
   * @param {Object} project - Project object to validate
   * @returns {Promise<{valid: boolean, errors: string[]}>}
   */
  async validateProject(project) {
    const projectDict = this.toDict(project);
    const query = `validate_project(${projectDict}, Result), write_canonical(Result), nl`;
    
    try {
      const result = await this.query(query);
      return this.parseValidationResult(result);
    } catch (error) {
      return { valid: false, errors: [error.message] };
    }
  }

  /**
   * Validate a prompt using Prolog
   * @param {Object} prompt - Prompt object to validate
   * @returns {Promise<{valid: boolean, errors: string[]}>}
   */
  async validatePrompt(prompt) {
    const promptDict = this.toDict(prompt);
    const query = `validate_prompt(${promptDict}, Result), write_canonical(Result), nl`;
    
    try {
      const result = await this.query(query);
      return this.parseValidationResult(result);
    } catch (error) {
      return { valid: false, errors: [error.message] };
    }
  }

  /**
   * Get Claude model information
   * @param {string} modelId - Model ID
   * @returns {Promise<Object>} Model information
   */
  async getModel(modelId) {
    const query = `claude_model(${modelId}, Name, Desc, Tier), format('~w|~w|~w~n', [Name, Desc, Tier])`;
    
    try {
      const result = await this.query(query);
      const [name, description, tier] = result.split('|');
      return {
        id: modelId,
        name: name.trim(),
        description: description.trim(),
        tier: tier.trim()
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * Get all available models
   * @returns {Promise<string[]>} Array of model IDs
   */
  async getAllModels() {
    const query = `all_models(Models), write_canonical(Models), nl`;
    
    try {
      const result = await this.query(query);
      // Parse list format [opus,sonnet,haiku]
      const match = result.match(/\[(.*?)\]/);
      if (match) {
        return match[1].split(',').map(m => m.trim());
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  /**
   * Generate a UUID
   * @returns {Promise<string>} Generated UUID
   */
  async generateId() {
    const query = `generate_id(Id), write(Id), nl`;
    
    try {
      const result = await this.query(query);
      return result.trim();
    } catch (error) {
      // Fallback to JavaScript UUID generation
      return this.fallbackGenerateId();
    }
  }

  /**
   * Fallback UUID generation in JavaScript
   * @returns {string} Generated UUID
   */
  fallbackGenerateId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * Convert JavaScript object to Prolog dict notation
   * @param {Object} obj - JavaScript object
   * @returns {string} Prolog dict notation
   */
  toDict(obj) {
    const pairs = Object.entries(obj).map(([key, value]) => {
      const prologKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
      let prologValue;
      
      if (typeof value === 'string') {
        prologValue = `'${value.replace(/'/g, "\\'")}'`;
      } else if (Array.isArray(value)) {
        prologValue = `[${value.map(v => typeof v === 'string' ? `'${v}'` : v).join(',')}]`;
      } else if (typeof value === 'object' && value !== null) {
        prologValue = this.toDict(value);
      } else {
        prologValue = value;
      }
      
      return `${prologKey}:${prologValue}`;
    });
    
    return `_{${pairs.join(',')}}`;
  }

  /**
   * Parse validation result from Prolog
   * @param {string} result - Raw Prolog result
   * @returns {{valid: boolean, errors: string[]}}
   */
  parseValidationResult(result) {
    if (result.includes('valid')) {
      return { valid: true, errors: [] };
    } else if (result.includes('invalid')) {
      // Extract error list
      const match = result.match(/\[(.*?)\]/);
      const errors = match ? match[1].split(',').map(e => e.trim().replace(/'/g, '')) : [];
      return { valid: false, errors };
    }
    return { valid: false, errors: ['Unknown validation result'] };
  }
}

// Export singleton instance
module.exports = new PrologBridge();
