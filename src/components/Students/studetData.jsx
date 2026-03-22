import React from 'react'
import Overview from './overview'
import AllStudents from './AllStudents';
import Verified from './Verified';
import Banned from './Banned';
import UnVerified from './unVerified';
export default function StudetData({ CurrentPage }) {  // 👈 Pass CurrentPage as prop
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-white">
          Students Management (2.4M)
        </h1>
      </div>

      {/* Use CurrentPage prop instead of window.location */}
      {CurrentPage === "overview" && <Overview />}
      {CurrentPage === "all-users" && <AllStudents />}
      {CurrentPage === "active-users" && <div>Active Users</div>}
      {CurrentPage === "verified" && <Verified />}
      {CurrentPage === "banned" && <Banned />}
      {CurrentPage === "unverified" && <UnVerified />}

      {/* Default content */}
      
        {/* Add your student cards */}
    
    </div>
  );
}
