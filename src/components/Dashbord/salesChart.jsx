import React from 'react'
import { PieChart,
    Pie,
    Cell,
    ResponsiveContainer,
    Tooltip
 } from 'recharts';
 const weeklyData = [
  { name: "Active Users", value: 87200,  color: "#3b82f6" },  // weekly total or avg
  { name: "Posts",        value: 19800,  color: "#10b981" },
  { name: "Comments",     value: 109500, color: "#8b5cf6" },
  { name: "Reports",      value: 2240,   color: "#ef4444" },
];
export default function salesChart() {
  return (
   
      <div className="bg-white/80 dark:bg-slate-900 backdrop-blur-xl rounded-b-2xl p-6 border
      border-slate-200/50 dark:border-slate-700/50">
<div classname="mb-6">
<h3 className="text-xl font-bold text-slate-800 dark:text-white">
    users
    </h3>
    <p className="text-sm text-slate-500 dark:text-slate-400">
      Total number of users
    </p>
  </div>
     <div className="h-80">
<ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={40}
          outerRadius={80}
          paddingAngle={5}
          dataKey="value"
         
        >
          {data.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Pie>

        <Tooltip
          contentStyle={{
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            border: 'none',
            borderRadius: '12px',
            boxShadow: '0 10px 40px rgba(0, 0, 0, 0.1)',
          }}
          // Optional: customize formatter if you want
          // formatter={(value, name) => [`${value.toLocaleString()}`, name]}
        />
      </PieChart>
    </ResponsiveContainer>
     </div>
    </div>
  )
}
