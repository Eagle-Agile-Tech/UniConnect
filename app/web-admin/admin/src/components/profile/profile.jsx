import { useNavigate } from "react-router-dom";
import { useState } from "react";

export default function EditProfile() {
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [image, setImage] = useState(null);

  // Handle image upload
  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImage(URL.createObjectURL(file));
    }
  };

  const handleSave = () => {
    console.log({
      name,
      email,
      image,
    });

    navigate("/dashboard/profile");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 dark:bg-slate-900 p-6">
      <div className="bg-white p-6 rounded-xl shadow w-full max-w-md">

        <h2 className="text-xl font-bold mb-4">Edit Profile</h2>

        {/* PROFILE IMAGE SECTION */}
        <div className="flex flex-col items-center mb-6">
          
          <div className="w-28 h-28 rounded-full overflow-hidden border-4 border-blue-500">
            <img
              src={
                image ||
                "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"
              }
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

        {/* NAME */}
        <input
          placeholder="Name"
          className="w-full mb-3 p-2 border rounded"
          onChange={(e) => setName(e.target.value)}
        />

        {/* EMAIL */}
        <input
          placeholder="Email"
          className="w-full mb-3 p-2 border rounded"
          onChange={(e) => setEmail(e.target.value)}
        />

        {/* SAVE BUTTON */}
        <button
          onClick={handleSave}
          className="w-full bg-blue-500 text-white py-2 rounded"
        >
          Save Changes
        </button>

        {/* CANCEL */}
        <button
          onClick={() => navigate("/dashboard/profile")}
          className="w-full mt-2 text-gray-500"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}