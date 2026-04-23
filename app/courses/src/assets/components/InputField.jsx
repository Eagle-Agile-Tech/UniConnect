import React from "react";

export default function InputField({ label, ...props }) {
  return (
    <label className="input-field">
      <span className="input-label">{label}</span>
      <input className="input-control" {...props} />
    </label>
  );
}
