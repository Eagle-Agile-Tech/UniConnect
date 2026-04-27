const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api").replace(/\/$/, "");

function getErrorMessage(payload, fallback) {
  if (!payload) return fallback;
  if (typeof payload.message === "string" && payload.message.trim()) return payload.message;
  if (Array.isArray(payload.errors) && payload.errors.length > 0) {
    const first = payload.errors[0];
    if (typeof first?.message === "string" && first.message.trim()) return first.message;
  }
  return fallback;
}

async function request(path, options = {}, fallbackMessage = "Request failed") {
  const response = await fetch(`${API_BASE_URL}${path}`, options);
  let payload = null;
  try {
    payload = await response.json();
  } catch {
    payload = null;
  }

  if (!response.ok) {
    throw new Error(getErrorMessage(payload, fallbackMessage));
  }
  return payload;
}

export async function registerInstitution(data) {
  return request(
    "/institutions",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    },
    "Failed to register institution"
  );
}

export async function verifyInstitutionOtp(data) {
  return request(
    "/institutions/verify-otp",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    },
    "OTP verification failed"
  );
}

export async function resendInstitutionOtp(data) {
  return request(
    "/institutions/resend-otp",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    },
    "Failed to resend OTP"
  );
}

export async function loginInstitution(data) {
  return request(
    "/institutions/login",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    },
    "Institution login failed"
  );
}

export async function updateInstitutionProfile(institutionId, data, accessToken) {
  return request(
    `/institutions/${institutionId}`,
    {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(data),
    },
    "Failed to update institution profile"
  );
}

export async function submitInstitutionVerification(institutionId, data, accessToken) {
  const formData = new FormData();
  if (data?.file) {
    formData.append("verificationDocument", data.file);
  }
  if (data?.documentUrl) {
    formData.append("documentUrl", data.documentUrl);
  }

  return request(
    `/institutions/${institutionId}/verification`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      body: formData,
    },
    "Failed to submit institution verification"
  );
}
