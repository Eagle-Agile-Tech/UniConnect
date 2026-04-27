import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./contexts/auth-provider";
import { useAuth } from "./contexts/useAuth";
import Dashboard from "./dashboard";
import Signin from "./components/log/signin";
import Profile from "./components/profile/profile";
import EditProfile from "./components/profile/Editprofile";
import AddAdmin from "./components/profile/Addadmin";

import Page from "./page";
function AppContent() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950 text-white">
        <div className="text-center">
          <p className="text-lg font-semibold">Loading admin session...</p>
          <p className="text-sm text-slate-400">Connecting to UniConnect backend</p>
        </div>
      </div>
    );
  }

  // If user is NOT logged in
  if (!user) {
    return (
      <Routes>
        <Route path="/signin" element={<Signin />} />
        <Route path="/" element={<Navigate to="/signin" replace />} />
        <Route path="*" element={<Navigate to="/signin" replace />} />
      </Routes>
    );
  }

  // If user IS logged in
  return (
    <Routes>
      <Route path="/dashboard/*" element={<Dashboard />} />

      <Route path="/profile" element={<Profile />} />
      <Route path="/profile/edit-profile" element={<EditProfile />} />
      <Route path="/profile/add-admin" element={<AddAdmin />} />
      <Route path="/page" element={<Page />} />
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <AppContent />
      </Router>
    </AuthProvider>
  );
}
