import React from "react";
import "./CourseCard.css";

export default function CourseCard({
  course,
  isSaved,
  isPurchased,
  onSave,
  onStart,
}) {
  const embedUrl = course.videoId
    ? `https://www.youtube.com/embed/${course.videoId}`
    : null;

  return (
    <div className="course-card">
      {/* ---------------- VIDEO SECTION ---------------- */}
      {embedUrl &&
        (isPurchased ? (
          <iframe
            src={embedUrl}
            title={course.title}
            frameBorder="0"
            allowFullScreen
            width="100%"
            height="200"
          />
        ) : (
          <div className="locked-video">
            <div className="lock-icon">🔒</div>
            <p>Purchase this course to unlock video</p>
          </div>
        ))}

      {/* ---------------- INFO ---------------- */}
      <div className="course-info">
        <h3>{course.title}</h3>

        {course.description && <p>{course.description}</p>}

        <p>Price: {course.price} Birr</p>

        {course.expertName && (
          <p>
            <strong>Expert:</strong> {course.expertName}
          </p>
        )}
      </div>

      {/* ---------------- ACTIONS ---------------- */}
      <div className="course-actions">
        {/* SAVE BUTTON ALWAYS */}
        <button onClick={onSave}>
          {isSaved ? "Saved ❤️ (Remove)" : "Save for Later"}
        </button>

        {/* START BUTTON ONLY IF NOT PURCHASED */}
        {!isPurchased && <button onClick={onStart}>Start Learning</button>}

        {/* OPTIONAL: show continue if purchased */}
        {isPurchased && <button disabled>Already Purchased ✔</button>}
      </div>
    </div>
  );
}
