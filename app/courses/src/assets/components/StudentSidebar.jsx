// src/assets/components/StudentSidebar.jsx
import React from "react";
import { NavLink } from "react-router-dom";
import "./StudentSidebar.css";

export default function StudentSidebar() {
  const items = [
    { id: "student-courses", label: "Courses", to: "/student/dashboard" },
    { id: "student-saved",  label: "Saved Courses", to: "/student/saved"} ,
    { id: "student-mycourses", label: "My Courses", to: "/student/mycourses" },
  ];

  return (
    <div className="student-sidebar">
      <h2>UniConnect</h2>
      <nav>
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              <NavLink
                to={item.to}
                className={({ isActive }) =>
                  isActive ? "student-sidebar-link active" : "student-sidebar-link"
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