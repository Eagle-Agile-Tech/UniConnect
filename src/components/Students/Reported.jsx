import React from 'react'

export default function Reported() {
  return (
    <div>
     {/* recent users */}
        <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-b-2xl p-6 border
         border-slate-200/50 dark:border-slate-700/50">
            <div className="p-4 border-b border-slate-200/50 dark:border-slate-700/50 ">
<div className="flex items-center justify-between mb-4">
    <div >

    </div>
<button className="text-blue-600 hover:bg-blue-700 text-sm font-medium">
  View all
</button>
</div>
            </div>
            {/* table */}
            <div className="overflow-x-auto">
<table className="w-full ">
    <thead>
        <tr className="border-b border-slate-200/50 dark:border-slate-700/50">
            <th className="py-3 px-4 text-left text-sm font-medium text-slate-500 dark:text-slate-400">Name</th>
            <th className="py-3 px-4 text-left text-sm font-medium text-slate-500 dark:text-slate-400">Email</th>
            <th className="py-3 px-4 text-left text-sm font-medium text-slate-500 dark:text-slate-400">Status</th>
        </tr>
    </thead>
    <tbody>
        <tr className="border-b border-slate-200/50 dark:border-slate-700/50">
            <td className="py-3 px-4 text-sm text-slate-800 dark:text-white">John Doe</td>
            <td className="py-3 px-4 text-sm text-slate-800 dark:text-white">john.doe@example.com</td>
            <td className="py-3 px-4 text-sm">
                <span className="bg-green-100 text-green-800 py-1 px-2 rounded-full">
                    Active
                </span>
            </td>
        </tr>
        {/* Add more rows as needed */}
    </tbody>

</table>
            </div>
    </div>
    </div>
  
  )
}
