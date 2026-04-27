const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api"
).replace(/\/$/, "");

const ACCESS_TOKEN_KEY = "adminAccessToken";
const REFRESH_TOKEN_KEY = "adminRefreshToken";
const USER_KEY = "adminUser";

export function getStoredAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getStoredRefreshToken() {
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function getStoredUser() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function storeAdminSession({ accessToken, refreshToken, user }) {
  if (accessToken) localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
  if (refreshToken) localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearAdminSession() {
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

function buildHeaders({ token, headers, isFormData }) {
  const nextHeaders = new Headers(headers || {});

  if (!isFormData && !nextHeaders.has("Content-Type")) {
    nextHeaders.set("Content-Type", "application/json");
  }

  if (token) {
    nextHeaders.set("Authorization", `Bearer ${token}`);
  }

  return nextHeaders;
}

async function parseResponse(response) {
  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    const message =
      (typeof payload === "object" && payload?.message) ||
      (typeof payload === "object" && payload?.error) ||
      (typeof payload === "string" && payload) ||
      "Request failed";

    const error = new Error(message);
    error.status = response.status;
    error.payload = payload;
    throw error;
  }

  return payload;
}

async function request(path, options = {}) {
  const { token, body, headers, method = "GET" } = options;
  const isFormData = body instanceof FormData;

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: buildHeaders({ token, headers, isFormData }),
    body: body
      ? isFormData
        ? body
        : JSON.stringify(body)
      : undefined,
  });

  return parseResponse(response);
}

export async function loginAdmin(credentials) {
  return request("/admin/login", {
    method: "POST",
    body: credentials,
  });
}

export async function refreshAdminSession(refreshToken) {
  return request("/admin/refresh", {
    method: "POST",
    body: { refreshToken },
  });
}

export async function logoutAdmin(refreshToken) {
  return request("/admin/logout", {
    method: "POST",
    body: { refreshToken },
  });
}

export async function getAdminProfile(token) {
  return request("/admin/profile", { token });
}

export async function updateAdminProfile(token, payload) {
  const body =
    payload instanceof FormData ? payload : JSON.stringify(payload);

  return request("/admin/profile", {
    method: "PATCH",
    token,
    body: payload instanceof FormData ? payload : JSON.parse(body),
  });
}

export async function createAdmin(token, payload) {
  return request("/admin/create", {
    method: "POST",
    token,
    body: payload,
  });
}

export async function getDashboardStats(token) {
  return request("/admin/dashboard/stats", { token });
}

export async function getModerationQueue(token, params = {}) {
  const search = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      search.set(key, String(value));
    }
  });

  const suffix = search.size ? `?${search.toString()}` : "";
  return request(`/admin/moderation/queue${suffix}`, { token });
}

export async function moderateContent(token, payload) {
  return request("/admin/moderation", {
    method: "POST",
    token,
    body: payload,
  });
}

export async function getUnverifiedUsers(token, params = {}) {
  const search = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      search.set(key, String(value));
    }
  });

  const suffix = search.size ? `?${search.toString()}` : "";
  return request(`/admin/users/unverified${suffix}`, { token });
}

export async function verifyAccount(token, userId, payload) {
  return request(`/admin/users/${userId}/verify`, {
    method: "PATCH",
    token,
    body: payload,
  });
}
