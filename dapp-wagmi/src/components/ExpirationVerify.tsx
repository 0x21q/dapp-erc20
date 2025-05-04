import { useEffect, useState } from "react";
import { formatUnits } from "viem";
import { useReadContract } from "wagmi";
import { erc20BdaAbi } from "../generated.ts";
import { CONTRACT_ADDRESS } from "../config.ts";

interface ExpirationComponentProps {
  address: `0x${string}` | undefined;
  onReverify: () => void;
}

export const ExpirationComponent = (
  { address, onReverify }: ExpirationComponentProps
) => {
  // read verification timestamp
  const { 
    data: verificationTimestamp, 
    isLoading: isLoadingTimestamp,
    isError: isErrorTimestamp,
  } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: erc20BdaAbi,
    functionName: "verificationTimestamp",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
      refetchInterval: 1000,
    }
  });

  // read expiration time duration from contract
  const { 
    data: expirationDuration,
    isLoading: isLoadingDuration,
    isError: isErrorDuration,
  } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: erc20BdaAbi,
    functionName: "expirationTime",
  });

  const [timeRemaining, setTimeRemaining] = useState("");

  useEffect(() => {
    const updateTimer = () => {
      if (!verificationTimestamp || !expirationDuration) return;
      // convert verificationTimestamp from seconds (no decimals)
      const verificationTime = Number(verificationTimestamp);
      // convert expirationDuration from wei (18 decimals) to seconds
      const duration = Number(formatUnits(expirationDuration, 18));
      const expirationTime = verificationTime + duration;
      const now = Math.floor(Date.now() / 1000);
      const remaining = expirationTime - now;
  
      if (remaining <= 0) {
        setTimeRemaining("Expired");
        return;
      }
  
      const days = Math.floor(remaining / 86400);
      const hours = Math.floor((remaining % 86400) / 3600);
      const minutes = Math.floor((remaining % 3600) / 60);
      const seconds = remaining % 60;
  
      setTimeRemaining(`${days}d ${hours}h ${minutes}m ${seconds}s`);
    };
  
    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [verificationTimestamp, expirationDuration]);

  // handle loading and error states
  if (isLoadingTimestamp || isLoadingDuration) {
    return <div>Loading verification status...</div>;
  }
  
  if (isErrorTimestamp || isErrorDuration) {
    return <div>Error loading verification data</div>;
  }

  return (
    <div className="subsection">
      <h2>Identity Status</h2>
      <p className="info-box">Time remaining: {timeRemaining}</p>
      <button onClick={onReverify} className="button">
        Renew Verification
      </button>
    </div>
  );
};