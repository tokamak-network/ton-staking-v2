import { ChallengersConfig, NetworksConfig } from "../lib/types";
import { useChallengerBalances } from "../hooks/useChallengerBalances";

export const ChallengerBalancesPanel = ({
  challengers,
  networks
}: {
  challengers?: ChallengersConfig;
  networks?: NetworksConfig;
}) => {
  const balances = useChallengerBalances(challengers, networks);

  return (
    <div>
      <h3>Challenger Balances (WTON)</h3>
      <table className="table">
        <tbody>
          {balances.map((item) => (
            <tr key={item.address}>
              <td>{item.label}</td>
              <td>
                {item.balance} ({item.address})
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
