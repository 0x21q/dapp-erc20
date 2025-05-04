import {
  useAccount,
  useConnect,
  useDisconnect,
  useBalance,
} from "wagmi";
import { formatUnits } from "viem";
import { CONTRACT_ADDRESS } from "../config";
import { isUserVerified, getRoleName } from "../components/Roles";

export default function DashboardPage() {
  // wallet hook
  const account = useAccount();
  // connect and disconnect to available connectors
  const { connectors, connect, status, error } = useConnect();
  const { disconnect } = useDisconnect();
  // fetch role and verification info
  let roleName = getRoleName();
  let { data: hasVerifiedAccount } = isUserVerified();
  // token balance hook
  const { data: tokenBalance } = useBalance({
    address: account.address,
    token: CONTRACT_ADDRESS as `0x${string}`,
  });

  // just to preformat the balance
  const formattedUnits = tokenBalance
    ? formatUnits(tokenBalance.value, tokenBalance.decimals)
    : "";
  const formattedBalance = tokenBalance
    ? `${formattedUnits} ${tokenBalance.symbol}`
    : "Not Available";

  return (
    <div className="container">
      <h1>ERC20 BDA - Dashboard</h1>
      {/* acc info subsection */}
      <div className="subsection">
        <h2>Account Information</h2>
        <p>Status: {account.status}</p>
        <p>Role: {roleName ?? "None"}</p>
        <p>Verified: {hasVerifiedAccount ? "Yes" : "No"}</p>
        {account.status === "connected" && (
          <>
            <p>Address: {account.address}</p>
            <p>Chain ID: {account.chainId}</p>
            <p>Token Balance: {formattedBalance}</p>
            <button onClick={() => disconnect()} className="button">
              Disconnect
            </button>
          </>
        )}
      </div>

      {/* connect wallet subsection */}
      <div className="subsection">
        <h2>Connect Wallet</h2>
        {status && <p>Status: {status}</p>}
        <div className="connect-buttons">
          {connectors.map((connector) => (
            <button
              key={connector.uid}
              onClick={() => connect({ connector })}
              className="button"
              disabled={account.status === "connected"}
            >
              {connector.name}
            </button>
          ))}
        </div>
        {error && <p className="error-message">Error: {error.message}</p>}
      </div>
    </div>
  );
}
