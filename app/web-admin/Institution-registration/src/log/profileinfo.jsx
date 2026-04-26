import React, { useState } from "react";
import { Upload, Camera } from "lucide-react";
import {
  submitInstitutionVerification,
  updateInstitutionProfile,
} from "../lib/institutionApi";

export default function AcademicProfile({ institutionId, accessToken, onProfileSaved }) {
  const [logo, setLogo] = useState(null);
  const [logoPreview, setLogoPreview] = useState(null);
  const [document, setDocument] = useState(null);
  const [bio, setBio] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setLogo(file);
      setLogoPreview(URL.createObjectURL(file));
      setError("");
      setSuccess("");
    }
  };

  const handleSubmit = async () => {
    if (!institutionId || !accessToken) {
      setError("Session expired. Please sign in again.");
      return;
    }

    if (!bio.trim() && !document) {
      setError("Add institution bio or upload a verification document.");
      return;
    }

    setIsSubmitting(true);
    setError("");
    setSuccess("");

    try {
      if (bio.trim()) {
        await updateInstitutionProfile(
          institutionId,
          {
            description: bio.trim(),
          },
          accessToken
        );
      }

      if (document) {
        await submitInstitutionVerification(
          institutionId,
          { file: document },
          accessToken
        );
      }

      setSuccess("Profile saved successfully.");
      onProfileSaved?.();
    } catch (err) {
      setError(err.message || "Failed to save profile");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="w-full max-w-md mx-auto p-4 mt-20 bg-white rounded-2xl shadow">
      <h2 className="text-xl font-semibold text-gray-800 mb-4">
        Institution Profile
      </h2>

      <div className="flex flex-col items-center mb-6">
        <label className="cursor-pointer">
          <div className="w-28 h-28 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
            {logoPreview ? (
              <img
                src={logoPreview}
                alt="logo"
                className="w-full h-full object-cover"
              />
            ) : (
              <span className="text-gray-400 text-3xl">L</span>
            )}
          </div>

          <input
            type="file"
            accept="image/*"
            hidden
            onChange={handleLogoChange}
          />
        </label>

        <label className="mt-3 flex items-center gap-2 px-4 py-2 rounded-full bg-gray-100 text-gray-600 text-sm cursor-pointer hover:bg-gray-200 transition">
          <Camera size={16} />
          Pick Institution logo
          <input
            type="file"
            accept="image/*"
            hidden
            onChange={handleLogoChange}
          />
        </label>

        {logo ? (
          <p className="text-xs text-gray-500 mt-2">{logo.name}</p>
        ) : null}
      </div>

      <div className="mb-4">
        <label className="text-sm text-gray-500">Verification Document</label>

        <label className="mt-2 flex items-center justify-between px-4 py-3 border border-gray-300 rounded-xl cursor-pointer hover:border-[#6750A4] transition">
          <span className="text-sm text-gray-500">
            {document ? document.name : "Upload Document"}
          </span>
          <Upload size={18} className="text-gray-400" />

          <input
            type="file"
            hidden
            onChange={(e) => {
              const selected = e.target.files?.[0] || null;
              setDocument(selected);
              setError("");
              setSuccess("");
            }}
          />
        </label>
      </div>

      <div className="mb-6">
        <label className="text-sm text-gray-500">Institution Bio</label>
        <textarea
          value={bio}
          onChange={(e) => {
            setBio(e.target.value);
            setError("");
            setSuccess("");
          }}
          placeholder="Write something about your institution..."
          rows="2"
          className="w-full mt-2 px-4 py-3 rounded-xl border border-gray-300 bg-gray-50 text-sm focus:outline-none focus:border-[#6750A4]"
        />
      </div>

      {error ? <p className="text-red-500 text-sm text-center mb-3">{error}</p> : null}
      {success ? <p className="text-green-600 text-sm text-center mb-3">{success}</p> : null}

      <button
        onClick={handleSubmit}
        disabled={isSubmitting}
        className="w-full py-3 rounded-full bg-[#6750A4] text-white font-medium hover:scale-[1.02] transition disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Create Profile"}
      </button>
    </div>
  );
}
