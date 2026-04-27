import React, { useState } from "react";
import { motion } from "framer-motion";
import { Eye, EyeOff } from "lucide-react";
import { registerInstitution } from "../lib/institutionApi";

const INSTITUTION_TYPES = [
  { value: "UNIVERSITY", label: "University" },
  { value: "COMPANY", label: "Company" },
  { value: "NGO", label: "NGO" },
  { value: "RESEARCH_CENTER", label: "Research Center" },
  { value: "TRAINING_CENTER", label: "Training Center" },
  { value: "GOVERNMENT", label: "Government" },
  { value: "OTHER", label: "Other" },
];

export default function RegisterInstitution({ onRegisterSuccess, onGoToSignIn }) {
  const [form, setForm] = useState({
    type: "",
    name: "",
    username: "",
    email: "",
    password: "",
    passwordConfirm: "",
  });

  const [errors, setErrors] = useState({});
  const [submitError, setSubmitError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: "" }));
    setSubmitError("");
  };

  const validateForm = () => {
    const nextErrors = {};
    const username = form.username.trim();

    if (!form.type) nextErrors.type = "Select institution type";
    if (!form.name.trim()) nextErrors.name = "Institution name required";
    if (!username) nextErrors.username = "Username required";
    if (!form.email.trim()) nextErrors.email = "Email required";
    if (!form.password) nextErrors.password = "Password required";
    if (!form.passwordConfirm) nextErrors.passwordConfirm = "Confirm your password";

    if (username && !/^[a-zA-Z0-9_]+$/.test(username)) {
      nextErrors.username = "Only letters, numbers, and underscore";
    }
    if (username && (username.length < 3 || username.length > 30)) {
      nextErrors.username = "Username must be 3-30 characters";
    }

    if (form.password && !/[A-Z]/.test(form.password)) {
      nextErrors.password = "Password needs at least one uppercase letter";
    } else if (form.password && !/[a-z]/.test(form.password)) {
      nextErrors.password = "Password needs at least one lowercase letter";
    } else if (form.password && !/[0-9]/.test(form.password)) {
      nextErrors.password = "Password needs at least one number";
    } else if (form.password && !/[^A-Za-z0-9]/.test(form.password)) {
      nextErrors.password = "Password needs at least one special character";
    } else if (form.password && (form.password.length < 8 || form.password.length > 32)) {
      nextErrors.password = "Password must be 8-32 characters";
    }

    if (form.password !== form.passwordConfirm) {
      nextErrors.passwordConfirm = "Passwords do not match";
    }

    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsSubmitting(true);
    setSubmitError("");

    try {
      const payload = {
        type: form.type,
        name: form.name.trim(),
        username: form.username.trim(),
        email: form.email.trim().toLowerCase(),
        password: form.password,
        passwordConfirm: form.passwordConfirm,
      };

      const response = await registerInstitution(payload);
      onRegisterSuccess?.({
        email: payload.email,
        institutionId: response?.INSTITUTION?.id || null,
        accessToken: response?.accessToken || null,
      });
    } catch (err) {
      setSubmitError(err.message || "Registration failed");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center px-4 py-10">
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-md rounded-3xl bg-white shadow-2xl border border-black p-6 sm:p-8"
      >
        <h1 className="text-2xl sm:text-3xl font-semibold text-black mb-6 text-center">
          Institution Registration
        </h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <SelectField
            name="type"
            value={form.type}
            onChange={handleChange}
            options={INSTITUTION_TYPES}
            error={errors.type}
          />

          <InputField
            name="name"
            placeholder="Institution Name"
            value={form.name}
            onChange={handleChange}
            error={errors.name}
          />

          <InputField
            name="username"
            placeholder="Username"
            value={form.username}
            onChange={handleChange}
            error={errors.username}
          />

          <InputField
            name="email"
            type="email"
            placeholder="Institution Email"
            value={form.email}
            onChange={handleChange}
            error={errors.email}
          />

          <div className="relative">
            <InputField
              name="password"
              type={showPassword ? "text" : "password"}
              placeholder="Password"
              value={form.password}
              onChange={handleChange}
              error={errors.password}
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              className="absolute right-3 top-3 text-gray-400"
            >
              {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>

          <div className="relative">
            <InputField
              name="passwordConfirm"
              type={showConfirmPassword ? "text" : "password"}
              placeholder="Confirm Password"
              value={form.passwordConfirm}
              onChange={handleChange}
              error={errors.passwordConfirm}
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword((prev) => !prev)}
              className="absolute right-3 top-3 text-gray-400"
            >
              {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>

          {submitError ? <p className="text-red-500 text-sm text-center">{submitError}</p> : null}

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 rounded-full bg-[#6750A4] text-white font-medium shadow-lg hover:scale-[1.02] transition disabled:opacity-60"
          >
            {isSubmitting ? "Registering..." : "Register"}
          </button>

          <p className="text-center text-sm text-gray-600 mt-4">
            Already have an account?{" "}
            <button
              type="button"
              onClick={onGoToSignIn}
              className="text-[#6750A4] font-medium hover:underline"
            >
              Sign in
            </button>
          </p>
        </form>
      </motion.div>
    </div>
  );
}

function InputField({ name, type = "text", placeholder, value, onChange, error }) {
  return (
    <div>
      <input
        name={name}
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className={`w-full px-4 py-3 rounded-xl text-sm transition outline-none ${
          error
            ? "border border-red-500 bg-red-50 text-red-500 placeholder:text-red-400"
            : "border border-black bg-white text-black placeholder:text-gray-500 focus:border-[#ff6600]"
        }`}
      />
      {error ? <p className="text-red-500 text-xs mt-1">{error}</p> : null}
    </div>
  );
}

function SelectField({ name, value, onChange, options, error }) {
  return (
    <div>
      <select
        name={name}
        value={value}
        onChange={onChange}
        className={`w-full px-4 py-3 rounded-xl text-sm transition outline-none ${
          error
            ? "border-2 border-red-500 bg-red-50 text-red-500"
            : "border-2 border-black bg-white text-black"
        }`}
      >
        <option value="">Select Category</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>

      {error ? <p className="text-red-500 text-xs mt-1">{error}</p> : null}
    </div>
  );
}
