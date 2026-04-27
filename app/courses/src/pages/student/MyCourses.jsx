import React, { useEffect, useState } from "react";
import StudentSidebar from "../../assets/components/StudentSidebar";
import CourseCard from "./CourseCard";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function MyCourses() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchMyCourses = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/payments/my-courses`, {
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

  useEffect(() => {
    fetchMyCourses();
  }, []);

  return (
    <div className="student-dashboard-page">
      <StudentSidebar />

      <div className="dashboard-main">
        <h1>My Courses</h1>
        <p>Courses you have purchased</p>

        {loading ? (
          <p>Loading...</p>
        ) : courses.length === 0 ? (
          <p>No purchased courses yet.</p>
        ) : (
          <div className="courses-grid">
            {courses.map((item) => (
              <CourseCard
                key={item.id}
                course={{
                  ...item.course,
                  expertName: item.course.expert
                    ? `${item.course.expert.firstName} ${item.course.expert.lastName}`
                    : "Unknown",
                }}
                isSaved={false}
                isPurchased={true}
                onSave={() => {}}
                onStart={() => {
                  alert("Continue learning");
                }}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
