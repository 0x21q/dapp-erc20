import { useState } from "react";
import { useAccount, useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated";

export const TokenTransfer = () => {
  const account = useAccount();

  // transfer hook
  const { writeContract, isPending, isError, isSuccess } = useWriteContract();
  // react states
  const [recipient, setRecipient] = useState("");
  const [amount, setAmount] = useState("");

  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!account.address || !recipient || !amount) return;

    try {
      // Convert amount to wei (using standard 18 decimal places)
      writeContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "transfer",
        args: [recipient as `0x${string}`, parseUnits(amount ,18)],
      });
    } catch (error) {
      console.error("Transfer error:", error);
    }
  };
  return (
    <div className="subsection">
    <h2>Token Transfer</h2>
    <form onSubmit={handleTransfer} className="form">
      <label className="">Recipient Address:</label>
      <input
        type="text"
        value={recipient}
        onChange={(e) => setRecipient(e.target.value)}
        className="input-field"
        required
      />
      <label className="">Amount:</label>
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        className="input-field"
        required
      />
      <button type="submit" disabled={isPending} className="button">
        {isPending ? "Processing..." : "Transfer Tokens"}
      </button>
      {isSuccess && (
        <div className="success-message">Transaction successful</div>
      )}
      {isError && <div className="error-message">Transaction failed</div>}
    </form>
  </div>
  );
}