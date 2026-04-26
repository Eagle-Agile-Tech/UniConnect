import React, { useEffect, useState } from "react";
import Register from "./log/register";
import Signin from "./log/singin";
import OTPVerification from "./log/otp";
import ProfileInfo from "./log/profileinfo";

const FLOW_STORAGE_KEY = "institution_registration_flow";
const VALID_STEPS = new Set(["register", "signin", "otp", "profileinfo"]);

function readInitialFlow() {
  try {
    const raw = localStorage.getItem(FLOW_STORAGE_KEY);
    if (!raw) return { step: "register", email: "", accessToken: "", institutionId: "" };

    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      return { step: "register", email: "", accessToken: "", institutionId: "" };
    }

    const step = VALID_STEPS.has(parsed.step) ? parsed.step : "register";
    return {
      step,
      email: parsed.email || "",
      accessToken: parsed.accessToken || "",
      institutionId: parsed.institutionId || "",
    };
  } catch {
    return { step: "register", email: "", accessToken: "", institutionId: "" };
  }
}

function App() {
  const [flow, setFlow] = useState(readInitialFlow);

  useEffect(() => {
    localStorage.setItem(FLOW_STORAGE_KEY, JSON.stringify(flow));
  }, [flow]);

  useEffect(() => {
    if (flow.step === "otp" && !flow.email) {
      setFlow((prev) => ({ ...prev, step: "register" }));
      return;
    }

    if (flow.step === "profileinfo" && (!flow.accessToken || !flow.institutionId)) {
      setFlow((prev) => ({ ...prev, step: prev.email ? "signin" : "register" }));
    }
  }, [flow.step, flow.email, flow.accessToken, flow.institutionId]);

  const goToRegister = () => {
    setFlow((prev) => ({ ...prev, step: "register" }));
  };

  const goToSignIn = () => {
    setFlow((prev) => ({ ...prev, step: "signin" }));
  };

  const handleRegisterSuccess = ({ email, accessToken, institutionId }) => {
    setFlow((prev) => ({
      ...prev,
      step: "otp",
      email: email || prev.email,
      accessToken: accessToken || prev.accessToken,
      institutionId: institutionId || prev.institutionId,
    }));
  };

  const handleOtpSuccess = ({ accessToken, institutionId }) => {
    setFlow((prev) => ({
      ...prev,
      step: "profileinfo",
      accessToken: accessToken || prev.accessToken,
      institutionId: institutionId || prev.institutionId,
    }));
  };

  const handleSignInSuccess = ({ email, accessToken, institutionId }) => {
    setFlow((prev) => ({
      ...prev,
      step: "profileinfo",
      email: email || prev.email,
      accessToken: accessToken || prev.accessToken,
      institutionId: institutionId || prev.institutionId,
    }));
  };

  return (
    <div>
      {flow.step === "register" && (
        <Register
          onRegisterSuccess={handleRegisterSuccess}
          onGoToSignIn={goToSignIn}
        />
      )}

      {flow.step === "signin" && (
        <Signin
          onGoToRegister={goToRegister}
          onSignInSuccess={handleSignInSuccess}
        />
      )}

      {flow.step === "otp" && (
        <OTPVerification
          email={flow.email}
          onVerifySuccess={handleOtpSuccess}
        />
      )}

      {flow.step === "profileinfo" && (
        <ProfileInfo
          institutionId={flow.institutionId}
          accessToken={flow.accessToken}
        />
      )}
    </div>
  );
}

export default App;
