import React from "react";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  CheckCircle,
  FileText,
  MessageSquare,
  Shield,
  Users,
} from "lucide-react";

function formatNumber(value) {
  return new Intl.NumberFormat().format(Number(value || 0));
}

export default function StatusGrid({ stats }) {
  const adminStats = [
    {
      title: "Total Registered Users",
      value: formatNumber(stats?.platformOverview?.totalUsers),
      icon: Users,
      color: "from-indigo-500 to-purple-600",
      bgColor: "bg-indigo-50 dark:bg-indigo-950/30",
      textColor: "text-indigo-700 dark:text-indigo-300",
    },
    {
      title: "Active Users Today",
      value: formatNumber(stats?.activity?.activeUsersToday),
      icon: Activity,
      color: "from-blue-500 to-cyan-600",
      bgColor: "bg-blue-50 dark:bg-blue-950/30",
      textColor: "text-blue-700 dark:text-blue-300",
    },
    {
      title: "Total Posts",
      value: formatNumber(stats?.platformOverview?.totalPosts),
      icon: FileText,
      color: "from-green-500 to-emerald-600",
      bgColor: "bg-green-50 dark:bg-green-950/30",
      textColor: "text-green-700 dark:text-green-300",
    },
    {
      title: "Total Comments",
      value: formatNumber(stats?.platformOverview?.totalComments),
      icon: MessageSquare,
      color: "from-violet-500 to-fuchsia-600",
      bgColor: "bg-violet-50 dark:bg-violet-950/30",
      textColor: "text-violet-700 dark:text-violet-300",
    },
    {
      title: "Pending Moderation",
      value: formatNumber(
        (stats?.moderation?.pendingPosts || 0) +
          (stats?.moderation?.pendingComments || 0)
      ),
      icon: AlertTriangle,
      color: "from-amber-500 to-orange-600",
      bgColor: "bg-amber-50 dark:bg-amber-950/30",
      textColor: "text-amber-700 dark:text-amber-300",
    },
    {
      title: "Pending Verifications",
      value: formatNumber(stats?.verification?.pendingVerifications),
      icon: Shield,
      color: "from-teal-500 to-cyan-600",
      bgColor: "bg-teal-50 dark:bg-teal-950/30",
      textColor: "text-teal-700 dark:text-teal-300",
    },
    {
      title: "Verified Users",
      value: formatNumber(stats?.verification?.verifiedUsers),
      icon: CheckCircle,
      color: "from-emerald-500 to-teal-600",
      bgColor: "bg-emerald-50 dark:bg-emerald-950/30",
      textColor: "text-emerald-700 dark:text-emerald-300",
    },
    {
      title: "Deleted Users",
      value: formatNumber(stats?.safety?.deletedUsers),
      icon: Users,
      color: "from-pink-500 to-rose-600",
      bgColor: "bg-pink-50 dark:bg-pink-950/30",
      textColor: "text-pink-700 dark:text-pink-300",
    },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
      {adminStats.map((stat) => (
        <div
          key={stat.title}
          className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-2xl p-6 border-slate-200/50 dark:border-slate-700/50 hover:shadow-xl hover:shadow-slate-200/20 dark:hover:shadow-slate-900/20 transition-all duration-300 group"
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
                <ArrowRight className="w-4 h-4 text-emerald-500 rotate-45" />
                <span className="text-sm font-medium text-emerald-500">
                  Live backend data
                </span>
              </div>
            </div>

            <div
              className={`p-3 rounded-xl ${stat.bgColor} group-hover:scale-110 transition-transform duration-300`}
            >
              <stat.icon className={`w-6 h-6 ${stat.textColor}`} />
            </div>
          </div>

          <div className="mt-4 h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
            <div
              className={`h-full bg-linear-to-r ${stat.color} transition-all duration-300`}
              style={{ width: "72%" }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}
