import { useAccount, useReadContract } from "wagmi";
import { erc20BdaAbi } from "../generated";
import { CONTRACT_ADDRESS } from "../config";
import { keccak256, toHex } from "viem";

const mintingAdminHash = keccak256(toHex("MINTING_ADMIN_ROLE"));
const restrAdminHash = keccak256(toHex("RESTR_ADMIN_ROLE"));
const idpAdminHash = keccak256(toHex("IDP_ADMIN_ROLE"));

export function useRoleCheck() {
    const { address } = useAccount();
    const MintingRole = useReadContract({
      address: CONTRACT_ADDRESS as `0x${string}`,
      abi: erc20BdaAbi,
      functionName: "hasRole",
      args: [mintingAdminHash, address as `0x${string}`],
      query: { enabled: !!address }
    });
    const RestrRole = useReadContract({
      address: CONTRACT_ADDRESS as `0x${string}`,
      abi: erc20BdaAbi,
      functionName: "hasRole",
      args: [restrAdminHash, address as `0x${string}`],
      query: { enabled: !!address }
    });
    const IdpAdminRole = useReadContract({
      address: CONTRACT_ADDRESS as `0x${string}`,
      abi: erc20BdaAbi,
      functionName: "hasRole",
      args: [idpAdminHash, address as `0x${string}`],
      query: { enabled: !!address }
    });

    const loading = MintingRole.isLoading 
        || RestrRole.isLoading
        || IdpAdminRole.isLoading;

    return {
        hasMintingRole: !!MintingRole.data,
        hasRestrRole: !!RestrRole.data,
        hasIdpAdminRole: !!IdpAdminRole.data,
        loading
    };
}

export function getRoleName() {
  const {
    hasMintingRole,
    hasRestrRole,
    hasIdpAdminRole,
    loading
  } = useRoleCheck();

  if (loading) {
    return  "Fetching user role...";
  } else if (hasMintingRole) {
    return  "Minting admin";
  } else if (hasRestrRole) {
    return  "Restriction admin";
  } else if (hasIdpAdminRole) {
    return "IDP admin";
  } else {
    return "User";
  }
}

export function isUserVerified() {
    const { address } = useAccount();
    return useReadContract({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: erc20BdaAbi,
        functionName: "isVerified",
        args: [address as `0x${string}`],
        query: { enabled: !!address }
    });
}