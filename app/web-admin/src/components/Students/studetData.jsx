import React from 'react'
import Overview from './overview'
import AllStudents from './AllStudents';
import Verified from './Verified';
import Banned from './Banned';
import Reported from './Reported';
import UnVerified from './unVerified';

export default function StudetData({ CurrentPage }) {  // 👈 Pass CurrentPage as prop
  return (
    <div className="space-y-6">
      

      {/* Use CurrentPage prop instead of window.location */}
      {CurrentPage === "overview" && <Overview />}
      {CurrentPage === "all-users" && <AllStudents />}
      {CurrentPage === "active-users" && <div>Active Users</div>}
      {CurrentPage === "verified" && <Verified />}
      {CurrentPage === "banned" && <Banned />}
      {CurrentPage === "unverified" && <UnVerified />}
      {CurrentPage === "reported" && <Reported />}
     
      {/* Default content */}
      
        {/* Add your student cards */}
    
    </div>
  );
}
