import React, { useEffect, useRef, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Header from './components/layout/header';
import Sidebar from './components/layout/sidebar';
import Dashboard from './components/Dashbord/dashboard';
import Verification from './Verification';

// Student components
// import Overview from './components/Students/overview';
import AllStudents from './components/Students/AllStudents';
import Verified from './components/Students/Verified';
import UnVerified from './components/Students/UnVerified';
import Reported from './components/Students/Reported';
import Banned from './components/Students/Banned';


// Other components
import Moderation from './components/Moderation/moderation';
import PlatformSetting from './components/setting/platformsetting';

export default function DashboardLayout() {
  const [sideBarCollapsed, setSideBarCollapsed] = useState(false);
  const sidebarRef = useRef(null);

  const onToggleSidebar = () => {
    setSideBarCollapsed(!sideBarCollapsed);
  };

  useEffect(() => {
    const handleOutsideClick = (event) => {
      if (sideBarCollapsed) return;

      const target = event.target;
      const clickedSidebar = sidebarRef.current?.contains(target);
      const clickedToggleButton = target.closest?.("[data-sidebar-toggle='true']");

      if (!clickedSidebar && !clickedToggleButton) {
        setSideBarCollapsed(true);
      }
    };

    document.addEventListener("mousedown", handleOutsideClick);
    document.addEventListener("touchstart", handleOutsideClick);

    return () => {
      document.removeEventListener("mousedown", handleOutsideClick);
      document.removeEventListener("touchstart", handleOutsideClick);
    };
  }, [sideBarCollapsed]);

  return (
    <div className="min-h-screen overflow-x-hidden bg-linear-to-br from-slate-50 via-blue-50 to-indigo-50
    dark:from-slate-900 dark:via-slate-800 dark:to-slate-900 transition-all duration-500">
      <div className="flex h-screen overflow-hidden">
        <div ref={sidebarRef}>
          <Sidebar collapsed={sideBarCollapsed} onToggleSidebar={onToggleSidebar} />
        </div>
        <div className="min-w-0 flex-1 flex flex-col overflow-hidden">
          <Header sideBarCollapsed={sideBarCollapsed} onToggleSidebar={onToggleSidebar} />
          <main className="min-w-0 flex-1 overflow-y-auto overflow-x-hidden bg-transparent">
            <div className="p-6 space-y-6">
              <Routes>
                <Route path="/" element={<Dashboard />} />
{/*                 
                <Route path="/overview" element={<Overview />} /> */}
                <Route path="/all-users" element={<AllStudents />} />
                <Route path="/active-users" element={<AllStudents />} />
                <Route path="/verified" element={<Verified />} />
                <Route path="/reported" element={<Reported />} />
                <Route path="/banned" element={<Banned />} />
                <Route path="/verification/*" element={<Verification />} />
                <Route path="/moderation" element={<Moderation />} />
                <Route path="/platform-setting" element={<PlatformSetting />} />
                {/* <Route path="*" element={<Navigate to="/" replace />} /> */}
              </Routes>
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}
