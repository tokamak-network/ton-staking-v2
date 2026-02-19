import { useState } from 'react';

interface LogEntry {
  time: string;
  message: string;
}

export default function GameLogPanel() {
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const addLog = (message: string) => {
    const time = new Date().toLocaleTimeString();
    setLogs((prev) => [{ time, message }, ...prev]);
  };

  // 컴포넌트에서 사용할 수 있도록
  // 실제로는 부모 컴포넌트에서 로그를 전달받아야 함
  // 여기서는 예시로 정적 로그를 보여줌

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">📜 게임 로그</h2>
      
      <div className="bg-gray-50 rounded-lg p-4 h-64 overflow-y-auto">
        {logs.length === 0 ? (
          <p className="text-gray-500 text-center py-8">
            아직 로그가 없습니다.
          </p>
        ) : (
          <div className="space-y-2">
            {logs.map((log, i) => (
              <div key={i} className="text-sm">
                <span className="text-gray-500">[{log.time}]</span>
                <span className="ml-2">{log.message}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
