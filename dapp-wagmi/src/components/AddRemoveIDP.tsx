import React, { useState } from "react";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

type IDPFunctionName = "addIdentityProvider" | "removeIdentityProvider";

export const AddRemoveIDPComponent = () => {
  // unified state management
  const [idpAddress, setIdpAddress] = useState("");
  const [selectedAction, setSelectedAction] = useState<IDPFunctionName>("addIdentityProvider");
  
  const {
    writeContract,
    isPending,
    isError,
    isSuccess,
    reset: resetWriteState,
  } = useWriteContract();

  // action configuration
  const actionConfig = {
    addIdentityProvider: {
      label: "Add IDP",
      pending: "Adding IDP...",
      success: "Add IDP request sent successfully!",
      error: "Add IDP request failed",
    },
    removeIdentityProvider: {
      label: "Remove IDP",
      pending: "Removing IDP...",
      success: "Remove IDP request sent successfully!",
      error: "Remove IDP request failed",
    },
  } as const;

  // unified form handler
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idpAddress) return;

    try {
      writeContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: selectedAction,
        args: [idpAddress as `0x${string}`],
      });
    } catch (err) {
      console.error(`${actionConfig[selectedAction].label} call failed:`, err);
    }
  };

  // TODO: show current IDP addresses
  // getter in contract: address[] public identityProviders;

  return (
    <div className="subsection">
      <h2>Add, Remove identity providers</h2>
      <form onSubmit={handleSubmit} className="form">
        <label>Action Type:</label>
        <select
          value={selectedAction}
          onChange={(e) => {
            resetWriteState();
            setSelectedAction(e.target.value as IDPFunctionName);
          }}
          className="input-field"
        >
          <option value="addIdentityProvider">Add IDP</option>
          <option value="removeIdentityProvider">Remove IDP</option>
        </select>
        <label>Provider Address:</label>
        <input
          type="text"
          value={idpAddress}
          onChange={(e) => setIdpAddress(e.target.value)}
          className="input-field"
          required
        />
        <button
          type="submit"
          disabled={isPending}
          className="button"
        >
          {isPending 
            ? actionConfig[selectedAction].pending
            : actionConfig[selectedAction].label}
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