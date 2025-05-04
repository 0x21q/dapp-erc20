import { ApproveComponent } from "../components/Approve.tsx";
import { MintComponent } from "../components/Mint.tsx";
import { TransferLimitComponent } from "../components/TransferLimit.tsx";
import { isUserVerified, useRoleCheck } from "../components/Roles.ts";
import { TokenTransfer } from "../components/TokenTransfer";

export default function TokenPage() {
  const { hasMintingRole, hasRestrRole, loading } = useRoleCheck();
  const { data: hasVerifiedAccount, isLoading } = isUserVerified();

  return (
    <div className="container">
      <h1 className="">ERC20 BDA - Token management</h1>
      {loading && <div>Fetching user role...</div>}
      {isLoading && <div>Fetching user verification status...</div>}
      {hasVerifiedAccount && <TokenTransfer/>}
      {hasVerifiedAccount && <ApproveComponent/>}
      {hasMintingRole && <MintComponent/>}
      {hasRestrRole && <TransferLimitComponent/>}
    </div>
  );
}
