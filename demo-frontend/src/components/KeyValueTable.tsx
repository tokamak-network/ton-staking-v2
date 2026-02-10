interface KeyValueTableProps {
  entries: Array<{ key: string; value: string }>;
}

export const KeyValueTable = ({ entries }: KeyValueTableProps) => {
  return (
    <table className="table">
      <tbody>
        {entries.map((entry) => (
          <tr key={entry.key}>
            <td>{entry.key}</td>
            <td>{entry.value}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
