import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

export const ApproveComponent = () => {
  // approve section
  const [spender, setSpender] = useState("");
  const [approveAmount, setApproveAmount] = useState("");
  const {
    writeContract: approveWrite,
    isPending: isApprovePending,
    isError: isApproveError,
    isSuccess: isApproveSuccess,
  } = useWriteContract();

  // calling approve hook
  const handleApprove = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!spender || !approveAmount) return;

    try {
      approveWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "approve",
        args: [spender as `0x${string}`, parseUnits(approveAmount, 18)],
      });
    } catch (err) {
      console.error("Approval failed:", err);
    }
  };

  return (
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
            type="number"
            value={approveAmount}
            onChange={(e) => setApproveAmount(e.target.value)}
            className="input-field"
            required
          />
          <button type="submit" disabled={isApprovePending} className="button">
            {isApprovePending ? "Processing..." : "Approve Spending"}
          </button>
          {isApproveSuccess && (
            <div className="success-message">Approval request sent successfully!</div>
          )}
          {isApproveError && (
            <div className="error-message">Approval request failed</div>
          )}
        </form>
      </div>
  );
}
