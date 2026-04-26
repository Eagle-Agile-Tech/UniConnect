import React, { useState } from "react";
import { motion } from "framer-motion";
import { Eye, EyeOff } from "lucide-react";
import { loginInstitution } from "../lib/institutionApi";

export default function SignIn({ onGoToRegister, onSignInSuccess }) {
  const [form, setForm] = useState({
    email: "",
    password: "",
  });

  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
    setError("");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!form.email.trim() || !form.password) {
      setError("Please fill all fields.");
      return;
    }

    setIsSubmitting(true);
    setError("");

    try {
      const payload = {
        email: form.email.trim().toLowerCase(),
        password: form.password,
      };
      const response = await loginInstitution(payload);
      onSignInSuccess?.({
        email: payload.email,
        accessToken: response?.accessToken || null,
        institutionId: response?.INSTITUTION?.id || null,
      });
    } catch (err) {
      setError(err.message || "Sign-in failed");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FFFFFFFF] flex items-center justify-center px-4 py-10">
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-md rounded-3xl bg-white shadow-2xl border border-black p-6 sm:p-8"
      >
        <h1 className="text-2xl sm:text-3xl font-semibold text-black mb-6 text-center">
          Sign In
        </h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <InputField
            name="email"
            type="email"
            placeholder="Institution Email"
            value={form.email}
            onChange={handleChange}
          />

          <div className="relative">
            <InputField
              name="password"
              type={showPassword ? "text" : "password"}
              placeholder="Password"
              value={form.password}
              onChange={handleChange}
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              className="absolute right-3 top-3 text-gray-400 hover:text-black"
            >
              {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>

          {error ? <p className="text-red-400 text-sm text-center">{error}</p> : null}

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 rounded-full bg-[#6750A4] text-white font-medium shadow-lg hover:scale-[1.02] transition disabled:opacity-60"
          >
            {isSubmitting ? "Signing in..." : "Sign In"}
          </button>

          <p className="text-center text-sm text-gray-600 mt-4">
            Don't have an account?{" "}
            <button
              type="button"
              onClick={onGoToRegister}
              className="text-[#6750A4] font-medium hover:underline"
            >
              Register
            </button>
          </p>
        </form>
      </motion.div>
    </div>
  );
}

function InputField({ name, type = "text", placeholder, value, onChange }) {
  return (
    <input
      name={name}
      type={type}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      className="w-full px-4 py-3 rounded-xl bg-white border border-black text-black text-sm placeholder:text-gray-500 focus:outline-none focus:border-[#ff6600] transition"
    />
  );
}
