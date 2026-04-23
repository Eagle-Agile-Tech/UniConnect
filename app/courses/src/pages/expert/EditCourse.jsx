import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Sidebar from "../../assets/components/Sidebar";
import "./UploadCourse.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function EditCourse() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [price, setPrice] = useState("");
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(true);
  const [error, setError] = useState(null);

  const getYouTubeId = (url) => {
    const match = url.match(/(?:v=|\.be\/)([^&]+)/);
    return match ? match[1] : null;
  };

  // ✅ FETCH COURSE DATA WITH BETTER ERROR HANDLING
  useEffect(() => {
    const fetchCourse = async () => {
      try {
        setFetching(true);
        setError(null);

        const token = localStorage.getItem("token");

        if (!token) {
          throw new Error("No authentication token found. Please login again.");
        }

        console.log("Fetching course with ID:", id);

        const res = await fetch(`${API_BASE_URL}/api/courses/${id}`, {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });

        const data = await res.json();
        console.log("Response:", data);

        if (!res.ok) {
          throw new Error(data.message || "Failed to fetch course");
        }

        if (!data.success || !data.data) {
          throw new Error("Course data not found");
        }

        const course = data.data;

        // Populate form fields
        setTitle(course.title || "");
        setDescription(course.description || "");
        setVideoUrl(
          course.videoId
            ? `https://www.youtube.com/watch?v=${course.videoId}`
            : "",
        );
        setPrice(course.price?.toString() || "");
      } catch (err) {
        console.error("Fetch error:", err);
        setError(err.message);
        alert("❌ " + err.message);

        // If unauthorized, redirect to login
        if (
          err.message.includes("token") ||
          err.message.includes("Unauthorized")
        ) {
          navigate("/login");
        }
      } finally {
        setFetching(false);
      }
    };

    if (id) {
      fetchCourse();
    }
  }, [id, navigate]);

  // ✅ UPDATE COURSE
  const handleUpdate = async (e) => {
    e.preventDefault();

    const videoId = getYouTubeId(videoUrl);

    if (!videoId) {
      alert("❌ Invalid YouTube URL. Please enter a valid YouTube video URL.");
      return;
    }

    if (!title.trim()) {
      alert("❌ Please enter a course title");
      return;
    }

    if (!description.trim()) {
      alert("❌ Please enter a course description");
      return;
    }

    if (!price || price <= 0) {
      alert("❌ Please enter a valid price");
      return;
    }

    try {
      setLoading(true);

      const token = localStorage.getItem("token");

      if (!token) {
        throw new Error("No authentication token found");
      }

      const res = await fetch(`${API_BASE_URL}/api/courses/${id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          title: title.trim(),
          description: description.trim(),
          videoId,
          price: Number(price),
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Failed to update course");
      }

      alert("✅ Course updated successfully!");
      navigate("/dashboard");
    } catch (err) {
      console.error("Update error:", err);
      alert("❌ " + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Loading state
  if (fetching) {
    return (
      <div className="upload-course-page">
        <Sidebar />
        <div className="upload-course-main">
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Loading course data...</p>
          </div>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="upload-course-page">
        <Sidebar />
        <div className="upload-course-main">
          <div className="error-container">
            <h2>Error Loading Course</h2>
            <p>{error}</p>
            <button onClick={() => navigate("/dashboard")} className="back-btn">
              Back to Dashboard
            </button>
          </div>
        </div>
      </div>
    );
  }

  const videoId = getYouTubeId(videoUrl);

  return (
    <div className="upload-course-page">
      <Sidebar />

      <div className="upload-course-main">
        <div className="page-header">
          <button onClick={() => navigate("/dashboard")} className="back-btn">
            ← Back
          </button>
          <h1>Edit Course</h1>
        </div>

        <form className="upload-form" onSubmit={handleUpdate}>
          <div className="form-group">
            <label>Course Title *</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter course title"
              required
            />
          </div>

          <div className="form-group">
            <label>Description *</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Enter course description"
              rows="5"
              required
            />
          </div>

          <div className="form-group">
            <label>YouTube Video URL *</label>
            <input
              type="text"
              value={videoUrl}
              onChange={(e) => setVideoUrl(e.target.value)}
              placeholder="https://www.youtube.com/watch?v=..."
              required
            />
            <small>Example: https://www.youtube.com/watch?v=dQw4w9WgXcQ</small>
          </div>

          <div className="form-group">
            <label>Price (Birr) *</label>
            <input
              type="number"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="0"
              min="0"
              step="1"
              required
            />
          </div>

          {videoId && (
            <div className="video-preview">
              <p>📹 Video Preview:</p>
              <div className="video-wrapper">
                <iframe
                  width="100%"
                  height="300"
                  src={`https://www.youtube.com/embed/${videoId}`}
                  title="Course Preview"
                  frameBorder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                />
              </div>
            </div>
          )}

          <div className="form-actions">
            <button
              type="button"
              onClick={() => navigate("/dashboard")}
              className="cancel-btn"
            >
              Cancel
            </button>
            <button type="submit" disabled={loading} className="submit-btn">
              {loading ? "Updating..." : "Update Course"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
