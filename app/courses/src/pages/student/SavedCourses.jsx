import React, { useEffect, useState } from "react";
import StudentSidebar from "../../assets/components/StudentSidebar";
import CourseCard from "./CourseCard";
import "./StudentDashboard.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function SavedCourses() {
  const [savedCourses, setSavedCourses] = useState([]);
  const [purchases, setPurchases] = useState([]);

  // ----------------------------
  // FETCH SAVED COURSES
  // ----------------------------
  const fetchSavedCourses = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/saved-courses`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      setSavedCourses(data.data);
    } catch (err) {
      alert(err.message);
    }
  };

  // ----------------------------
  // FETCH PURCHASES
  // ----------------------------
  const fetchPurchases = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/payments/my-courses`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      setPurchases(data.data.map((p) => p.courseId));
    } catch (err) {
      console.log(err.message);
    }
  };

  useEffect(() => {
    fetchSavedCourses();
    fetchPurchases();
  }, []);

  // ----------------------------
  // REMOVE SAVED COURSE
  // ----------------------------
  const handleRemove = async (courseId) => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/saved-courses/${courseId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message);

      setSavedCourses((prev) =>
        prev.filter((item) => item.course.id !== courseId),
      );
    } catch (err) {
      alert(err.message);
    }
  };

  // ----------------------------
  // START LEARNING / PAYMENT
  // ----------------------------
  const handleStartLearning = async (courseId) => {
    const isPurchased = purchases.includes(courseId);

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

  // ----------------------------
  // UI
  // ----------------------------
  return (
    <div className="student-dashboard-page">
      <StudentSidebar />

      <div className="dashboard-main">
        <div className="student-header">
          <div>
            <p className="eyebrow">Student Hub</p>
            <h1>Saved Courses</h1>
            <p className="subtext">Courses you saved for later</p>
          </div>
        </div>

        {savedCourses.length === 0 ? (
          <p>No saved courses yet.</p>
        ) : (
          <div className="courses-grid">
            {savedCourses.map((item) => {
              const courseId = item.course.id;
              const isPurchased = purchases.includes(courseId);

              return (
                <CourseCard
                  key={courseId}
                  course={{
                    id: courseId,
                    title: item.course.title,
                    description: item.course.description,
                    price: item.course.price,
                    videoId: item.course.videoId,
                    expertName: item.course.expert
                      ? `${item.course.expert.firstName} ${item.course.expert.lastName}`
                      : "Unknown",
                  }}
                  isSaved={true}
                  isPurchased={isPurchased}
                  onSave={() => handleRemove(courseId)}
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
