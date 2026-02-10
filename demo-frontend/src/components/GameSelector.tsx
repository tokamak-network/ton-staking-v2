interface GameSelectorProps {
  games: string[];
  selectedGame?: string;
  onSelect: (game: string) => void;
}

export const GameSelector = ({ games, selectedGame, onSelect }: GameSelectorProps) => {
  return (
    <div>
      <h3>Dispute Game Selector</h3>
      {games.length === 0 ? (
        <p style={{ color: "#8ea0bf" }}>No games created yet.</p>
      ) : (
        <select
          value={selectedGame ?? ""}
          onChange={(event) => onSelect(event.target.value)}
          style={{ width: "100%", padding: "10px", borderRadius: "8px" }}
        >
          {games.map((game) => (
            <option key={game} value={game}>
              {game}
            </option>
          ))}
        </select>
      )}
    </div>
  );
};
