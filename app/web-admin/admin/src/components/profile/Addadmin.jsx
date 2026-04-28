import { useNavigate } from "react-router-dom";
import { useState } from "react";

export default function AddAdmin() {
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  const handleAdd = () => {
    console.log("New Admin:", { name, email });
    navigate("/profile");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 dark:bg-slate-900 p-6">
      <div className="bg-white p-6 rounded-xl shadow w-full max-w-md">
        
        <h2 className="text-xl font-bold mb-4">Add New Admin</h2>

        <input
          placeholder="Admin Name"
          className="w-full mb-3 p-2 border rounded"
          onChange={(e) => setName(e.target.value)}
        />

        <input
          placeholder="Admin Email"
          className="w-full mb-3 p-2 border rounded"
          onChange={(e) => setEmail(e.target.value)}
        />

        <button
          onClick={handleAdd}
          className="w-full bg-green-500 text-white py-2 rounded"
        >
          Add Admin
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