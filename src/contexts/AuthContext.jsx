import React, { useCallback, useEffect, useState } from "react";
import {
  clearAdminSession,
  createAdmin as createAdminRequest,
  getAdminProfile,
  getStoredAccessToken,
  getStoredRefreshToken,
  getStoredUser,
  loginAdmin,
  logoutAdmin as logoutAdminRequest,
  refreshAdminSession,
  storeAdminSession,
  updateAdminProfile as updateAdminProfileRequest,
} from "../lib/adminApi";
import { AuthContext } from "./auth-context";

const normalizeUser = (profile) => ({
  id: profile.id,
  email: profile.email,
  role: profile.role,
  createdAt: profile.createdAt,
  firstName: profile.firstName,
  lastName: profile.lastName,
  profile: profile.profile || null,
});

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getStoredUser());
  const [accessToken, setAccessToken] = useState(getStoredAccessToken());
  const [refreshToken, setRefreshToken] = useState(getStoredRefreshToken());
  const [loading, setLoading] = useState(true);

  const saveSession = ({ nextUser, nextAccessToken, nextRefreshToken }) => {
    setUser(nextUser);
    setAccessToken(nextAccessToken);
    setRefreshToken(nextRefreshToken);
    storeAdminSession({
      user: nextUser,
      accessToken: nextAccessToken,
      refreshToken: nextRefreshToken,
    });
  };

  const clearSession = () => {
    setUser(null);
    setAccessToken(null);
    setRefreshToken(null);
    clearAdminSession();
  };

  const refreshProfile = useCallback(async (tokenOverride) => {
    const token = tokenOverride || accessToken || getStoredAccessToken();
    if (!token) return null;

    const profile = await getAdminProfile(token);
    const normalizedUser = normalizeUser(profile);

    setUser(normalizedUser);
    storeAdminSession({
      user: normalizedUser,
      accessToken: token,
      refreshToken: refreshToken || getStoredRefreshToken(),
    });

    return normalizedUser;
  }, [accessToken, refreshToken]);

  const tryRestoreSession = useCallback(async () => {
    const storedAccessToken = getStoredAccessToken();
    const storedRefreshToken = getStoredRefreshToken();

    if (!storedAccessToken && !storedRefreshToken) {
      clearSession();
      setLoading(false);
      return;
    }

    try {
      if (storedAccessToken) {
        setAccessToken(storedAccessToken);
        setRefreshToken(storedRefreshToken);
        await refreshProfile(storedAccessToken);
      } else if (storedRefreshToken) {
        const refreshed = await refreshAdminSession(storedRefreshToken);
        setAccessToken(refreshed.accessToken);
        setRefreshToken(refreshed.refreshToken);
        storeAdminSession({
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          user: getStoredUser(),
        });
        await refreshProfile(refreshed.accessToken);
      }
    } catch {
      clearSession();
    } finally {
      setLoading(false);
    }
  }, [refreshProfile]);

  useEffect(() => {
    void tryRestoreSession();
  }, [tryRestoreSession]);

  const login = async ({ email, password }) => {
    setLoading(true);
    try {
      const session = await loginAdmin({ email, password });
      const profile = await getAdminProfile(session.accessToken);
      const normalizedUser = normalizeUser(profile);

      saveSession({
        nextUser: normalizedUser,
        nextAccessToken: session.accessToken,
        nextRefreshToken: session.refreshToken,
      });

      return normalizedUser;
    } catch (error) {
      throw new Error(error.message || "Invalid credentials");
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    const token = refreshToken || getStoredRefreshToken();
    try {
      if (token) {
        await logoutAdminRequest(token);
      }
    } catch {
      // Best-effort logout. Client session is still cleared below.
    } finally {
      clearSession();
    }
  };

  const updateProfile = async (payload) => {
    const token = accessToken || getStoredAccessToken();
    if (!token) throw new Error("Not authenticated");

    const updated = await updateAdminProfileRequest(token, payload);
    const normalizedUser = normalizeUser(updated);

    saveSession({
      nextUser: normalizedUser,
      nextAccessToken: token,
      nextRefreshToken: refreshToken || getStoredRefreshToken(),
    });

    return normalizedUser;
  };

  const createAdmin = async (payload) => {
    const token = accessToken || getStoredAccessToken();
    if (!token) throw new Error("Not authenticated");
    return createAdminRequest(token, payload);
  };

  const value = {
    user,
    accessToken,
    refreshToken,
    loading,
    login,
    logout,
    refreshProfile,
    updateProfile,
    createAdmin,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
