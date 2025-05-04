import { useState } from "react";
import { useAccount } from "wagmi";
import { VerifyComponent } from "../components/Verify";
import { ExpirationComponent } from "../components/ExpirationVerify";
import { isUserVerified } from "../components/Roles.ts";

export default function ProfilePage() {
  const account = useAccount();
  const [showReverify, setShowReverify] = useState(false);

  const { 
    data: isVerified, 
    isLoading, 
    isError, 
  } = isUserVerified();

  return (
    <div className="container">
      <h1>ERC20 BDA - Profile page</h1>
      {account.status === "connected" && (
        <>
        {isVerified && !showReverify ? (
          <ExpirationComponent 
            address={account.address}
            onReverify={() => setShowReverify(true)}
          />
        ) : (
          <VerifyComponent 
            isVerified={isVerified}
            isLoading={isLoading}
            isError={isError}
          />
        )}
        </>
      )}
    </div>
  )
}
