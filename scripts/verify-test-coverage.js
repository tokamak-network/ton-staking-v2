#!/usr/bin/env node

/**
 * Test Coverage Verification Script
 * 
 * 이 스크립트는 docs/specs-kr/10-v3-test-plan.md의 테스트 ID와
 * 실제 test/v3/ 디렉토리의 테스트 함수들을 매칭하여 검증합니다.
 */

const fs = require('fs');
const path = require('path');

// 색상 코드
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  gray: '\x1b[90m'
};

// 테스트 ID 패턴
const TEST_ID_PATTERN = /^\|\s+(SM|RAT|VR|SD|INT|E2E|EDGE|SEC)-(\d+)\s+\|/gm;
const TEST_FUNCTION_PATTERN = /function\s+(test\w+)\s*\(/g;

/**
 * 테스트 계획 문서에서 테스트 ID 추출
 */
function extractTestIDsFromDocs() {
  const docPath = path.join(__dirname, '..', 'docs', 'specs-kr', '10-v3-test-plan.md');
  const content = fs.readFileSync(docPath, 'utf-8');
  
  const testIDs = new Map();
  const lines = content.split('\n');
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const match = /^\|\s+(SM|RAT|VR|SD|INT|E2E|EDGE|SEC)-(\d+)\s+\|\s+(.+?)\s+\|\s+(.+?)\s+\|\s+(.+?)\s+\|/.exec(line);
    
    if (match) {
      const [, prefix, num, name, description, status] = match;
      const testID = `${prefix}-${num.padStart(3, '0')}`;
      
      testIDs.set(testID, {
        id: testID,
        prefix,
        num: num.padStart(3, '0'),
        name: name.trim(),
        description: description.trim(),
        status: status.trim(),
        found: false,
        matchedFunctions: []
      });
    }
  }
  
  return testIDs;
}

/**
 * 테스트 파일에서 테스트 함수 추출
 */
