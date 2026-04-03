import { University } from "lucide-react";
import React, { useState } from "react";

export default function Reported() {
  const [hoveredUser, setHoveredUser] = useState(null);

  // Example user data (you can replace with API later)
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
      joindate: "2023-03-10"
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

      bio: "Backend developer who loves Node.js."
    },
    {
      id: 3,
      name: "feysel",
      email: "feysel@ju.edu.et",
      status: "Inactive",
      avatar: "https://i.pravatar.cc/40?img=3",
      University: "jima university",
      departement: "software engineering",
      bio: "flatter developer ",
      joindate: "2022-11-20"
    }
  ];

  return (
  <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-b-2xl border border-slate-200/50 dark:border-slate-700/50">

      {/* Header */}
      <div className="p-4 border-b border-slate-200/50 dark:border-slate-700/50 flex justify-end">
        <button className="text-blue-600 hover:text-blue-700 text-sm font-medium">
          View all
        </button>
      </div>

      {/* Table */}
      <div className="overflow-x-auto overflow-y-visible">
        <table className="w-full min-w-[600px]">
          <thead>
            <tr className="border-b border-slate-200/50 dark:border-slate-700/50">
              <th className="py-3 px-4 text-left text-sm text-slate-500">Name</th>
              <th className="py-3 px-4 text-left text-sm text-slate-500">Email</th>
              <th className="py-3 px-4 text-left text-sm text-slate-500">Status</th>
            </tr>
          </thead>

          <tbody>
            {users.map((user) => (
              <tr
                key={user.id}
                className="border-b border-slate-200/50 dark:border-slate-700/50"
              >
                {/* Name */}
                <td className="py-3 px-4 relative">
                  <button
                    className="text-blue-600 hover:underline"
                    onMouseEnter={() => setHoveredUser(user.id)}
                    onMouseLeave={() => setHoveredUser(null)}
                  >
                    {user.name}
                  </button>

                  {/* Profile Card */}
                  {hoveredUser === user.id && (
                    <div
                      className="absolute top-1/2 left-full ml-3 -translate-y-1/2 w-72 bg-white dark:bg-slate-800 shadow-lg rounded-xl p-4 border border-slate-200 dark:border-slate-700 z-50"
                      onMouseEnter={() => setHoveredUser(user.id)}
                      onMouseLeave={() => setHoveredUser(null)}
                    >
                      <div className="flex items-center gap-3">
                        <img
                          src={user.avatar}
                          alt="avatar"
                          className="w-10 h-10 rounded-full"
                        />

                        <div>
                          <p className="font-medium text-slate-800 dark:text-white">
                            {user.name}
                          </p>
                          <p className="text-xs text-slate-500">{user.email}</p>
                        </div>
                      </div>

                      <p className="text-sm text-slate-600 dark:text-slate-300 mt-2">
                        {user.bio}
                      </p>
                       <p className="text-sm text-slate-600 dark:text-slate-300 mt-2">
                        join date: {user.joindate}
                      </p>
                    </div>
                  )}
                </td>

                {/* Email */}
                <td className="py-3 px-4 text-sm text-slate-800 dark:text-white">
                  {user.email}
                </td>
                <td className="py-3 px-4 text-sm text-slate-800 dark:text-white">
                  {user.University}
                </td>
                <td className="py-3 px-4 text-sm text-slate-800 dark:text-white">
                  {user.departement}
                </td>
                {/* Status */}
                <td className="py-3 px-4 text-sm">
                  <span
                    className={`py-1 px-2 rounded-full text-xs ${
                      user.status === "Active"
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
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
    </div>
  );
}