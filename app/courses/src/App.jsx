import React, { useState } from "react";
import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
  useNavigate,
  useLocation,
} from "react-router-dom";
import LoginPage from "./pages/LoginPage.jsx";
import Dashboard from "./pages/expert/Dashboard.jsx";

import UploadCourse from "./pages/expert/UploadCourse.jsx";
import EditCourse from "./pages/expert/EditCourse.jsx";
import StudentDashboard from "./pages/student/StudentDashboard.jsx";
import SavedCourses from "./pages/student/SavedCourses.jsx";
import ExpertMyCourses from "./pages/expert/MyCourses.jsx";
import StudentMyCourses from "./pages/student/MyCourses.jsx";
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

function getInitialUser() {
  try {
    const storedUser = localStorage.getItem("currentUser");
    return storedUser ? JSON.parse(storedUser) : null;
  } catch {
    return null;
  }
}

function AppRoutes() {
  const [currentUser, setCurrentUser] = useState(null);
  const [authError, setAuthError] = useState("");
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogin = async (email, password) => {
    setAuthError("");

    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email: email.trim(), password }),
      });

      const result = await response.json();

      if (!response.ok) {
        setAuthError(result?.message || "Invalid email or password.");
        return;
      }

      const user = result;
      const normalizedUser = {
        ...user,
        role: user?.role?.toLowerCase(),
      };
      const role = normalizedUser.role;

      if (user?.accessToken) {
        localStorage.setItem("token", user.accessToken);
      }

      const storedUser = {
        ...normalizedUser,
      };
      delete storedUser.accessToken;
      delete storedUser.refreshToken;
      delete storedUser.sessionId;

      setCurrentUser(storedUser);
      setAuthError("");

      if (role === "expert") {
        navigate("/expert/dashboard", { replace: true });
        return;
      }

      if (role === "student") {
        navigate("/student/dashboard", { replace: true });
        return;
      }

      setAuthError("Student access is not available yet.");
    } catch (error) {
      setAuthError(error?.message || "Unable to connect to the backend.");
    }
  };

  const requireExpert = (element) =>
    currentUser?.role === "expert" ? (
      element
    ) : (
      <Navigate to="/" replace state={{ from: location }} />
    );

  const requireStudent = (element) =>
    currentUser?.role === "student" ? (
      element
    ) : (
      <Navigate to="/" replace state={{ from: location }} />
    );

  return (
    <Routes>
      <Route
        path="/"
        element={
          currentUser ? (
            <Navigate
              to={
                currentUser?.role === "expert"
                  ? "/expert/dashboard"
                  : "/student/dashboard"
              }
              replace
            />
          ) : (
            <LoginPage onLogin={handleLogin} error={authError} />
          )
        }
      />
      <Route path="/expert/dashboard" element={requireExpert(<Dashboard />)} />
      <Route
        path="/expert/mycourse"
        element={requireExpert(<ExpertMyCourses />)}
      />
      <Route
        path="/expert/mycourses"
        element={requireExpert(<ExpertMyCourses />)}
      />

      <Route
        path="/student/mycourses"
        element={requireStudent(<StudentMyCourses />)}
      />
      <Route
        path="/expert/upload-course"
        element={requireExpert(<UploadCourse />)}
      />
      <Route
        path="/expert/edit-course/:id"
        element={requireExpert(<EditCourse />)}
      />
      <Route
        path="/student/dashboard"
        element={requireStudent(
          <StudentDashboard
            user={currentUser}
            onNavigate={(path) => navigate(path)}
            activePage="student-dashboard"
          />,
        )}
      />

      <Route
        path="*"
        element={
          <Navigate
            to={
              currentUser?.role === "expert"
                ? "/expert/dashboard"
                : currentUser?.role === "student"
                  ? "/student/dashboard"
                  : "/"
            }
            replace
          />
        }
      />
      <Route path="/student/saved" element={requireStudent(<SavedCourses />)} />
    </Routes>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  );
}
