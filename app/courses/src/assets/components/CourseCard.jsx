import React from "react";
import "./CourseCard.css";

export default function CourseCard({ course, onEdit }) {
  return (
    <div className="course-card">
      {/* Title Section */}
      <div className="course-header">
        <h3 className="course-title">{course.title}</h3>
        {course.level && (
          <span className={`course-level level-${course.level.toLowerCase()}`}>
            {course.level}
          </span>
        )}
      </div>

      {/* Description */}
      {course.description && (
        <div className="course-description-wrapper">
          <p className="course-desc">{course.description}</p>
        </div>
      )}

      {/* Meta Info - Redesigned */}
      <div className="course-info-grid">
        <div className="info-card">
          <div className="info-icon">👥</div>
          <div className="info-content">
            <span className="label">Total Students</span>
            <span className="value">
              {course.students?.toLocaleString() || 0}
            </span>
          </div>
        </div>

        <div className="info-card">
          <div className="info-icon">💰</div>
          <div className="info-content">
            <span className="label">Course Price</span>
            <span className="value price-value">{course.price || 0} Birr</span>
          </div>
        </div>

        {course.duration && (
          <div className="info-card">
            <div className="info-icon">⏱️</div>
            <div className="info-content">
              <span className="label">Duration</span>
              <span className="value">{course.duration}</span>
            </div>
          </div>
        )}

        {course.lessons && (
          <div className="info-card">
            <div className="info-icon">📚</div>
            <div className="info-content">
              <span className="label">Lessons</span>
              <span className="value">{course.lessons}</span>
            </div>
          </div>
        )}
      </div>

      {/* Video */}
      {course.videoId && (
        <div className="video-wrapper">
          <div className="video-overlay">
            <iframe
              src={`https://www.youtube.com/embed/${course.videoId}`}
              title={course.title}
              allowFullScreen
            />
          </div>
        </div>
      )}

      {/* Action Buttons */}
      {/* <div className="card-actions">
        <button
          className="edit-btn"
          type="button"
          onClick={() => onEdit?.(course.id)}
          disabled={!onEdit}
        >
          Edit Course
        </button>
      </div> */}
    </div>
  );
}
