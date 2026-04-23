// src/pages/expert/MyCourses.jsx
import React, { useEffect, useState } from "react";
import Sidebar from "../../assets/components/Sidebar";
import CourseCard from "../../assets/components/CourseCard";
import "./MyCourses.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function MyCourses() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchMyCourses = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/api/courses/my`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Failed to fetch courses");
      }

      const formattedCourses = (data.data || []).map((course) => ({
        ...course,
        students: course._count?.purchases ?? 0,
      }));

      setCourses(formattedCourses);
    } catch (err) {
      console.error(err);
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMyCourses();
  }, []);

  return (
    <div className="my-courses-page">
      <Sidebar />

      <div className="my-courses-main">
        <h1>My Courses</h1>

        {loading ? (
          <p>Loading courses...</p>
        ) : courses.length === 0 ? (
          <p>You haven’t uploaded any courses yet.</p>
        ) : (
          <div className="courses-list">
            {courses.map((course) => (
              <CourseCard
                key={course.id}
                course={{
                  title: course.title,
                  students: course.students || 0,
                  description: course.description,
                  price: course.price,
                  videoId: course.videoId,
                }}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
