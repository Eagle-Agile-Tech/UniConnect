import React, { useState, useRef } from "react";
import { motion } from "framer-motion";
import { resendInstitutionOtp, verifyInstitutionOtp } from "../lib/institutionApi";

export default function OTPVerification({
  email = "",
  onVerifySuccess,
}) {
  const [otp, setOtp] = useState(["", "", "", ""]);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const inputsRef = useRef([]);

  const handleChange = (value, index) => {
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);
    setError("");
    setMessage("");

    if (value && index < 3) {
      inputsRef.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (e, index) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputsRef.current[index - 1]?.focus();
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const code = otp.join("");

    if (!email) {
      setError("Missing email. Please register again.");
      return;
    }

    if (code.length !== 4) {
      setError("Enter complete OTP");
      return;
    }

    setIsVerifying(true);
    setError("");
    setMessage("");

    try {
      const response = await verifyInstitutionOtp({ email, otp: code });
      onVerifySuccess?.({
        accessToken: response?.accessToken || null,
        institutionId: response?.INSTITUTION?.id || null,
      });
    } catch (err) {
      setError(err.message || "OTP verification failed");
    } finally {
      setIsVerifying(false);
    }
  };

  const handleResend = async () => {
    if (!email) {
      setError("Missing email. Please register again.");
      return;
    }

    setIsResending(true);
    setError("");
    setMessage("");

    try {
      const response = await resendInstitutionOtp({ email });
      setMessage(response?.message || "OTP resent successfully.");
    } catch (err) {
      setError(err.message || "Failed to resend OTP");
    } finally {
      setIsResending(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center px-4">
      <motion.div
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md bg-white border border-black rounded-3xl p-6 sm:p-8 shadow-2xl"
      >
        <h1 className="text-2xl font-semibold text-black text-center">
          Verify OTP
        </h1>

        <p className="text-black text-sm text-center mt-2">
          We have sent a 4-digit code to <br />
          <span className="font-medium">{email || "your email"}</span>
        </p>

        <form onSubmit={handleSubmit} className="mt-10 space-y-6">
          <div className="flex gap-4 justify-center">
            {otp.map((digit, index) => (
              <input
                key={index}
                ref={(el) => {
                  inputsRef.current[index] = el;
                }}
                type="text"
                maxLength="1"
                value={digit}
                onChange={(e) => handleChange(e.target.value, index)}
                onKeyDown={(e) => handleKeyDown(e, index)}
                className="w-14 h-14 text-center text-lg rounded-xl bg-white border border-black text-black focus:outline-none focus:border-[#ff6600] transition"
              />
            ))}
          </div>

          {error ? <p className="text-red-500 text-sm text-center">{error}</p> : null}
          {message ? <p className="text-green-600 text-sm text-center">{message}</p> : null}

          <button
            type="submit"
            disabled={isVerifying}
            className="w-full py-3 mt-10 rounded-full bg-[#6750A4] text-white font-medium hover:scale-[1.02] transition disabled:opacity-60"
          >
            {isVerifying ? "Verifying..." : "Verify"}
          </button>

          <p className="text-center text-sm text-gray-500">
            Didn't receive code?{" "}
            <button
              type="button"
              onClick={handleResend}
              disabled={isResending}
              className="text-[#ff6600] font-medium hover:underline disabled:opacity-60"
            >
              {isResending ? "Resending..." : "Resend"}
            </button>
          </p>
        </form>
      </motion.div>
    </div>
  );
}
