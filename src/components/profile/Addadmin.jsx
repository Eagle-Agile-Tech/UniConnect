import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/useAuth";

export default function AddAdmin() {
  const navigate = useNavigate();
  const { createAdmin } = useAuth();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleAdd = async () => {
    setSubmitting(true);
    setError("");
    setSuccess("");

    try {
      await createAdmin({
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password,
      });
      setSuccess("New admin created successfully.");
      setTimeout(() => navigate("/profile"), 900);
    } catch (err) {
      setError(err.message || "Failed to create admin");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 dark:bg-slate-900 p-6">
      <div className="bg-white p-6 rounded-xl shadow w-full max-w-md">
        <h2 className="text-xl font-bold mb-4">Add New Admin</h2>

        {error ? (
          <div className="mb-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        ) : null}

        {success ? (
          <div className="mb-3 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
            {success}
          </div>
        ) : null}

        <input
          placeholder="Admin name"
          className="w-full mb-3 p-2 border rounded"
          value={name}
          onChange={(event) => setName(event.target.value)}
        />

        <input
          placeholder="Admin email"
          className="w-full mb-3 p-2 border rounded"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />

        <input
          type="password"
          placeholder="Temporary password"
          className="w-full mb-3 p-2 border rounded"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />

        <button
          onClick={handleAdd}
          disabled={submitting}
          className="w-full bg-green-500 text-white py-2 rounded disabled:opacity-60"
        >
          {submitting ? "Creating..." : "Add Admin"}
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
