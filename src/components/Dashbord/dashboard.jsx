import React, { useEffect, useState } from "react";
import ChartSection from "./ChartSection";
import StatusGrid from "./statusGrid";
import { useAuth } from "../../contexts/useAuth";
import { getDashboardStats } from "../../lib/adminApi";

export default function Dashboard() {
  const { accessToken } = useAuth();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function loadStats() {
      if (!accessToken) return;

      setLoading(true);
      setError("");

      try {
        const nextStats = await getDashboardStats(accessToken);
        if (active) {
          setStats(nextStats);
        }
      } catch (err) {
        if (active) {
          setError(err.message || "Failed to load dashboard stats");
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    loadStats();

    return () => {
      active = false;
    };
  }, [accessToken]);

  return (
    <div className="space-y-6">
      <ChartSection />

      {error ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      {loading ? (
        <div className="rounded-2xl bg-white/80 p-6 text-slate-600 shadow">
          Loading dashboard metrics...
        </div>
      ) : (
        <StatusGrid stats={stats} />
      )}

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6" />
    </div>
  );
}
