export const formatDateTime = (value?: string) => {
  if (!value) return "-";
  const date = new Date(value);
  return date.toLocaleString();
};

export const formatDuration = (start?: string, end?: string) => {
  if (!start) return "-";
  const s = new Date(start).getTime();
  const e = end ? new Date(end).getTime() : Date.now();
  const diff = Math.max(0, e - s);
  const seconds = Math.floor(diff / 1000);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}m ${secs}s`;
};

export const extractMarkers = (logs: string[]) => {
  return logs
    .filter((line) => line.includes("[DEMO_STEP]"))
    .map((line) => line.replace("[DEMO_STEP]", "").trim());
};
