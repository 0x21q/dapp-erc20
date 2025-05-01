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

  // TODO
  return "";
}