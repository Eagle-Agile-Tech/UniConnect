// Dashboard.jsx
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "../../assets/components/Sidebar";
import CourseCard from "../../assets/components/CourseCard";
import "./Dashboard.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function Dashboard() {
  const navigate = useNavigate();
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchCourses = async () => {
    setLoading(true);
    setError(null);

    try {
      const res = await fetch(`${API_BASE_URL}/api/courses/my`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Failed to load courses");
      }

      const courses = (data.data || []).map((course) => ({
        ...course,
        students: course._count?.purchases ?? 0,
      }));

      setCourses(courses);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourses();
  }, []);

  const totalStudents = courses.reduce((acc, c) => acc + (c.students || 0), 0);

  return (
    <div className="expert-dashboard">
      <Sidebar />
      <div className="dashboard-main">
        <div className="dashboard-header">
          <div>
            <p className="eyebrow">Expert Workspace</p>
            <h1>Course Studio</h1>
            <p className="subtext">
              Track enrollments, publish updates, and manage your learning
              content in one place.
            </p>
          </div>
          <button
            className="primary-btn"
            onClick={() => navigate("/expert/upload-course")}
          >
            Create Course
          </button>
        </div>

        <div className="stats">
          <div className="stat-card">
            <span className="stat-label">Courses</span>
            <span className="stat-value">{courses.length}</span>
            <span className="stat-extra">Total created</span>
          </div>

          <div className="stat-card">
            <span className="stat-label">Students</span>
            <span className="stat-value">{totalStudents}</span>
            <span className="stat-extra">Total enrolled</span>
          </div>
        </div>

        <div className="section-header">
          <h2>My Courses</h2>
          <button
            className="ghost-btn"
            onClick={() => navigate("/expert/mycourses")}
          >
            View All
          </button>
        </div>

        {loading ? (
          <p>Loading courses...</p>
        ) : error ? (
          <p className="error-message">{error}</p>
        ) : courses.length === 0 ? (
          <p>No courses found yet.</p>
        ) : (
          <div className="courses">
            {courses.slice(0, 2).map((course, idx) => (
              <CourseCard
                key={course.id || idx}
                course={course}
                onEdit={(courseId) =>
                  navigate(`/expert/edit-course/${courseId}`)
                }
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
