import React from 'react'
import CircleChart from './circlechart'
import VerificationStatus from './statuschart';


export default function Dashboard() {
  return (
   
   <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
         <div className="space-y-3">
           
   <CircleChart />
         </div>
        
    <div className="xl:col-span-2">
             <VerificationStatus/>
        </div>
       </div>
        
     )
   }
   