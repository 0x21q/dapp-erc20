import { createBrowserRouter, RouterProvider } from "react-router-dom";
import Navigation from "./components/Navigation";
import DashboardPage from "./pages/DashboardPage";
import TokenPage from "./pages/TokenPage";
import IdpAdminPage from "./pages/IdpAdminPage";
import ProposalPage from "./pages/ProposalPage";
import ProfilePage from "./pages/ProfilePage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <Navigation />,
    children: [
      { index: true, element: <DashboardPage /> },
      { path: "token-management", element: <TokenPage /> }, // Tasks 1,2,3
      { path: "idp-admin", element: <IdpAdminPage /> }, // Tasks 5,7
      { path: "role-proposal", element: <ProposalPage /> }, // Task 9
      { path: "profile-management", element: <ProfilePage /> }, // Tasks 4,6
    ],
  },
]);

export default function App() {
  return <RouterProvider router={router} />;
}
