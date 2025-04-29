import { Link, Outlet } from 'react-router-dom';

export default function Navigation() {
    return (
      <div>
        <nav>
          <Link to="/">HomePage - Wallet</Link>
        </nav>
        <Outlet />
      </div>
    );
  }