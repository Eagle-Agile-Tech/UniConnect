import { ArrowRight ,
Users,
Activity,
Calendar,
MessageSquare,
AlertTriangle,
Zap,
DollarSign,
Heart,

} from 'lucide-react'
import React from 'react'

const adminStats = [
  {
    title: "Total Registered Users",
    value: "1,248,567",
    change: "+18.4%",
    trend: "up",
    icon: Users,
    color: "from-indigo-500 to-purple-600",
    bgColor: "bg-indigo-50 dark:bg-indigo-950/30",
    textColor: "text-indigo-700 dark:text-indigo-300"
  },
  {
    title: "Daily Active Users (DAU)",
    value: "187,420",
    change: "+12.1%",
    trend: "up",
    icon: Activity,
    color: "from-blue-500 to-cyan-600",
    bgColor: "bg-blue-50 dark:bg-blue-950/30",
    textColor: "text-blue-700 dark:text-blue-300"
  },
  {
    title: "Monthly Active Users (MAU)",
    value: "845,910",
    change: "+15.7%",
    trend: "up",
    icon: Calendar,
    color: "from-violet-500 to-purple-600",
    bgColor: "bg-violet-50 dark:bg-violet-950/30",
    textColor: "text-violet-700 dark:text-violet-300"
  },
  {
    title: "New Posts Today",
    value: "92,340",
    change: "+9.8%",
    trend: "up",
    icon: MessageSquare,
    color: "from-green-500 to-emerald-600",
    bgColor: "bg-green-50 dark:bg-green-950/30",
    textColor: "text-green-700 dark:text-green-300"
  },
  {
    title: "Pending Reports / Moderation Queue",
    value: "1,284",
    change: "+28.6%",
    trend: "up",  // ↑ might indicate rising issues → alert color if high
    icon: AlertTriangle,
    color: "from-amber-500 to-orange-600",
    bgColor: "bg-amber-50 dark:bg-amber-950/30",
    textColor: "text-amber-700 dark:text-amber-300"
  },
  {
    title: "Active Sessions Now",
    value: "42,819",
    change: "+5.3%",
    trend: "up",
    icon: Zap,
    color: "from-teal-500 to-cyan-600",
    bgColor: "bg-teal-50 dark:bg-teal-950/30",
    textColor: "text-teal-700 dark:text-teal-300"
  },
  {
    title: "Total Revenue (This Month)",
    value: "$348,920",
    change: "+22.4%",
    trend: "up",
    icon: DollarSign,
    color: "from-emerald-500 to-teal-600",
    bgColor: "bg-emerald-50 dark:bg-emerald-950/30",
    textColor: "text-emerald-700 dark:text-emerald-300"
  },
  {
    title: "Avg. Engagement Rate",
    value: "6.82%",
    change: "-1.2%",
    trend: "down",
    icon: Heart,
    color: "from-pink-500 to-rose-600",
    bgColor: "bg-pink-50 dark:bg-pink-950/30",
    textColor: "text-pink-700 dark:text-pink-300"
  }
];export default function StatusGrid() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
     
      {adminStats.map((stat, index) => (
        <div
          key={index}
          className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-2xl p-6
          border-slate-200/50 dark:border-slate-700/50 hover:shadow-xl
          hover:shadow-slate-200/20 dark:hover:shadow-slate-900/20 transition-all duration-300 group"
        >
      
          <div className="flex items-center justify-between">
            
            <div className="flex-1">

              <p className="text-sm font-medium text-slate-600 dark:text-slate-400 mb-2">
                {stat.title}
              </p>

              <p className="text-3xl font-bold text-slate-800 dark:text-white mb-4"> 
                {stat.value}
              </p>

              <div className="flex items-center space-x-2">

                {stat.trend === "up" ? (
                  <ArrowRight className="w-4 h-4 text-emerald-500 rotate-45"/>
                ) : (
                  <ArrowRight className="w-4 h-4 text-red-500 -rotate-45"/>
                )}

                <span
                  className={`text-sm font-medium ${
                    stat.trend === "up"
                      ? "text-emerald-500"
                      : "text-red-500"
                  }`}
                >
                  {stat.change}
                </span>

              </div>

            </div>

            <div className={`p-3 rounded-xl ${stat.bgColor} group-hover:scale-110 transition-transform duration-300`}>
              <stat.icon className={`w-6 h-6 ${stat.textColor}`} />
            </div>

          </div>

          {/* progress bar */}
          <div className="mt-4 h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
            <div
              className={`h-full bg-linear-to-r ${stat.color} transition-all duration-300`}
              style={{ width: stat.trend === "up" ? "75%" : "45%" }}
            ></div>
          </div>

        </div>
      ))}

    </div>
  );
}