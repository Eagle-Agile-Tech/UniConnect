import React, { useState, useMemo } from "react";

export default function Reported() {
  const [hoveredUser, setHoveredUser] = useState(null);
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  const USERS_PER_PAGE = 10;

  const users = [
    {
      id: 1,
      name: "iman",
      email: "iman@ju.edu.et",
      status: "Active",
      avatar: "https://i.pravatar.cc/40?img=1",
      University: "jima university",
      departement: "software engineering",
      bio: "Frontend developer passionate about React.",
      joindate: "2023-03-10",
    },
    {
      id: 2,
      name: "tsegi",
      email: "tsegi@ju.edu.et",
      status: "Active",
      avatar: "https://i.pravatar.cc/40?img=2",
      University: "jima university",
      departement: "software engineering",
      joindate: "2023-01-15",
      bio: "Backend developer who loves Node.js.",
    },
    {
      id: 3,
      name: "feysel",
      email: "feysel@ju.edu.et",
      status: "Inactive",
      avatar: "https://i.pravatar.cc/40?img=3",
      University: "jima university",
      departement: "software engineering",
      bio: "flutter developer",
      joindate: "2022-11-20",
    },
  ];

  const filteredUsers = useMemo(() => {
    return users.filter((user) => {
      const q = search.toLowerCase();
      return (
        user.name.toLowerCase().includes(q) ||
        user.email.toLowerCase().includes(q) ||
        user.University.toLowerCase().includes(q) ||
        user.departement.toLowerCase().includes(q)
      );
    });
  }, [search]);

  const totalPages = Math.ceil(filteredUsers.length / USERS_PER_PAGE);

  const paginatedUsers = filteredUsers.slice(
    (currentPage - 1) * USERS_PER_PAGE,
    currentPage * USERS_PER_PAGE
  );

  return (
    <div className="bg-white dark:bg-slate-900 rounded-b-2xl border border-gray-200 dark:border-slate-700 text-black dark:text-white">

      {/* 🔍 Search */}
      <div className="p-4 flex justify-between items-center">
        <input
          type="text"
          placeholder="Search users..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setCurrentPage(1);
          }}
          className="px-4 py-2 border rounded-lg w-64 text-sm bg-white dark:bg-slate-800 border-gray-300 dark:border-slate-600 text-black dark:text-white"
        />

        <span className="text-sm text-gray-600 dark:text-gray-300">
          Page {currentPage} of {totalPages || 1}
        </span>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full min-w-[600px]">
          <thead>
            <tr className="border-b border-gray-200 dark:border-slate-700">
              <th className="py-3 px-4 text-left text-sm">Name</th>
              <th className="py-3 px-4 text-left text-sm">Email</th>
              <th className="py-3 px-4 text-left text-sm">University</th>
              <th className="py-3 px-4 text-left text-sm">Department</th>
              <th className="py-3 px-4 text-left text-sm">Status</th>
            </tr>
          </thead>

          <tbody>
            {paginatedUsers.map((user) => (
              <tr
                key={user.id}
                className="border-b border-gray-100 dark:border-slate-800"
              >
                {/* Name */}
                <td className="py-3 px-4 relative">
                  <button
                    onMouseEnter={() => setHoveredUser(user.id)}
                    onMouseLeave={() => setHoveredUser(null)}
                    className="text-blue-600 dark:text-blue-400 hover:underline"
                  >
                    {user.name}
                  </button>

                  {/* Hover Card */}
                  {hoveredUser === user.id && (
                    <div className="absolute bg-white dark:bg-slate-800 shadow-lg p-4 rounded-xl w-72 z-50 border border-gray-200 dark:border-slate-700">
                      <p className="font-medium">{user.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {user.email}
                      </p>
                      <p className="text-sm mt-2 text-gray-700 dark:text-gray-300">
                        {user.bio}
                      </p>
                    </div>
                  )}
                </td>

                <td className="py-3 px-4">{user.email}</td>
                <td className="py-3 px-4">{user.University}</td>
                <td className="py-3 px-4">{user.departement}</td>

                {/* Status */}
                <td className="py-3 px-4">
                  <span
                    className={`px-2 py-1 text-xs rounded ${
                      user.status === "Active"
                        ? "bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400"
                        : "bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400"
                    }`}
                  >
                    {user.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex justify-between items-center p-4">
        <button
          disabled={currentPage === 1}
          onClick={() => setCurrentPage((p) => p - 1)}
          className="px-3 py-1 bg-gray-200 dark:bg-slate-700 rounded disabled:opacity-50"
        >
          Prev
        </button>

        <button
          disabled={currentPage === totalPages || totalPages === 0}
          onClick={() => setCurrentPage((p) => p + 1)}
          className="px-3 py-1 bg-gray-200 dark:bg-slate-700 rounded disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}