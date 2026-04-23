import React, { useState } from "react";
import Sidebar from "../../assets/components/Sidebar";
import "./UploadCourse.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export default function UploadCourse() {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [price, setPrice] = useState("");
  const [loading, setLoading] = useState(false);

  const getYouTubeId = (url) => {
    const match = url.match(/(?:v=|\.be\/)([^&]+)/);
    return match ? match[1] : null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const videoId = getYouTubeId(videoUrl);

    if (!videoId) {
      alert("Please enter a valid YouTube URL");
      return;
    }

    try {
      setLoading(true);

      const res = await fetch(`${API_BASE_URL}/api/courses`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
        body: JSON.stringify({
          title,
          description,
          videoId,
          price: Number(price),
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || "Upload failed");
      }

      alert("✅ Course uploaded successfully!");

      // Reset form
      setTitle("");
      setDescription("");
      setVideoUrl("");
      setPrice("");
    } catch (err) {
      alert("❌ " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const videoId = getYouTubeId(videoUrl);

  return (
    <div className="upload-course-page">
      <Sidebar />

      <div className="upload-course-main">
        <h1>Upload a New Course</h1>

        <form className="upload-form" onSubmit={handleSubmit}>
          <label>Course Title</label>
          <input
            type="text"
            placeholder="Enter course title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
          />

          <label>Description</label>
          <textarea
            placeholder="Enter course description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
          />

          <label>YouTube Video URL</label>
          <input
            type="text"
            placeholder="Paste YouTube link"
            value={videoUrl}
            onChange={(e) => setVideoUrl(e.target.value)}
            required
          />

          <label>Price</label>
          <input
            type="number"
            min="0"
            step="0.01"
            placeholder="Enter price"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            required
          />

          {videoId && (
            <div style={{ marginTop: "20px" }}>
              <p>Video Preview:</p>
              <iframe
                width="100%"
                height="300"
                src={`https://www.youtube.com/embed/${videoId}`}
                title="Preview"
                frameBorder="0"
                allowFullScreen
              />
            </div>
          )}

          <button type="submit" disabled={loading}>
            {loading ? "Uploading..." : "Upload Course"}
          </button>
        </form>
      </div>
    </div>
  );
}
