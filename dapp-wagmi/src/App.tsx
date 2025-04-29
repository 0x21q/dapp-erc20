import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import HomePage from './pages/HomePage';
import Navigation from './components/Navigation';

const router = createBrowserRouter([
    {
      path: "/",
      element: <Navigation />,
      children: [
        { index: true, element: <HomePage /> },
        { path: "approvals", element: <ApprovalsPage /> },
        { path: "mint", element: <MintPage /> },
        { path: "transfer-restrictions", element: <TransferRestrictionsPage /> },
        { path: "identity", element: <IdentityPage /> },
        { path: "idp-management", element: <IdpManagementPage /> },
        { path: "governance", element: <GovernancePage /> },
        { path: "admin", element: <AdminPanelPage /> }
      ]
    }
  ]);

export default function App() {
  return <RouterProvider router={router} />;
}
