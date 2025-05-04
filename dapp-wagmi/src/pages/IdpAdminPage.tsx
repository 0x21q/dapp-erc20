import { AddRemoveIDPComponent } from "../components/AddRemoveIDP.tsx";
import { IdpAdminActionComponent } from "../components/IdpAdminAction.tsx";
import { useRoleCheck } from "../components/Roles.ts";

export default function IdpAdminPage() {
  const { hasIdpAdminRole, loading } = useRoleCheck();

  return (
    <div className="container">
      <h1 className="">ERC20 BDA - IDP Administration</h1>
      {loading && <div>Fetching user role...</div>}
      {hasIdpAdminRole && <AddRemoveIDPComponent/>}
      {hasIdpAdminRole && <IdpAdminActionComponent/>}
    </div>
  );
}

