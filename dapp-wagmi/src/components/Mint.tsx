import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract, useReadContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

export const MintComponent = () => {
  // mint section
  const [recipient, setRecipient] = useState("");
  const [mintAmount, setMintAmount] = useState("");
  const {
    writeContract: mintWrite,
    isPending: isMintPending,
    isError: isMintError,
    isSuccess: isMintSuccess,
  } = useWriteContract();

  // calling mint hook
  const handleMint = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!recipient || !mintAmount) return;

    try {
      mintWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "mint",
        args: [recipient as `0x${string}`, parseUnits(mintAmount, 18)],
      });
    } catch (err) {
      console.error("Minting failed:", err);
    }
  };

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

  return (
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
          type="number"
          value={mintAmount}
          onChange={(e) => setMintAmount(e.target.value)}
          className="input-field"
          required
        />
        <button type="submit" disabled={isMintPending} className="button">
          {isMintPending ? "Minting..." : "Mint Tokens"}
        </button>
        {isMintSuccess && (
          <div className="success-message">Mint request sent successfuly!</div>
        )}
        {isMintError && (
          <div className="error-message">Mint request failed</div>
        )}
      </form>
    </div> 
  );
}