import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip
} from "recharts";

const weeklyData = [
  { name: "Active Users", value: 87200, color: "#3b82f6" },
  { name: "Posts", value: 19800, color: "#10b981" },
  { name: "Comments", value: 109500, color: "#8b5cf6" },
  { name: "Reports", value: 2240, color: "#ef4444" }
];

export default function SalesChart() {
  return (
    <div className="bg-white/80 dark:bg-slate-900 backdrop-blur-xl rounded-b-2xl p-6 border border-slate-200/50 dark:border-slate-700/50">

      <div className="mb-6">
        <h3 className="text-xl font-bold text-slate-800 dark:text-white">
          Users
        </h3>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Total number of users
        </p>
      </div>

      <div className="w-full h-48 min-h-[192px]">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={weeklyData}
              cx="50%"
              cy="50%"
              innerRadius={40}
              outerRadius={80}
              paddingAngle={5}
              dataKey="value"
            >
              {weeklyData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>

            <Tooltip
              contentStyle={{
                backgroundColor: "rgba(255,255,255,0.95)",
                border: "none",
                borderRadius: "12px",
                boxShadow: "0 10px 40px rgba(0,0,0,0.1)"
              }}
            />
          </PieChart>
        </ResponsiveContainer>
      </div>
<div className=" space-y-3">
{weeklyData.map((entry, index) => {
    return (
  <div className="flex items-center justify-between">
      <div className="flex items-sce space-x-3">
        <div
          className="w-4 h-4 rounded-full"
          style={{ backgroundColor: entry.color }}
       />
<span className="text-sm text-slate-600 dark:text-slate-400">
    {entry.name}
</span>

      
      </div>
      <div className="text-sm font-semibold text-slate-800 dark:text-white">
        {entry.value.toLocaleString()}%
      </div>
       </div>
       
    );
  })}
    </div>
    </div>
  );
}
