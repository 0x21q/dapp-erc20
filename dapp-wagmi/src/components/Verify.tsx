import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

interface VerifyComponentProps {
  isVerified?: boolean;
  isLoading: boolean;
  isError: boolean;
}

export const VerifyComponent = ({ 
  isVerified, 
  isLoading, 
  isError 
}: VerifyComponentProps) => {
  // verify section
  const [timestamp, setTimestamp] = useState("");
  const [signature, setSignature] = useState("");
  const {
    writeContract: verifyWrite,
    isPending: isVerifyPending,
    isSuccess: isVerifySuccess,
    isError: isVerifyError,
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
      console.error("Verification failed:", err);
    }
  };

  return (
    <div className="subsection">
      <h2>{isVerified ? "Reverify Account" : "Verify Account"}</h2>
      {isLoading && (
        <div className="loading-message">Checking verification status...</div>
      )}
      {isError && (
        <div className="error-message">Error checking verification status</div>
      )}
      {!isLoading && !isError && (
        <>
          <div className="info-box">
            To {isVerified ? "reverify" : "verify"} your account, please
            provide a timestamp and a signature provided by a verified provider.
          </div>
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
              {isVerifyPending ? "Processing..." : "Submit Verification"}
            </button>
            {isVerifySuccess && (
              <div className="success-message">Verification request sent successfully!</div>
            )}
            {isVerifyError && (
              <div className="error-message">Verification request failed</div>
            )}
          </form>
        </>
      )}
    </div>
  );
};