function extractTestFunctions() {
  const testDir = path.join(__dirname, '..', 'test', 'v3');
  const files = fs.readdirSync(testDir).filter(f => f.endsWith('.sol'));
  
  const functions = [];
  
  for (const file of files) {
    const filePath = path.join(testDir, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    
    // 함수명 추출
    const matches = [...content.matchAll(/function\s+(test\w+)\s*\(/g)];
    
    for (const match of matches) {
      const funcName = match[1];
      functions.push({
        file,
        name: funcName,
        matched: false
      });
    }
  }
  
  return functions;
}

/**
 * 테스트 ID와 함수명 매칭
 */
function matchTestIDsWithFunctions(testIDs, functions) {
  for (const [id, testInfo] of testIDs) {
    const { prefix, num, name, description } = testInfo;
    
    const patterns = [
      new RegExp(`test_${prefix}${num}_`, 'i'),
      new RegExp(`test_${prefix}-${num}_`, 'i'),
      new RegExp(`test_${prefix}${num}[^0-9]`, 'i'),
      new RegExp(`testFuzz_${prefix}${num}_`, 'i'),
      new RegExp(`testFuzz_${prefix}-${num}_`, 'i'),
    ];
    
    for (const func of functions) {
      for (const pattern of patterns) {
        if (pattern.test(func.name)) {
          testInfo.found = true;
          testInfo.matchedFunctions.push(func.name);
          func.matched = true;
        }
      }
    }
    
    if (!testInfo.found) {
      const keywords = extractKeywords(name + ' ' + description);
      for (const func of functions) {
        if (!func.matched && semanticMatch(func.name, keywords, prefix)) {
          testInfo.found = true;
          testInfo.matchedFunctions.push(func.name + ' (semantic)');
          func.matched = true;
        }
      }
    }
  }
  
  return { testIDs, functions };
}

function extractKeywords(text) {
  const normalized = text.toLowerCase()
    .replace(/[`()]/g, '')
    .replace(/[×·]/g, ' ')
    .replace(/→/g, ' ');
  
  return normalized.split(/\s+/).filter(w => w.length > 2);
}

function semanticMatch(funcName, keywords, prefix) {
  const funcLower = funcName.toLowerCase();
  
  const specificMappings = {
    'hyperbolic': ['hyperbolic', 'saturation'],
    'sequencer': ['sequencer', 'reward', 'calculate'],
    'validator': ['validator', 'register', 'deactivate'],
    'rat': ['attention', 'test', 'trigger'],
    'evidence': ['evidence', 'submit'],
    'claim': ['claim', 'resolve'],
    'slashing': ['slash', 'treasury', 'withdraw'],
    'coinage': ['coinage', 'transfer'],
    'deposit': ['deposit', 'stake'],
    'withdraw': ['withdraw', 'request'],
    'migration': ['migrat', 'v3'],
  };
  
  for (const [key, terms] of Object.entries(specificMappings)) {
    const hasAllTerms = terms.every(term => funcLower.includes(term));
    const hasAnyKeyword = keywords.some(kw => funcLower.includes(kw));
    if (hasAllTerms && hasAnyKeyword) {
      return true;
    }
  }
  
  const matchCount = keywords.filter(kw => funcLower.includes(kw)).length;
  return matchCount >= Math.min(3, keywords.length);
}

/**
 * 결과 출력
 */
function printResults(testIDs, functions) {
  console.log('\n' + '='.repeat(80));
  console.log('📊 Test Coverage Verification Report');
  console.log('='.repeat(80) + '\n');
  
  // 통계
  const totalTests = testIDs.size;
  const foundTests = [...testIDs.values()].filter(t => t.found).length;
  const totalFunctions = functions.length;
  const matchedFunctions = functions.filter(f => f.matched).length;
  const unmatchedFunctions = functions.filter(f => !f.matched).length;
  
  console.log(`${colors.blue}📋 Summary:${colors.reset}`);
  console.log(`  Total Test IDs in docs: ${totalTests}`);
  console.log(`  Test IDs with matching functions: ${colors.green}${foundTests}${colors.reset}`);
  console.log(`  Test IDs without matches: ${colors.red}${totalTests - foundTests}${colors.reset}`);
  console.log(`  Total test functions: ${totalFunctions}`);
  console.log(`  Matched functions: ${colors.green}${matchedFunctions}${colors.reset}`);
  console.log(`  Unmatched functions: ${colors.yellow}${unmatchedFunctions}${colors.reset}`);
  console.log(`  Coverage: ${colors.blue}${((foundTests / totalTests) * 100).toFixed(1)}%${colors.reset}\n`);
  
  // 상태별 분류
  const byStatus = {
    '✅': [],
    '⚠️': [],
    '❌': [],
    'N/A': []
  };
  
  for (const testInfo of testIDs.values()) {
    const status = testInfo.status.split(' ')[0]; // "✅", "⚠️", "❌", "N/A"
    if (byStatus[status]) {
      byStatus[status].push(testInfo);
    }
  }
  
  console.log(`${colors.blue}📊 By Status:${colors.reset}`);
  console.log(`  ✅ Completed: ${byStatus['✅'].length}`);
  console.log(`  ⚠️  Partial: ${byStatus['⚠️'].length}`);
  console.log(`  ❌ Not Implemented: ${byStatus['❌'].length}`);
  console.log(`  N/A: ${byStatus['N/A'].length}\n`);
  
  // 문서에는 있지만 코드에 없는 테스트
  const missingTests = [...testIDs.values()].filter(t => !t.found && t.status.startsWith('✅'));
  if (missingTests.length > 0) {
    console.log(`${colors.red}⚠️  Tests marked as ✅ but missing in code:${colors.reset}`);
    for (const test of missingTests) {
      console.log(`  ${colors.red}✗${colors.reset} ${test.id}: ${test.name}`);
    }
    console.log();
  }
  
  // 코드에는 있지만 문서에 매칭되지 않는 함수 (처음 20개만)
  const unmatchedFuncs = functions.filter(f => !f.matched).slice(0, 20);
  if (unmatchedFuncs.length > 0) {
    console.log(`${colors.yellow}📝 Test functions not matched to any Test ID (showing first 20):${colors.reset}`);
    for (const func of unmatchedFuncs) {
      console.log(`  ${colors.gray}•${colors.reset} ${func.name} ${colors.gray}(${func.file})${colors.reset}`);
    }
    if (unmatchedFunctions > 20) {
      console.log(`  ${colors.gray}... and ${unmatchedFunctions - 20} more${colors.reset}`);
    }
    console.log();
  }
  
  // 카테고리별 통계
  console.log(`${colors.blue}📂 By Category:${colors.reset}`);
  const categories = ['SM', 'RAT', 'VR', 'SD', 'INT', 'E2E', 'EDGE', 'SEC'];
  for (const cat of categories) {
    const catTests = [...testIDs.values()].filter(t => t.prefix === cat);
    const catFound = catTests.filter(t => t.found).length;
    const percentage = catTests.length > 0 ? ((catFound / catTests.length) * 100).toFixed(0) : 0;
    const bar = '█'.repeat(Math.floor(percentage / 5)) + '░'.repeat(20 - Math.floor(percentage / 5));
    console.log(`  ${cat.padEnd(6)}: ${bar} ${catFound}/${catTests.length} (${percentage}%)`);
  }
  
  console.log('\n' + '='.repeat(80) + '\n');
}

/**
 * JSON 리포트 생성
 */
function generateJSONReport(testIDs, functions) {
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalTestIDs: testIDs.size,
      foundTestIDs: [...testIDs.values()].filter(t => t.found).length,
      totalFunctions: functions.length,
      matchedFunctions: functions.filter(f => f.matched).length,
      coverage: (([...testIDs.values()].filter(t => t.found).length / testIDs.size) * 100).toFixed(2) + '%'
    },
    testIDs: Object.fromEntries(testIDs),
    unmatchedFunctions: functions.filter(f => !f.matched).map(f => ({ file: f.file, name: f.name }))
  };
  
  const outputPath = path.join(__dirname, '..', 'test-coverage-report.json');
  fs.writeFileSync(outputPath, JSON.stringify(report, null, 2));
  console.log(`${colors.green}✓${colors.reset} JSON report saved to: ${colors.gray}${outputPath}${colors.reset}\n`);
}

/**
 * 메인 실행
 */
function main() {
  console.log(`${colors.blue}🔍 Extracting test IDs from documentation...${colors.reset}`);
  const testIDs = extractTestIDsFromDocs();
  console.log(`${colors.green}✓${colors.reset} Found ${testIDs.size} test IDs\n`);
  
  console.log(`${colors.blue}🔍 Extracting test functions from code...${colors.reset}`);
  const functions = extractTestFunctions();
  console.log(`${colors.green}✓${colors.reset} Found ${functions.length} test functions\n`);
  
  console.log(`${colors.blue}🔗 Matching test IDs with functions...${colors.reset}`);
  const result = matchTestIDsWithFunctions(testIDs, functions);
  
  printResults(result.testIDs, result.functions);
  generateJSONReport(result.testIDs, result.functions);
}

main();
