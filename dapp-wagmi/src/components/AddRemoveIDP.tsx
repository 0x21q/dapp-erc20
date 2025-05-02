import React, { useState } from "react";
import { parseUnits } from "viem";
import { erc20BdaAbi } from "../generated.ts";
import { useWriteContract } from "wagmi";
import { CONTRACT_ADDRESS } from "../config.ts";

//function addIdentityProvider(address idpAddress)
//function removeIdentityProvider(address idpAddress)

export const AddRemoveIDPComponent = () => {
  // add/remove IDP section
  const [idpAddressAdd, setIdpAddressAdd] = useState("");
  const {
    writeContract: idpAddWrite,
    isPending: isIdpAddPending,
    isError: isIdpAddError,
    isSuccess: isIdpAddSuccess,
  } = useWriteContract();

  const [idpAddressRemove, setIdpAddressRemove] = useState("");
  const {
    writeContract: idpRemoveWrite,
    isPending: isIdpRemovePending,
    isError: isIdpRemoveError,
    isSuccess: isIdpRemoveSuccess,
  } = useWriteContract();

  // calling Add Idp hook
  const handleAddIdp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idpAddressAdd) return;

    try {
      idpAddWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "addIdentityProvider",
        args: [idpAddressAdd as `0x${string}`],
      });
    } catch (err) {
      console.error("Adding IDP call failed:", err);
    }
  };

  // calling Add Idp hook
  const handleRemoveIdp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idpAddressRemove) return;

    try {
      idpRemoveWrite({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "removeIdentityProvider",
        args: [idpAddressRemove as `0x${string}`],
      });
    } catch (err) {
      console.error("Removing IDP call failed:", err);
    }
  };

  // TODO: show current IDP addresses
  // getter in contract: address[] public identityProviders;

  return (
    <>
    <div className="subsection">
      <h2>Add identity provider</h2>
      <form onSubmit={handleAddIdp} className="form">
        <label>Address of the provider:</label>
        <input
          type="text"
          value={idpAddressAdd}
          onChange={(e) => setIdpAddressAdd(e.target.value)}
          className="input-field"
          required
        />
        <button type="submit" disabled={isIdpAddPending} className="button">
          {isIdpAddPending ? "Adding IDP..." : "Add IDP"}
        </button>
        {isIdpAddSuccess && (
          <div className="success-message">Add IDP request sent successfully!</div>
        )}
        {isIdpAddError && (
          <div className="error-message">Add IDP request failed</div>
        )}
      </form>
    </div>
    <div className="subsection">
      <h2>Remove identity provider</h2>
      <form onSubmit={handleRemoveIdp} className="form">
        <label>Address of the provider:</label>
        <input
          type="text"
          value={idpAddressRemove}
          onChange={(e) => setIdpAddressRemove(e.target.value)}
          className="input-field"
          required
        />
        <button type="submit" disabled={isIdpRemovePending} className="button">
          {isIdpRemovePending ? "Removing limit..." : "Remove limit"}
        </button>
        {isIdpRemoveSuccess && (
          <div className="success-message">Remove IDP request sent successfully!</div>
        )}
        {isIdpRemoveError && (
          <div className="error-message">Remove IDP request failed</div>
        )}
      </form>
    </div>
    </>
  );
}