import { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract, useReadContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

export default function TokenPage() {
  // Approve section
  const [spender, setSpender] = useState("");
  const [amount, setAmount] = useState("");

  const {
    writeContract: approveWriteContract,
    isPending: isApprovePending,
    isError: isApproveError,
    isSuccess: isApproveSuccess,
  } = useWriteContract();

  // mint section
  const [recipient, setRecipient] = useState("");
  const [mintAmount, setMintAmount] = useState("");
  const {
    writeContract: mintWriteContract,
    isPending: isMintPending,
    isError: isMintError,
    isSuccess: isMintSuccess,
  } = useWriteContract();

  // read mint limits
  const { data: dailyMintLimit } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: erc20BdaAbi,
    functionName: "maxDailyLimit",
  });

  const { data: dailyMintedAmount } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: erc20BdaAbi,
    functionName: "dailyMinted",
  });

  const remainingTokens =
    dailyMintLimit && dailyMintedAmount
      ? dailyMintLimit - dailyMintedAmount
      : BigInt(0);

  // Temporary until role check is implemented
  const [hasMintingRole] = useState(true);

  const handleApprove = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!spender || !amount) return;

    try {
      mintWriteContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "approve",
        args: [spender as `0x${string}`, parseUnits(amount, 18)],
      });
    } catch (err) {
      console.error("Approval failed:", err);
    }
  };

  const handleMint = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!recipient || !mintAmount) return;

    try {
      approveWriteContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "mint",
        args: [recipient as `0x${string}`, parseUnits(mintAmount, 18)],
      });
    } catch (err) {
      console.error("Minting failed:", err);
    }
  };

  return (
    <div className="container">
      <h1 className="">ERC20 BDA - Token page</h1>
      <div className="subsection">
        <h2>Approve Spending</h2>
        <form onSubmit={handleApprove} className="form">
          <label>Spender Address:</label>
          <input
            type="text"
            value={spender}
            onChange={(e) => setSpender(e.target.value)}
            className="input-field"
            required
          />
          <label>Amount (in tokens):</label>
          <input
            type="text"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input-field"
            required
          />
          <button type="submit" disabled={isApprovePending} className="button">
            {isApprovePending ? "Processing..." : "Approve Spending"}
          </button>
          {isApproveSuccess && (
            <div className="success-message">Approval successful</div>
          )}
          {isApproveError && (
            <div className="error-message">Approval failed</div>
          )}
        </form>
      </div>

      {hasMintingRole && (
        <div className="subsection">
          <h2>Token Minting</h2>
          <div className="info-box">
            Remaining mintable tokens today: {remainingTokens.toString()}
          </div>
          <form onSubmit={handleMint} className="form">
            <label>Recipient Address:</label>
            <input
              type="text"
              value={recipient}
              onChange={(e) => setRecipient(e.target.value)}
              className="input-field"
              required
            />
            <label>Amount to Mint (in tokens):</label>
            <input
              type="text"
              value={mintAmount}
              onChange={(e) => setMintAmount(e.target.value)}
              className="input-field"
              required
            />
            <button type="submit" disabled={isMintPending} className="button">
              {isMintPending ? "Minting..." : "Mint Tokens"}
            </button>
            {isMintSuccess && (
              <div className="success-message">Minting sent successfuly!</div>
            )}
            {isMintError && (
              <div className="error-message">Minting sent failed</div>
            )}
          </form>
        </div>
      )}
    </div>
  );
}
