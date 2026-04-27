import React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from "recharts";

const data = [
  { month: "Jan", users: 45000, post: 32000 },
  { month: "Feb", users: 52000, post: 38000 },
  { month: "Mar", users: 48000, post: 35000 },
  { month: "Apr", users: 61000, post: 42000 },
  { month: "May", users: 55000, post: 40000 },
  { month: "Jun", users: 67000, post: 45000 },
  { month: "Jul", users: 72000, post: 48000 },
  { month: "Aug", users: 69000, post: 46000 },
  { month: "Sep", users: 78000, post: 52000 },
  { month: "Oct", users: 74000, post: 50000 },
  { month: "Nov", users: 82000, post: 55000 },
  { month: "Dec", users: 89000, post: 58000 }
];

export default function RevenueChart() {
  return (
    <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-b-2xl border border-slate-200/50 dark:border-slate-700/50 p-6">
      
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-xl font-bold text-slate-800 dark:text-white">
            Users & Posts Chart
          </h3>
          <p className="text-sm text-slate-600 dark:text-slate-400">
            Track users and posts over time
          </p>
        </div>

        <div className="flex space-x-4">
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 rounded-full bg-blue-500"></div>
            <span className="text-sm text-slate-600 dark:text-slate-400">
              Users
            </span>
          </div>

          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 rounded-full bg-purple-500"></div>
            <span className="text-sm text-slate-600 dark:text-slate-400">
              Posts
            </span>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="h-80">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={data}
            margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" opacity={0.3} />

            <XAxis
              dataKey="month"
              stroke="#64748b"
              fontSize={12}
              tickLine={false}
              axisLine={false}
            />

            <YAxis
              stroke="#64748b"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              tickFormatter={(value) => `${value / 1000}k`}
            />

            <Tooltip
              contentStyle={{
                backgroundColor: "rgba(255,255,255,0.95)",
                border: "none",
                borderRadius: "12px",
                boxShadow: "0 10px 40px rgba(0,0,0,0.1)"
              }}
              formatter={(value, name) => [
                value.toLocaleString(),
                name === "users" ? "Users" : "Posts"
              ]}
            />

            {/* Users Bar */}
            <Bar
              dataKey="users"
              fill="url(#usersGradient)"
              radius={[4, 4, 0, 0]}
              maxBarSize={40}
            />

            {/* Posts Bar */}
            <Bar
              dataKey="post"
              fill="url(#postsGradient)"
              radius={[4, 4, 0, 0]}
              maxBarSize={40}
            />

            {/* Gradients */}
            <defs>
              <linearGradient id="usersGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#3b82f6" />
                <stop offset="100%" stopColor="#2563eb" />
              </linearGradient>

              <linearGradient id="postsGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#a855f7" />
                <stop offset="100%" stopColor="#7e22ce" />
              </linearGradient>
            </defs>

          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}