import React, { useEffect, useState } from "react";
import StudentSidebar from "../../assets/components/StudentSidebar";
import CourseCard from "./CourseCard";
import "./StudentDashboard.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function StudentDashboard({ user }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [savedCourses, setSavedCourses] = useState([]);
  const [purchases, setPurchases] = useState([]);

  // ---------------- FETCH COURSES ----------------
  const fetchCourses = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/courses`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      setCourses(data.data);
    } catch (err) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  // ---------------- FETCH PURCHASES ----------------
  const fetchPurchases = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/payments/my-courses`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      setPurchases(data.data.map((p) => String(p.courseId)));
    } catch (err) {
      console.log(err.message);
    }
  };

  useEffect(() => {
    fetchCourses();
    fetchPurchases();
  }, []);

  // ---------------- SAVE COURSE ----------------
  const handleToggleSave = async (courseId, isSaved) => {
    const res = await fetch(`${API_BASE_URL}/api/saved-courses/${courseId}`, {
      method: isSaved ? "DELETE" : "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },
      body: isSaved ? null : JSON.stringify({ courseId }),
    });

    const data = await res.json();
    if (!res.ok) return alert(data.message);

    if (isSaved) {
      setSavedCourses((prev) => prev.filter((id) => id !== courseId));
    } else {
      setSavedCourses((prev) => [...prev, courseId]);
    }
  };

  // ---------------- START LEARNING ----------------
  const handleStartLearning = async (courseId) => {
    const isPurchased = purchases.includes(String(courseId));

    if (isPurchased) {
      window.location.href = "/student/mycourses";
      return;
    }

    try {
      const res = await fetch(`${API_BASE_URL}/api/payments/start`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
        body: JSON.stringify({ courseId }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      window.location.href = data.checkout_url;
    } catch (err) {
      alert(err.message);
    }
  };

  // ---------------- UI ----------------
  return (
    <div className="student-dashboard-page">
      <StudentSidebar />

      <div className="dashboard-main">
        <div className="student-header">
          <div>
            <p className="eyebrow">Student Hub</p>
            <h1>Available Courses</h1>
            <p className="subtext">
              {user?.email ? `Welcome back, ${user.email}` : "Browse courses"}
            </p>
          </div>
        </div>

        {loading ? (
          <p>Loading courses...</p>
        ) : (
          <div className="courses-grid">
            {courses.map((course) => {
              const courseId = course.id;
              const isPurchased = purchases.includes(String(courseId));

              return (
                <CourseCard
                  key={courseId}
                  course={{
                    id: courseId,
                    title: course.title,
                    description: course.description,
                    price: course.price,
                    videoId: course.videoId,
                    expertName: course.expert
                      ? `${course.expert.firstName} ${course.expert.lastName}`
                      : "Unknown",
                  }}
                  isSaved={savedCourses.includes(courseId)}
                  isPurchased={isPurchased}
                  onSave={() =>
                    handleToggleSave(courseId, savedCourses.includes(courseId))
                  }
                  onStart={() => handleStartLearning(courseId)}
                />
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
