const express = require('express');
const router = express.Router();

// 테스트 로그 저장소 (메모리 내 - 실제 구현 시 DB 사용 권장)
let testLogs = [];

// 테스트 결과 저장 API
router.post('/logs', (req, res) => {
  const { testId, logs, timestamp, status } = req.body;
  
  const logEntry = {
    id: testLogs.length + 1,
    testId,
    logs,
    timestamp: timestamp || new Date().toISOString(),
    status: status || 'completed'
  };
  
  testLogs.push(logEntry);
  
  res.json({
    success: true,
    message: 'Test logs saved successfully',
    data: logEntry
  });
});

// 테스트 로그 조회 API
router.get('/logs/:testId', (req, res) => {
  const { testId } = req.params;
  const logs = testLogs.filter(log => log.testId === testId);
  
  if (logs.length === 0) {
    return res.status(404).json({
      success: false,
      message: 'No logs found for this test'
    });
  }
  
  res.json({
    success: true,
    data: logs
  });
});

// 모든 테스트 로그 조회 API
router.get('/logs', (req, res) => {
  res.json({
    success: true,
    data: testLogs
  });
});
// 테스트 로그 삭제 API
router.delete('/logs/:testId', (req, res) => {
  const { testId } = req.params;
  testLogs = testLogs.filter(log => log.testId !== testId);
  
  res.json({
    success: true,
    message: 'Test logs deleted successfully'
  });
});

module.exports = router;