import { useState } from "react";
import { useWriteContract } from "wagmi";
import { erc20BdaAbi } from "../generated.ts";
import { CONTRACT_ADDRESS } from "../config.ts";

type ContractFunctionName = 
  | "verifyAddressAdmin" 
  | "revokeVerification" 
  | "blockAddress" 
  | "unblockAddress";

export const IdpAdminActionComponent = () => {
  const [address, setAddress] = useState("");
  const [
    selectedAction,
    setSelectedAction
  ] = useState<ContractFunctionName>("verifyAddressAdmin");
  
  // setup hook
  const {
    writeContract,
    isPending,
    isError,
    isSuccess,
    reset: resetWriteState,
  } = useWriteContract();

  // define actions for reuse in single hook since all share
  // the same input address but just differ in functionName
  const actionConfig = {
    verifyAddressAdmin: {
      label: "Verify Address",
      success: "Address verified successfully!",
      error: "Verification failed",
    },
    revokeVerification: {
      label: "Revoke Verification",
      success: "Verification revoked successfully!",
      error: "Revocation failed",
    },
    blockAddress: {
      label: "Block Address",
      success: "Address blocked successfully!",
      error: "Blocking failed",
    },
    unblockAddress: {
      label: "Unblock Address",
      success: "Address unblocked successfully!",
      error: "Unblocking failed",
    },
  } as const;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address) return;

    writeContract({
      address: CONTRACT_ADDRESS as `0x${string}`,
      abi: erc20BdaAbi,
      functionName: selectedAction,
      args: [address as `0x${string}`],
    });
  };

  return (
    <div className="subsection">
      <h2>Verify, Revoke, Block, Unblock accounts</h2>
      <form onSubmit={handleSubmit} className="form">
        <label>Select Action:</label>
        <select
          value={selectedAction}
          onChange={(e) => {
            resetWriteState();
            setSelectedAction(e.target.value as ContractFunctionName);
          }}
          className="input-field"
        >
          <option value="verifyAddressAdmin">Verify Address</option>
          <option value="revokeVerification">Revoke Verification</option>
          <option value="blockAddress">Block Address</option>
          <option value="unblockAddress">Unblock Address</option>
        </select>
        <label>Address:</label>
        <input
          type="text"
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          className="input-field"
          required
        />
        <button
          type="submit"
          disabled={isPending}
          className="button"
        >
          {isPending ? "Processing..." : actionConfig[selectedAction].label}
        </button>
        {isSuccess && (
          <div className="success-message">
            {actionConfig[selectedAction].success}
          </div>
        )}
        {isError && (
          <div className="error-message">
            {actionConfig[selectedAction].error}
          </div>
        )}
      </form>
    </div>
  );
};