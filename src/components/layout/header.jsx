import React, { useState, useEffect } from "react";
import { useAuth } from '../../contexts/AuthContext';
import {
  Menu,
  Search,
  Moon,
  Filter,
  Plus,
  Sun,
  Bell,
  Settings,
  LogOut
} from "lucide-react";

export default function Header() {
  const [darkMode, setDarkMode] = useState(() => {
    const isDark = localStorage.getItem("theme") === "dark";
    if (isDark) {
      document.documentElement.classList.add("dark");
    }
    return isDark;
  });
  const { user, logout } = useAuth();

  const toggleTheme = () => {
    const newDarkMode = !darkMode;

    if (newDarkMode) {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
    } else {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
    }

    setDarkMode(newDarkMode);
  };

  const handleLogout = () => {
    logout();
  };

  return (
    <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl border-b
    border-slate-200/50 dark:border-slate-700/50 px-6 py-4">

      <div className="flex items-center justify-between">

        {/* LEFT */}
        <div className="flex items-center space-x-4">
          <div className="hidden md:block">
            
            <h1 className="text-2xl font-black text-slate-800 dark:text-white">
              Dashboard
            </h1>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Welcome back {user?.name || 'Admin'}
            </p>
          </div>
        </div>

        {/* CENTER */}
        <div className="flex-1 max-w-md mx-8">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />

            <input
              type="text"
              placeholder="Search anything"
              className="w-full pl-10 pr-4 py-2.5 bg-slate-100 dark:bg-slate-800 border
              border-slate-200 dark:border-slate-700 rounded-xl text-slate-800
              dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2
              focus:ring-blue-500 transition-all"
            />

            <button className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
              <Filter className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* RIGHT */}
        <div className="flex items-center space-x-3">

          <button className="hidden lg:flex items-center space-x-2 py-2 px-4
           bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl">
            <Plus className="w-4 h-4" />
            <span className="text-sm font-medium">New</span>
          </button>

          {/* DARK MODE TOGGLE */}
          <button
            onClick={toggleTheme}
            className="p-2 rounded-lg text-slate-600 dark:text-slate-300
            hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            {darkMode ? (
              <Sun className="w-5 h-5" />
            ) : (
              <Moon className="w-5 h-5" />
            )}
          </button>

          <button className="p-2 rounded-lg text-slate-600 dark:text-slate-300
          hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
            <Bell className="w-5 h-5" />
          </button>

          <button className="p-2 rounded-lg text-slate-600 dark:text-slate-300
          hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
            <Settings className="w-5 h-5" />
          </button>

          <button
            onClick={handleLogout}
            className="p-2 rounded-lg text-slate-600 dark:text-slate-300
            hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            title="Logout"
          >
            <LogOut className="w-5 h-5" />
          </button>

        </div>
      </div>
    </div>
  );
}