import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract, useReadContract, useAccount } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

export const VerifyComponent = () => {
  // read verification info from chain
  const account = useAccount();
  const { data: isVerified, isLoading, isError } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: erc20BdaAbi,
    functionName: "isVerified",
    args: account.address ? [account.address] : undefined,
    query: {
      enabled: !!account.address,
    }
  })

  // verify section
  const [timestamp, setTimestamp] = useState("");
  const [signature, setSignature] = useState("");
  const {
    writeContract: verifyWrite,
    isPending: isVerifyPending,
    isError: isVerifyError,
    isSuccess: isVerifySuccess,
  } = useWriteContract();

  // calling verify hook and checking signature format
  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!timestamp || !signature) return;

    try {
      const formattedSignature = signature.startsWith('0x') 
      ? signature 
      : `0x${signature}`;

      verifyWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "verifyIdentity",
        args: [parseUnits(timestamp, 0), formattedSignature as `0x${string}`],
      });
    } catch (err) {
      console.error("Approval failed:", err);
    }
  };

  return (
    <>
    {!isVerified && !isLoading && !isError && (
      <div className="subsection">
        <h2>Verify account</h2>
        <p>
          To verify an account please provide a timestamp and
          a signature provided by verified Identity Provider.
        </p>
        <form onSubmit={handleVerify} className="form">
          <label>UNIX timestamp of the signature:</label>
          <input
            type="number"
            value={timestamp}
            onChange={(e) => setTimestamp(e.target.value)}
            className="input-field"
            required
          />
          <label>Signature:</label>
          <input
            type="text"
            value={signature}
            onChange={(e) => setSignature(e.target.value)}
            className="input-field"
            required
          />
          <button type="submit" disabled={isVerifyPending} className="button">
            {isVerifyPending ? "Verifying..." : "Verify account"}
          </button>
          {isVerifySuccess && (
            <div className="success-message">Verification request sent successfully!</div>
          )}
          {isVerifyError && (
            <div className="error-message">Approval failed</div>
          )}
        </form>
      </div>
    )}
    </>
  );
}