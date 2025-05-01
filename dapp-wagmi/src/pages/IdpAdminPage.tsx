import { useState } from "react";
import { AddRemoveIDPComponent } from "../components/AddRemoveIDP.tsx";

export default function IdpAdminPage() {
  // Temporary until role check is implemented
  const [hasIdpAdminRole] = useState(true);

  return (
    <div className="container">
      <h1 className="">ERC20 BDA - IDP Administration</h1>
      {hasIdpAdminRole && <AddRemoveIDPComponent/>}
    </div>
  );
}

