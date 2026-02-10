const steps = [
  { key: "PREPARE", label: "Prepare Devnet" },
  { key: "GAME_CREATED", label: "Dispute Game Created" },
  { key: "CHALLENGERS_STARTED", label: "Challengers Started" },
  { key: "SLASHING_DONE", label: "Slashing Executed" },
  { key: "REWARD_DISTRIBUTED", label: "Rewards Distributed" },
  { key: "COMPLETED", label: "Scenario Completed" }
];

interface StepperProps {
  markers: string[];
}

export const Stepper = ({ markers }: StepperProps) => {
  const markerSet = new Set(markers);
  const currentIndex = steps.reduce((acc, step, index) => {
    return markerSet.has(step.key) ? index : acc;
  }, -1);

  return (
    <div>
      <h3>Progress</h3>
      <ol style={{ paddingLeft: 20 }}>
        {steps.map((step, index) => {
          const done = index <= currentIndex;
          return (
            <li
              key={step.key}
              style={{
                color: done ? "#7ce6a8" : "#8ea0bf",
                marginBottom: 8
              }}
            >
              {done ? "✅" : "⬜"} {step.label}
            </li>
          );
        })}
      </ol>
    </div>
  );
};
