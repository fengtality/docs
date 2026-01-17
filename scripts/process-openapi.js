#!/usr/bin/env node
/**
 * Process OpenAPI specs for Mintlify compatibility
 *
 * Converts anyOf patterns with null to nullable: true
 * This is required because Mintlify's OpenAPI validation doesn't
 * support the anyOf pattern with type: null
 */

const fs = require('fs');

if (process.argv.length < 3) {
  console.error('Usage: node process-openapi.js <input-file>');
  process.exit(1);
}

// Read the OpenAPI spec
const spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

// Function to convert anyOf with null to nullable
function convertAnyOfToNullable(obj) {
  if (!obj || typeof obj !== 'object') return obj;

  // If this is an array, process each item
  if (Array.isArray(obj)) {
    return obj.map(item => convertAnyOfToNullable(item));
  }

  // Check for anyOf pattern with null
  if (obj.anyOf && Array.isArray(obj.anyOf)) {
    const nonNullTypes = obj.anyOf.filter(t => t.type !== 'null');
    const hasNull = obj.anyOf.some(t => t.type === 'null');

    if (hasNull && nonNullTypes.length === 1) {
      // Convert to nullable: true format (OpenAPI 3.0 style)
      const newObj = { ...obj, ...nonNullTypes[0], nullable: true };
      delete newObj.anyOf;
      return convertAnyOfToNullable(newObj);
    }
  }

  // Process all properties recursively
  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    result[key] = convertAnyOfToNullable(value);
  }
  return result;
}

// Process the spec
const processedSpec = convertAnyOfToNullable(spec);

// Output the processed spec
console.log(JSON.stringify(processedSpec, null, 2));
