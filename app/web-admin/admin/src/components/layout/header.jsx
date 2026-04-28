import React, { useState, useEffect } from "react";
import {
  Menu,
  Search,
  Moon,
  Filter,
  Plus,
  Sun,
  Bell,
  Settings
} from "lucide-react";
export default function Header({ sideBarCollapsed, onToggleSidebar }) {
  const [darkMode, setDarkMode] = useState(false); // 👈 ADD THIS

  // Load theme on mount
  useEffect(() => {
    const isDark = localStorage.getItem("theme") === "dark";
    setDarkMode(isDark);
    if (isDark) {
      document.documentElement.classList.add("dark");
    }
  }, []);

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

  return (
    <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl border-b 
    border-slate-200/50 dark:border-slate-700/50 px-6 py-4">

      <div className="flex items-center justify-between">

        {/* LEFT */}
        <div className="flex items-center space-x-4">
          <button
            className="p-2 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            onClick={onToggleSidebar}
          >
            <Menu className="w-5 h-5" />
          </button>

          <div className="hidden md:block">
            <h1 className="text-2xl font-black text-slate-800 dark:text-white">
              Dashboard
            </h1>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Welcome back Admin
            </p>
          </div>
        </div>

        {/* CENTER */}
        <div className="flex-1 max-w-md mx-8">
          <div className="relative">
            

            
          </div>
        </div>

        {/* RIGHT */}
        <div className="flex items-center space-x-3">

         

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

        
          

        </div>
      </div>
    </div>
  );
}