import { useState } from "react";
import { ApproveComponent } from "../components/Approve.tsx";
import { MintComponent } from "../components/Mint.tsx";
import { TransferLimitComponent } from "../components/TransferLimit.tsx";

export default function TokenPage() {
  // Temporary until role check is implemented
  const [hasVerifiedAccount] = useState(true);
  const [hasMintingRole] = useState(true);
  const [hasRestrRole] = useState(true);

  return (
    <div className="container">
      <h1 className="">ERC20 BDA - Token management</h1>
      {hasVerifiedAccount && <ApproveComponent/>}
      {hasMintingRole && <MintComponent/>}
      {hasRestrRole && <TransferLimitComponent/>}
    </div>
  );
}
