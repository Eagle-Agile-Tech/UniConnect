'use client';

import React, { useEffect, useMemo, useState } from "react";
import { Search, Eye } from "lucide-react";

export default function InstitutionVerificationPage() {
  const [allItems, setAllItems] = useState([]);
  const [activeTab, setActiveTab] = useState("pending");
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedFile, setSelectedFile] = useState(null);

  // 🔹 MOCK DATA (Institution only)
  useEffect(() => {
    setAllItems([
      {
        id: "1",
        institutionName: "Addis Tech University",
        email: "admin@atu.edu",
        createdAt: new Date(),
        status: "pending",
        fileUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
      },
      {
        id: "2",
        institutionName: "Jimma University",
        email: "info@ju.edu",
        createdAt: new Date(),
        status: "approved",
        fileUrl: "https://via.placeholder.com/400",
      },
    ]);
  }, []);

  // 🔍 Filter
  const filteredData = useMemo(() => {
    return allItems.filter((item) => {
      if (activeTab !== "all" && item.status !== activeTab) return false;

      const q = searchTerm.toLowerCase();
      return (
        item.institutionName.toLowerCase().includes(q) ||
        item.email.toLowerCase().includes(q)
      );
    });
  }, [activeTab, allItems, searchTerm]);

  const handleAction = (id, newStatus) => {
    setAllItems((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, status: newStatus } : item
      )
    );
  };

  return (
    <div className="p-8 bg-slate-900 min-h-screen text-white">
      <h1 className="text-3xl font-bold mb-6">
        Institution Verification
      </h1>

      {/* Tabs + Search */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex gap-6">
          {["all", "pending", "approved", "rejected"].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-2 ${
                activeTab === tab
                  ? "border-b-2 border-orange-500 text-orange-400"
                  : "text-gray-400"
              }`}
            >
              {tab.toUpperCase()}
            </button>
          ))}
        </div>

        <div className="relative w-72">
          <Search className="absolute left-3 top-3 text-gray-400" size={18} />
          <input
            type="text"
            placeholder="Search institution..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-3 py-2 rounded-full bg-transparent border border-gray-600 text-sm focus:outline-none"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-slate-800 rounded-2xl overflow-hidden">
        <div className="grid grid-cols-5 px-6 py-4 text-gray-400 text-sm border-b border-gray-700">
          <span>Institution</span>
          <span>Email</span>
          <span>Created</span>
          <span>Status</span>
          <span>Actions</span>
        </div>

        {filteredData.map((item) => (
          <div
            key={item.id}
            className="grid grid-cols-5 px-6 py-4 border-b border-gray-700 items-center"
          >
            <span className="font-medium">{item.institutionName}</span>
            <span className="text-gray-300">{item.email}</span>
            <span className="text-gray-400">
              {new Date(item.createdAt).toLocaleDateString()}
            </span>

            {/* ✅ FIXED STATUS */}
            <span
              className={`px-2 py-1 text-xs rounded-full w-fit ${
                item.status === "pending"
                  ? "bg-yellow-500/20 text-yellow-400"
                  : item.status === "approved"
                  ? "bg-green-500/20 text-green-400"
                  : "bg-red-500/20 text-red-400"
              }`}
            >
              {item.status}
            </span>

            {/* Actions */}
            <div className="flex gap-2 items-center">
              <button
                onClick={() => setSelectedFile(item.fileUrl)}
                className="text-blue-400 flex items-center gap-1 text-sm"
              >
                <Eye size={16} /> View
              </button>

              {item.status === "pending" && (
                <>
                  <button
                    onClick={() => handleAction(item.id, "approved")}
                    className="bg-green-500 px-3 py-1 rounded text-xs"
                  >
                    Approve
                  </button>

                  <button
                    onClick={() => handleAction(item.id, "rejected")}
                    className="bg-red-500 px-3 py-1 rounded text-xs"
                  >
                    Reject
                  </button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* 📄 Document Modal */}
      {selectedFile && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50">
          <div className="bg-white p-4 rounded-xl w-[90%] max-w-3xl relative">
            <button
              onClick={() => setSelectedFile(null)}
              className="absolute top-2 right-3 text-black text-lg"
            >
              ✕
            </button>

            {selectedFile.endsWith(".pdf") ? (
              <iframe src={selectedFile} className="w-full h-[500px]" />
            ) : (
              <img
                src={selectedFile}
                className="w-full max-h-[500px] object-contain"
              />
            )}
          </div>
        </div>
      )}
    </div>
  );
}