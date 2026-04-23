// src/assets/components/Sidebar.jsx
import React from "react";
import { NavLink } from "react-router-dom";
import "./Sidebar.css";

export default function Sidebar() {
  const items = [
    { id: "dashboard", label: "Overview", to: "/expert/dashboard" },
    { id: "my-courses", label: "My Courses", to: "/expert/mycourse" },
    { id: "upload-course", label: "Upload Course", to: "/expert/upload-course" },
  ];

  return (
    <div className="sidebar">
      <h2>UniConnect</h2>
      <nav>
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              <NavLink
                to={item.to}
                className={({ isActive }) =>
                  isActive ? "sidebar-link active" : "sidebar-link"
                }
              >
                {item.label}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  );
}