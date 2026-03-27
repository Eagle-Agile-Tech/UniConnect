import React ,{useState}from 'react'
import { Zap,
  LayoutDashboard,
  BarChart3,
  Users,
  CheckCircle,       // or BadgeCheck / ShieldCheck as alternative
  FileText,
  ShieldAlert,
  UsersRound,
  MessageSquare,
  Megaphone,
  DollarSign,
  Bell,
  Settings,
  ChevronDown
 } from 'lucide-react';
 import { ArrowLeftRight } from "lucide-react";

const menuItems = [
  {
    id: "dashboard",
    icon: LayoutDashboard,
    label: "Dashboard",
   
    badge: "Live"
  },

  {
    id: "Students",
    icon: Users,
    label: "Students",
    count: "2.4M",
    submenu: [
      { id: "overview",          label: "Overview", badge:"new" },
      { id: "all-users",          label: "All Users", badge:"1.2M" },
      { id: "active-users",       label: "Active / Online" },
      { id: "verified",           label: "Verified Accounts" },  // ← Link to list of already verified users
      { id: "reported",           label: "Reported Users" },
      { id: "banned",             label: "Banned / Suspended" },
      
       
       
    ]
  },
  {
    id: "verification",
    icon: CheckCircle,          // or "ShieldCheck", "BadgeCheck", "Award"
    label: "Verification",
    badge: "128",                 // e.g. pending verification requests
    
  },
  {
    id: "posts",
    icon: FileText,
    label: "Posts & Content",
    submenu: [
      { id: "all-posts",       label: "All Posts" },
      { id: "pending-review",  label: "Pending Review" },
      { id: "reported-content",label: "Reported Content" },
      { id: "trending",        label: "Trending / Viral" },
      { id: "media-library",   label: "Media Library" }
    ]
  },
  {
    id: "moderation",
    icon: ShieldAlert,
    label: "Moderation",
    badge: "47"
  },
  {
    id: "communities",
    icon: UsersRound,
    label: "Communities / Groups",
    submenu: [
      { id: "all-groups",      label: "All Communities" },
      { id: "reported-groups", label: "Reported" },
      { id: "trending-groups", label: "Trending" }
    ]
  },
  {
    id: "messages",
    icon: MessageSquare,
    label: "Messages & Chats",
    submenu: [
      { id: "reports",         label: "Reported Conversations" },
      { id: "flagged",         label: "Flagged Messages" }
    ]
  },
  {
    id: "ads",
    icon: Megaphone,
    label: "Advertisements",
    submenu: [
      { id: "campaigns",       label: "All Campaigns" },
      { id: "pending-ads",     label: "Pending Approval" },
      { id: "revenue",         label: "Ad Revenue" }
    ]
  },
  
  {
    id: "notifications",
    icon: Bell,
    label: "Notifications",
    badge: "12"
  },
  {
    id: "settings",
    icon: Settings,
    label: "Platform Settings",
    submenu: [
      { id: "general",         label: "General" },
      { id: "features",        label: "Feature Flags" },
      { id: "policies",        label: "Content Policies" },
      { id: "api",             label: "API & Integrations" },
      { id: "backup",          label: "Backup & Logs" }
    ]
  }
];
function Sidebar({ collapsed, onToggle, CurrentPage, onPageChange }) {
  const [expandedItem, setExpandedItem] = useState(new Set());
  const toggleExpand = (itemid) => {
    const newExpanded = new Set(expandedItem);
    if(newExpanded.has(itemid)){
      newExpanded.delete(itemid);
    } else {
      newExpanded.add(itemid);
    }
    setExpandedItem(newExpanded);
  };
  return (
   <div
  className={`${collapsed ? "w-20" : "w-72"} transition duration-300 ease-in-out bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl
  border-r border-slate-200/50 dark:border-slate-700/50 flex flex-col relative z-10`}
>
    {/* logo */}
    <div className="p-6 border-b border-slate-200/50 dark:border-slate-700/50 ">
<div className="flex items-center space-x-3">
  <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl flex items-center justify-center shadow-md">
  <ArrowLeftRight className="w-6 h-6 text-white rotate-45"/>
</div>
  {/* conditinally render  */}
  {!collapsed && (
    <div>
      <h1 className="text-lg font-bold text-slate-800 dark:text-white">
        Uniconnect
      </h1>
      <p className="text-xs text-slate-600 dark:text-slate-400">
        connect
      </p>
    </div>
  )}
</div>
    </div>
    {/* navigation */}
   <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
  {menuItems.map((item) => {
    const itemActive =
      CurrentPage === item.id ||
      (item.submenu && item.submenu.some((sub) => sub.id === CurrentPage));

    return (
      <div key={item.id}>
        <button
          className={`w-full flex items-center justify-between p-2 rounded-xl transition-all duration-200 ${
            itemActive
              ? "bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg shadow-blue-500/25"
              : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50"
          }`}
          onClick={() => {
            if (item.submenu) {
              toggleExpand(item.id);
            } else {
              onPageChange(item.id);
            }
          }}
        >
          <div className="flex items-center space-x-3">
 {React.createElement(item.icon, { className: "w-5 h-5" })}


  {!collapsed && (
    <>
      <span className="font-medium ml-2">
        {item.label}
      </span>

      {item.badge && (
        <span className="px-2 py-1 text-xs bg-red-500 text-white rounded-full">
          {item.badge}
        </span>
      )}

      {item.count && (
        <span className="px-2 py-1 text-xs bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-full">
          {item.count}
        </span>
      )}
    </>
  )}
</div>

          {!collapsed && item.submenu && (
            <ChevronDown className="w-4 h-4 transition-transform" />
          )}
        </button>

        {/* submenu */}
      {!collapsed &&
        item.submenu &&
        (expandedItem.has(item.id) ||
          item.submenu.some((sub) => sub.id === CurrentPage)) && (
          <div className="ml-8 mt-2 space-y-1">
            {item.submenu.map((subitem) => (
              <button 
                key={subitem.id}
    className={`w-full text-left p-2 text-sm rounded-lg transition-all flex items-center space-x-3 ${
      CurrentPage === subitem.id
        ? "bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg shadow-blue-500/25 font-bold"  // 👈 ACTIVE
        : "text-slate-800 dark:text-slate-300 hover:bg-slate-100/50 dark:hover:bg-slate-700/50"  // 👈 INACTIVE
    }`}
    onClick={() => onPageChange(subitem.id)}
  >
    <span>{subitem.label}</span>
    {subitem.badge && (
      <span className="px-2 py-1 text-xs bg-white/20 dark:bg-white/20 text-white rounded-full">
        {subitem.badge}
      </span>
    )}
  </button>
))}

  </div>
)}

      </div>
    );
  })}
</nav>
    {/* user profile */}
      <div className="p-4 border-t border-slate-200/50 dark:border-slate-700/50">
 
    <div className="flex items-center space-x-3  rounded-xl bg-slate-50 dark:bg-slate-800/50">
      <img
        src=""           // ← add your image URL here
        alt="Admin"
        className="w-10 h-10 rounded-full ring-2 ring-blue-500"
      />
      <div className="flex-1 min-w-0">
         <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-slate-800 dark:text-white truncate">
          Admin
        </p>
        <p className="text-xs text-slate-600 dark:text-slate-400 truncate">
          Administrator
        </p>
   </div>
    </div>
  </div>
</div>
      </div>
  
  )
}
export default Sidebar