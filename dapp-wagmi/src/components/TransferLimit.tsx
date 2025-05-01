import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

export const TransferLimitComponent = () => {
  // transfer limit section
  const [limitAccountSet, setLimitAccountSet] = useState("");
  const [limitSet, setLimitSet] = useState("");
  const {
    writeContract: setLimitWrite,
    isPending: isSetLimitPending,
    isError: isSetLimitError,
    isSuccess: isSetLimitSuccess,
  } = useWriteContract();

  const [limitAccountUnset, setLimitAccountUnset] = useState("");
  const {
    writeContract: unsetLimitWrite,
    isPending: isUnsetLimitPending,
    isError: isUnsetLimitError,
    isSuccess: isUnsetLimitSuccess,
  } = useWriteContract();

  // calling set transfer limit hook
  const handleSetTransferLimit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!limitAccountSet || !limitSet) return;

    try {
      setLimitWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "setTransferLimit",
        args: [limitAccountSet as `0x${string}`, parseUnits(limitSet, 18)],
      });
    } catch (err) {
      console.error("Setting transfer limit failed:", err);
    }
  };

  // calling set transfer limit hook
  const handleUnsetTransferLimit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!limitAccountUnset) return;

    try {
      unsetLimitWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "unsetTransferLimit",
        args: [limitAccountUnset as `0x${string}`],
      });
    } catch (err) {
      console.error("Setting transfer limit failed:", err);
    }
  };

  return (
    <>
    <div className="subsection">
      <h2>Set limit restrictions</h2>
      <form onSubmit={handleSetTransferLimit} className="form">
        <label>Address to limit:</label>
        <input
          type="text"
          value={limitAccountSet}
          onChange={(e) => setLimitAccountSet(e.target.value)}
          className="input-field"
          required
        />
        <label>Limit Amount (in tokens):</label>
        <input
          type="text"
          value={limitSet}
          onChange={(e) => setLimitSet(e.target.value)}
          className="input-field"
          required
        />
        <button type="submit" disabled={isSetLimitPending} className="button">
          {isSetLimitPending ? "Setting limit..." : "Set limit"}
        </button>
        {isSetLimitSuccess && (
          <div className="success-message">Set limit request sent successfully!</div>
        )}
        {isSetLimitError && (
          <div className="error-message">Set limit request failed</div>
        )}
      </form>
    </div>
    <div className="subsection">
      <h2>Remove limit restrictions</h2>
      <form onSubmit={handleUnsetTransferLimit} className="form">
        <label>Address to remove limit:</label>
        <input
          type="text"
          value={limitAccountUnset}
          onChange={(e) => setLimitAccountUnset(e.target.value)}
          className="input-field"
          required
        />
        <button type="submit" disabled={isUnsetLimitPending} className="button">
          {isUnsetLimitPending ? "Removing limit..." : "Remove limit"}
        </button>
        {isUnsetLimitSuccess && (
          <div className="success-message">Remove limit request sent successfully!</div>
        )}
        {isUnsetLimitError && (
          <div className="error-message">Remove limit request failed</div>
        )}
      </form>
    </div>
    </>
  );
}