import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/useAuth";

const FALLBACK_AVATAR =
  "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

export default function EditProfile() {
  const navigate = useNavigate();
  const { user, updateProfile } = useAuth();

  const initialName = useMemo(() => {
    if (user?.profile?.fullName) return user.profile.fullName;
    return "";
  }, [user]);

  const [name, setName] = useState(initialName);
  const [username, setUsername] = useState(user?.profile?.username || "");
  const [bio, setBio] = useState(user?.profile?.bio || "");
  const [imagePreview, setImagePreview] = useState(
    user?.profile?.profileImage || FALLBACK_AVATAR
  );
  const [imageFile, setImageFile] = useState(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    setName(initialName);
    setUsername(user?.profile?.username || "");
    setBio(user?.profile?.bio || "");
    setImagePreview(user?.profile?.profileImage || FALLBACK_AVATAR);
  }, [initialName, user]);

  const handleImageChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const handleSave = async () => {
    setSaving(true);
    setError("");

    try {
      const payload = new FormData();
      if (name.trim()) payload.append("name", name.trim());
      if (username.trim()) payload.append("username", username.trim());
      if (bio.trim()) payload.append("bio", bio.trim());
      if (imageFile) payload.append("profileImage", imageFile);

      await updateProfile(payload);
      navigate("/profile");
    } catch (err) {
      setError(err.message || "Failed to update profile");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 dark:bg-slate-900 p-6">
      <div className="bg-white p-6 rounded-xl shadow w-full max-w-md">
        <h2 className="text-xl font-bold mb-4">Edit Profile</h2>

        {error ? (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        ) : null}

        <div className="flex flex-col items-center mb-6">
          <div className="w-28 h-28 rounded-full overflow-hidden border-4 border-blue-500">
            <img
              src={imagePreview}
              alt="Profile"
              className="w-full h-full object-cover"
            />
          </div>

          <label className="mt-3 cursor-pointer bg-blue-500 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-600 transition">
            Upload Photo
            <input
              type="file"
              accept="image/*"
              onChange={handleImageChange}
              className="hidden"
            />
          </label>

          <p className="text-xs text-gray-500 mt-1">
            JPG, PNG or GIF. Max size 5MB.
          </p>
        </div>

        <input
          placeholder="Full name"
          className="w-full mb-3 p-2 border rounded"
          value={name}
          onChange={(event) => setName(event.target.value)}
        />

        <input
          placeholder="Username"
          className="w-full mb-3 p-2 border rounded"
          value={username}
          onChange={(event) => setUsername(event.target.value)}
        />

        <textarea
          placeholder="Bio"
          className="w-full mb-3 p-2 border rounded min-h-28"
          value={bio}
          onChange={(event) => setBio(event.target.value)}
        />

        <button
          onClick={handleSave}
          disabled={saving}
          className="w-full bg-blue-500 text-white py-2 rounded disabled:opacity-60"
        >
          {saving ? "Saving..." : "Save Changes"}
        </button>

        <button
          onClick={() => navigate("/profile")}
          className="w-full mt-2 text-gray-500"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}
