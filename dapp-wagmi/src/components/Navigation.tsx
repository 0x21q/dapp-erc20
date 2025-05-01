import { NavLink, Outlet } from "react-router-dom";

export default function Navigation() {
  return (
    <div>
      <nav className="nav">
        <NavLink to="/" className="nav-link">
          Dashboard
        </NavLink>
        <NavLink to="/token-management" className="nav-link">
          Token Management
        </NavLink>
        <NavLink to="/profile-management" className="nav-link">
          Profile Page
        </NavLink>
        <NavLink to="/idp-admin" className="nav-link">
          IDP Admin Page
        </NavLink>
        <NavLink to="/role-proposal" className="nav-link">
          Role proposals
        </NavLink>
      </nav>
      <Outlet />
    </div>
  );
}
