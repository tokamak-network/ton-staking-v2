import { useRpcStatus } from "../hooks/useRpcStatus";
import { NetworksConfig } from "../lib/types";

export const RpcStatusPanel = ({ networks }: { networks?: NetworksConfig }) => {
  const status = useRpcStatus(networks);

  return (
    <div>
      <h3>RPC Status</h3>
      <table className="table">
        <tbody>
          {status.map((item) => (
            <tr key={item.network}>
              <td>{item.network.toUpperCase()}</td>
              <td>
                {item.ok
                  ? `OK (block ${item.blockNumber})`
                  : `ERROR: ${item.error}`}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
