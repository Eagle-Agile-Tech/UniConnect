import React ,{useState}from 'react'
import Header from './components/layout/header'
import Sidebar from './components/layout/sidebar'
import Dashboard from './components/Dashbord/dashboard'
import StudetData from './components/Students/studetData'
export default function App() {
  const [sideBarCollapsed, setSideBarCollapsed] = useState(false);
  const [CurrentPage, setCurrentPage] = useState("dashboard");
  return (
    <div className="min-h-screen bg-linear-to-br from-slate-50 via-blue-50 to-indigo-50 
    dark:from-slate-900 dark:via-slate-800 dark:to-slate-900 transition-all duration-500">
      <div className="flex h-screen overflow-hidden">

        <Sidebar
         collapsed={sideBarCollapsed} 
        onToggle={() => setSideBarCollapsed(!sideBarCollapsed)}
        CurrentPage={CurrentPage}
        onPageChange={setCurrentPage}
        />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header 
          sideBarCollapsed={sideBarCollapsed}
          onToggleSidebar={() => setSideBarCollapsed(!sideBarCollapsed)}
          />
          <main className="flex-1 overflow-y-auto bg-transparent">
            <div className="p-6 space-y-6">
              {CurrentPage === "dashboard" && <Dashboard />}

              {(CurrentPage === "students" ||
                CurrentPage === "overview" ||
                CurrentPage === "all-users" ||
                CurrentPage === "active-users" ||
                CurrentPage === "verified" ||
                CurrentPage === "reported" ||
                CurrentPage === "banned") && (
                <StudetData CurrentPage={CurrentPage} />
              )}
            </div>
          </main>
        </div>
      </div>
    </div>
  )
}
