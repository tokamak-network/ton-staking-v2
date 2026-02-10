interface StatusBadgeProps {
  status?: string;
}

export const StatusBadge = ({ status }: StatusBadgeProps) => {
  if (!status) return null;
  return <span className={`badge ${status}`}>{status.toUpperCase()}</span>;
};
