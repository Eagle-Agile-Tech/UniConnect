'use client';

import React, { useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  CheckCircle,
  Flag,
  Search,
  ShieldAlert,
  XCircle,
} from "lucide-react";
import { useAuth } from "../../contexts/useAuth";
import { getModerationQueue, moderateContent } from "../../lib/adminApi";

function normalizeItems(items, contentType) {
  return (items || []).map((item) => ({
    id: item.id,
    type: contentType.toLowerCase(),
    author: item.author?.email || item.commenter?.email || "Unknown user",
    contentPreview: item.content || "",
    createdAt: item.createdAt,
    status: (item.moderationStatus || "PENDING").toLowerCase(),
  }));
}

export default function ModerationPage() {
  const { accessToken } = useAuth();
  const [allItems, setAllItems] = useState([]);
  const [activeTab, setActiveTab] = useState("pending");
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [submittingId, setSubmittingId] = useState("");

  useEffect(() => {
    let active = true;

    async function loadQueue() {
      if (!accessToken) return;

      setLoading(true);
      setError("");

      try {
        const [posts, comments] = await Promise.all([
          getModerationQueue(accessToken, {
            contentType: "POST",
            status: "PENDING",
            limit: 50,
          }),
          getModerationQueue(accessToken, {
            contentType: "COMMENT",
            status: "PENDING",
            limit: 50,
          }),
        ]);

        if (active) {
          setAllItems([
            ...normalizeItems(posts, "POST"),
            ...normalizeItems(comments, "COMMENT"),
          ]);
        }
      } catch (err) {
        if (active) {
          setError(err.message || "Failed to load moderation queue");
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    loadQueue();

    return () => {
      active = false;
    };
  }, [accessToken]);

  const filteredData = useMemo(() => {
    return allItems.filter((item) => {
      if (activeTab !== "all" && item.status !== activeTab) return false;
      if (!searchTerm) return true;

      const needle = searchTerm.toLowerCase();
      return (
        item.type.toLowerCase().includes(needle) ||
        item.author.toLowerCase().includes(needle) ||
        item.contentPreview.toLowerCase().includes(needle)
      );
    });
  }, [activeTab, allItems, searchTerm]);

  const stats = {
    pending: allItems.filter((item) => item.status === "pending").length,
    approvedToday: allItems.filter((item) => item.status === "approved").length,
    rejected: allItems.filter((item) => item.status === "rejected").length,
    totalReports: allItems.length,
  };

  const handleAction = async (item, action) => {
    setSubmittingId(item.id);
    setError("");

    try {
      await moderateContent(accessToken, {
        contentId: item.id,
        contentType: item.type.toUpperCase(),
        action,
      });

      const nextStatus =
        action === "APPROVE" ? "approved" : action === "REJECT" ? "rejected" : action.toLowerCase();

      setAllItems((current) =>
        current.map((entry) =>
          entry.id === item.id
            ? { ...entry, status: nextStatus }
            : entry
        )
      );
    } catch (err) {
      setError(err.message || "Failed to update moderation status");
    } finally {
      setSubmittingId("");
    }
  };

  const getStatusColor = (status) => {
    if (status === "pending") {
      return "bg-yellow-500 text-black px-3 py-1 rounded-full text-xs font-medium";
    }
    if (status === "approved") {
      return "bg-emerald-500 px-3 py-1 rounded-full text-xs font-medium text-white";
    }
    return "bg-red-500 px-3 py-1 rounded-full text-xs font-medium text-white";
  };

  return (
    <div className="flex-1 p-8 bg-slate-50 dark:bg-slate-900 min-h-screen">
      <div className="max-w-7xl">
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-2">
            <ShieldAlert className="w-10 h-10 text-red-500" />
            <div>
              <h1 className="text-4xl font-bold text-slate-800 dark:text-white">
                Content Moderation
              </h1>
              <p className="text-slate-500 dark:text-slate-400">
                Review pending posts and comments from the backend queue
              </p>
            </div>
          </div>
        </div>

        {error ? (
          <div className="mb-6 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        ) : null}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          {[
            { label: "Pending Review", value: stats.pending, color: "yellow", icon: AlertTriangle },
            { label: "Approved", value: stats.approvedToday, color: "emerald", icon: CheckCircle },
            { label: "Rejected", value: stats.rejected, color: "red", icon: XCircle },
            { label: "Loaded Items", value: stats.totalReports, color: "slate", icon: Flag },
          ].map((stat) => (
            <div
              key={stat.label}
              className="bg-white/70 dark:bg-slate-800/70 backdrop-blur-xl rounded-3xl p-6 border border-slate-200/50 dark:border-slate-700/50 shadow-lg"
            >
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-slate-500 dark:text-slate-400 text-sm font-medium">
                    {stat.label}
                  </p>
                  <p className="text-4xl font-bold mt-2 text-slate-800 dark:text-white">
                    {stat.value}
                  </p>
                </div>
                <div className="w-12 h-12 rounded-2xl p-3 flex items-center justify-center bg-slate-100 dark:bg-slate-700/50">
                  <stat.icon className="w-6 h-6" />
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between mb-5 gap-6">
          <div className="flex border-b border-slate-200 dark:border-slate-700">
            {["all", "pending", "approved", "rejected"].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-6 py-4 font-medium text-sm border-b-2 transition-all ${
                  activeTab === tab
                    ? "border-red-500 text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/50"
                    : "border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300"
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
              </button>
            ))}
          </div>

          <div className="relative w-80 flex-1 min-w-[300px]">
            <Search className="absolute left-4 top-3 text-slate-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search by type, author, or content"
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              className="w-full bg-white/50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 pl-11 py-3 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent backdrop-blur-sm"
            />
          </div>
        </div>

        <div className="bg-white/60 dark:bg-slate-800/60 backdrop-blur-xl rounded-3xl overflow-hidden border border-slate-200/50 dark:border-slate-700/50 shadow-2xl">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700 bg-white/50 dark:bg-slate-700/50 backdrop-blur-sm">
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Type
                  </th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Content
                  </th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Author
                  </th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Created
                  </th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Status
                  </th>
                  <th className="px-8 py-5 text-right text-sm font-semibold text-slate-700 dark:text-slate-300">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200/50 dark:divide-slate-700/50">
                {filteredData.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-all">
                    <td className="px-6 py-5">
                      <span className="px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">
                        {item.type.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-6 py-5 max-w-md">
                      <div className="text-sm text-slate-700 dark:text-slate-300 line-clamp-3">
                        {item.contentPreview || "No content preview"}
                      </div>
                    </td>
                    <td className="px-6 py-5 text-sm font-semibold text-slate-700 dark:text-slate-300">
                      {item.author}
                    </td>
                    <td className="px-6 py-5 text-sm text-slate-500 dark:text-slate-400">
                      {item.createdAt
                        ? new Date(item.createdAt).toLocaleString()
                        : "-"}
                    </td>
                    <td className="px-6 py-5">
                      <span className={getStatusColor(item.status)}>
                        {item.status.charAt(0).toUpperCase() + item.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-8 py-5 text-right">
                      {item.status === "pending" ? (
                        <div className="flex gap-2 justify-end">
                          <button
                            onClick={() => handleAction(item, "APPROVE")}
                            disabled={submittingId === item.id}
                            className="bg-emerald-500 hover:bg-emerald-600 text-white px-5 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-60"
                          >
                            Approve
                          </button>
                          <button
                            onClick={() => handleAction(item, "REJECT")}
                            disabled={submittingId === item.id}
                            className="bg-red-500 hover:bg-red-600 text-white px-5 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-60"
                          >
                            Reject
                          </button>
                        </div>
                      ) : (
                        <span className="text-slate-600 dark:text-slate-400 font-semibold text-sm">
                          {item.status === "approved" ? "Approved" : "Rejected"}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {loading ? (
          <div className="text-center py-10 text-slate-500 dark:text-slate-400">
            Loading moderation queue...
          </div>
        ) : null}

        {!loading && filteredData.length === 0 ? (
          <div className="text-center py-24 text-slate-500 dark:text-slate-400">
            <Flag className="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-slate-600" />
            <h3 className="text-xl font-semibold mb-2">No moderation items found</h3>
            <p>Try a different filter or search term.</p>
          </div>
        ) : null}
      </div>
    </div>
  );
}
