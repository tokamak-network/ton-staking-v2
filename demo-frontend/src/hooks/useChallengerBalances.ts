import { useEffect, useState } from "react";
import { Contract } from "ethers";
import { ChallengersConfig, NetworksConfig } from "../lib/types";
import { getProvider } from "../lib/chain";

const erc20Abi = ["function balanceOf(address) view returns (uint256)", "function decimals() view returns (uint8)"];

interface ChallengerBalance {
  label: string;
  address: string;
  balance: string;
}

export const useChallengerBalances = (
  challengers?: ChallengersConfig,
  networks?: NetworksConfig
) => {
  const [balances, setBalances] = useState<ChallengerBalance[]>([]);

  useEffect(() => {
    const load = async () => {
      if (!challengers?.rewardToken?.address || !challengers?.challengers) return;

      const provider = getProvider(networks, "l1");
      if (!provider) return;

      const token = new Contract(challengers.rewardToken.address, erc20Abi, provider);
      const decimals = await token.decimals();

      const items: ChallengerBalance[] = [];
      for (const challenger of challengers.challengers) {
        const raw = await token.balanceOf(challenger.address);
        const formatted = (Number(raw) / 10 ** decimals).toFixed(4);
        items.push({
          label: challenger.label,
          address: challenger.address,
          balance: formatted
        });
      }

      setBalances(items);
    };

    void load();
    const interval = setInterval(load, 6000);
    return () => clearInterval(interval);
  }, [challengers, networks]);

  return balances;
};
