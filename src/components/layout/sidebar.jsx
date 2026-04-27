import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/useAuth";
import { Zap,
  LayoutDashboard,
  BarChart3,
  Users,
  CheckCircle,
  FileText,
  ShieldAlert,
  UsersRound,
  MessageSquare,
  Megaphone,
  DollarSign,
  Bell,
  Settings,
  Menu,
  ChevronDown,
   ArrowLeftRight
 } from 'lucide-react';


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
    submenu: [
      { id: "verification-overview", label: "Verification Overview" },
      { id: "id-verification", label: "Id Verification" },
      { id: "verified-email", label: "Verified with Email" },
     
      { id: "Institution-Verification-", label: "Institution Verification" },
    
    ]
  },
  {
    id: "posts",
    icon: FileText,
    label: "Posts & Content",
    submenu: [
      
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
      
    ]
  },
  {
    id: "messages",
    icon: MessageSquare,
    label: "Messages & Chats",
    submenu: [
     
    ]
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
function Sidebar({ collapsed = false, onToggleSidebar }) {
  const [expandedItem, setExpandedItem] = useState(new Set());
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();

  const toggleExpand = (itemid) => {
    const newExpanded = new Set(expandedItem);
    if(newExpanded.has(itemid)){
      newExpanded.delete(itemid);
    } else {
      newExpanded.add(itemid);
    }
    setExpandedItem(newExpanded);
  };

  const getNavigationPath = (itemId, subId) => {
    if (itemId === "dashboard") return "/dashboard";
    if (itemId === "verification") {
      return subId ? `/dashboard/verification/${subId}` : "/dashboard/verification";
    }
    return subId ? `/dashboard/${subId}` : `/dashboard/${itemId}`;
  };

  const handleNavigation = (itemId, path) => {
    navigate(getNavigationPath(itemId, path));
  };

  const handleItemClick = (item) => {
    if (collapsed && onToggleSidebar) {
      onToggleSidebar();
      if (item.submenu) {
        toggleExpand(item.id);
      }
      return;
    }

    if (item.submenu) {
      toggleExpand(item.id);
    } else {
      handleNavigation(item.id);
    }
  };

  return (
   <div className={`${collapsed ? 'w-16' : 'w-72'} h-screen overflow-x-hidden transition-all duration-300 ease-in-out 
bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl border-r border-slate-200/50 dark:border-slate-700/50 flex flex-col relative z-10`}>{/* logo */}
    <div className="p-4 border-b border-slate-200/50 dark:border-slate-700/50 ">
<div className="flex items-center justify-between">
  <div className="flex items-center space-x-3">
    <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl flex items-center justify-center shadow-md">
      <ArrowLeftRight className="w-6 h-6 text-white rotate-45"/>
    </div>
    {!collapsed && (
      <div>
        <h1 className="text-lg font-bold text-slate-800 dark:text-white">
          Uniconnect
        </h1>
       
      </div>
    )}
  </div>
 
</div>
    </div>
    {/* navigation */}
   <nav className={`flex-1 ${collapsed ? 'p-2' : 'p-4'} space-y-2 overflow-y-auto overflow-x-hidden`}>
  {menuItems.map((item) => {
    const itemActive =
      (item.id === "dashboard" && location.pathname === "/dashboard") ||
      (item.id === "verification" && location.pathname.startsWith("/dashboard/verification")) ||
      location.pathname === `/dashboard/${item.id}` ||
      (item.submenu &&
        item.submenu.some(
          (sub) =>
            location.pathname === `/dashboard/${sub.id}` ||
            location.pathname === `/dashboard/verification/${sub.id}`
        ));

    return (
      <div key={item.id}>
        <button
          className={`relative group w-full flex items-center justify-between p-2 rounded-xl transition-all duration-200 ${
            itemActive
              ? "bg-gradient-to-r from-slate-800 to-slate-600 text-white shadow-lg shadow-blue-500/25"
              : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50"
          }`}
          onClick={() => handleItemClick(item)}
        >
          <div className={`min-w-0 flex items-center ${collapsed ? 'justify-center w-full' : 'space-x-3'}`}>
            {React.createElement(item.icon, { className: "w-5 h-5" })}

            {collapsed && (
              <span className="pointer-events-none absolute left-full top-1/2 ml-2 -translate-y-1/2 whitespace-nowrap rounded-lg bg-slate-900 text-white text-xs px-2 py-1 shadow-lg opacity-0 transition duration-200 group-hover:opacity-100">
                {item.label}
              </span>
            )}

            {!collapsed && (
            <>
              <span className="font-medium ml-2 truncate">
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

          {item.submenu && !collapsed && (
            <ChevronDown className={`w-4 h-4 transition-transform duration-200 ${
              expandedItem.has(item.id) ||
              (item.id === "verification" && location.pathname.startsWith("/dashboard/verification")) ||
              item.submenu.some(
                (sub) =>
                  location.pathname === `/dashboard/${sub.id}` ||
                  location.pathname === `/dashboard/verification/${sub.id}`
              )
                ? "rotate-180"
                : ""
            }`} />
          )}
        </button>

        {/* submenu */}
      {item.submenu && !collapsed &&
        (expandedItem.has(item.id) ||
          (item.id === "verification" && location.pathname.startsWith("/dashboard/verification")) ||
          item.submenu.some(
            (sub) =>
              location.pathname === `/dashboard/${sub.id}` ||
              location.pathname === `/dashboard/verification/${sub.id}`
          )) && (
          <div className="ml-8 mt-2 space-y-1 min-w-0">
            {item.submenu.map((subitem) => (
              <button
                key={subitem.id}
    className={`w-full min-w-0 text-left p-2 text-sm rounded-lg transition-all flex items-center space-x-3 ${
      location.pathname === `/dashboard/${subitem.id}` ||
      location.pathname === `/dashboard/verification/${subitem.id}`
        ? "bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg shadow-blue-500/25 font-bold"
        : "text-slate-800 dark:text-slate-300 hover:bg-slate-100/50 dark:hover:bg-slate-700/50"
    }`}
    onClick={() => handleNavigation(item.id, subitem.id)}
  >
    <span className="truncate">{subitem.label}</span>
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
    <div className="mt-auto shrink-0  border-t border-slate-200/50 dark:border-slate-700/50">
    <Link to="/profile" className="w-full flex items-center space-x-3 rounded-xl bg-slate-50 dark:bg-slate-800/50 p-2 text-left hover:bg-slate-100 dark:hover:bg-slate-700/50 transition" > 
    <img src={user?.profile?.profileImage || "https://via.placeholder.com/40"} alt="Admin" className="w-10 h-10 rounded-full ring-2 ring-blue-500" />
     <div className="flex-1 min-w-0"> <p className="text-sm font-medium text-slate-800 dark:text-white truncate"> 
      {user?.profile?.fullName || user?.firstName || "Admin"} </p> 
      <p className="text-xs text-slate-600 dark:text-slate-400 truncate"> {user?.role || "Administrator"} </p> 
      </div>
      
     </Link> </div> </div> ) }
       export default Sidebar
