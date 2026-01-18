#!/usr/bin/env node
/**
 * Process OpenAPI specs for Mintlify compatibility
 *
 * 1. Converts anyOf patterns with null to nullable: true
 *    This is required because Mintlify's OpenAPI validation doesn't
 *    support the anyOf pattern with type: null
 *
 * 2. Adds operationIds and summaries to endpoints that don't have them
 *    This ensures clean URL paths and titles in Mintlify
 */

const fs = require('fs');

if (process.argv.length < 3) {
  console.error('Usage: node process-openapi.js <input-file>');
  process.exit(1);
}

// Read the OpenAPI spec
const spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

// Function to convert path segment to title case
function toTitleCase(str) {
  return str
    .replace(/-/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

// Function to generate a clean operationId from path
function generateOperationId(path, method, tag) {
  const cleanPath = path.replace(/^\/|\/$/g, '');
  const parts = cleanPath ? cleanPath.split('/') : [];
  const tagName = tag ? tag.replace(/^\//, '').split('/')[0] : '';

  let relevantParts = parts;
  if (tagName && parts[0] === tagName) {
    relevantParts = parts.slice(1);
  }

  relevantParts = relevantParts.filter(p => p.length > 0);

  if (relevantParts.length === 0) {
    if (method === 'get') {
      relevantParts = ['list'];
    } else {
      relevantParts = [tagName || 'root'];
    }
  }

  const operationId = relevantParts
    .join('_')
    .replace(/-/g, '_')
    .replace(/[{}]/g, '')
    .toLowerCase();

  return operationId;
}

// Normalize a segment for comparison (handle plural/singular)
function normalizeSegment(seg) {
  seg = seg.toLowerCase();
  // Remove trailing 's' for comparison (chains->chain, connectors->connector)
  if (seg.endsWith('s') && seg.length > 1) {
    return seg.slice(0, -1);
  }
  return seg;
}

// Check if two segments match (accounting for plural/singular)
function segmentsMatch(pathSeg, tagSeg) {
  return normalizeSegment(pathSeg) === normalizeSegment(tagSeg);
}

// Function to generate a summary from path
function generateSummary(path, method, tag) {
  const cleanPath = path.replace(/^\/|\/$/g, '');
  const pathParts = cleanPath ? cleanPath.split('/') : [];

  // Parse full tag path (e.g., "/connector/meteora" -> ["connector", "meteora"])
  const tagParts = tag ? tag.replace(/^\/|\/$/g, '').split('/').filter(p => p.length > 0) : [];

  // Remove path segments that match tag segments (in order)
  let relevantParts = [...pathParts];
  let tagIndex = 0;

  while (tagIndex < tagParts.length && relevantParts.length > 0) {
    if (segmentsMatch(relevantParts[0], tagParts[tagIndex])) {
      relevantParts.shift();
      tagIndex++;
    } else {
      break;
    }
  }

  // Filter out path parameters, empty segments, and protocol types
  const protocolTypes = ['clmm', 'amm', 'router'];
  relevantParts = relevantParts.filter(p =>
    p.length > 0 &&
    !p.startsWith('{') &&
    !protocolTypes.includes(p.toLowerCase())
  );

  // Get last tag segment for default naming
  const lastTagSegment = tagParts.length > 0 ? tagParts[tagParts.length - 1] : '';

  if (relevantParts.length === 0) {
    if (method === 'get') {
      return `List`;
    } else if (method === 'post') {
      return `Create`;
    } else if (method === 'delete') {
      return `Delete`;
    } else if (method === 'put' || method === 'patch') {
      return `Update`;
    }
    return toTitleCase(lastTagSegment);
  }

  return relevantParts.map(toTitleCase).join(' ');
}

// Function to add operationIds and summaries to all endpoints
function addOperationIds(spec) {
  if (!spec.paths) return spec;

  const usedIds = new Set();

  for (const [path, pathItem] of Object.entries(spec.paths)) {
    for (const method of ['get', 'post', 'put', 'delete', 'patch']) {
      if (pathItem[method]) {
        const operation = pathItem[method];
        const tag = operation.tags?.[0] || '';

        if (!operation.summary) {
          operation.summary = generateSummary(path, method, tag);
        }

        if (operation.operationId) {
          usedIds.add(operation.operationId);
          continue;
        }

        let operationId = generateOperationId(path, method, tag);
        let uniqueId = operationId;
        let counter = 1;
        while (usedIds.has(uniqueId)) {
          uniqueId = `${operationId}_${method}`;
          if (usedIds.has(uniqueId)) {
            uniqueId = `${operationId}_${counter}`;
            counter++;
          }
        }

        operation.operationId = uniqueId;
        usedIds.add(uniqueId);
      }
    }
  }

  return spec;
}

// Function to convert anyOf with null to nullable
function convertAnyOfToNullable(obj) {
  if (!obj || typeof obj !== 'object') return obj;

  if (Array.isArray(obj)) {
    return obj.map(item => convertAnyOfToNullable(item));
  }

  if (obj.anyOf && Array.isArray(obj.anyOf)) {
    const nonNullTypes = obj.anyOf.filter(t => t.type !== 'null');
    const hasNull = obj.anyOf.some(t => t.type === 'null');

    if (hasNull && nonNullTypes.length === 1) {
      const newObj = { ...obj, ...nonNullTypes[0], nullable: true };
      delete newObj.anyOf;
      return convertAnyOfToNullable(newObj);
    }
  }

  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    result[key] = convertAnyOfToNullable(value);
  }
  return result;
}

// Process the spec
let processedSpec = addOperationIds(spec);
processedSpec = convertAnyOfToNullable(processedSpec);

// Output the processed spec
console.log(JSON.stringify(processedSpec, null, 2));
