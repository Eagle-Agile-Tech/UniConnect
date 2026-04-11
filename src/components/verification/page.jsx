'use client';

import React, { useState } from 'react';
import { 
  Users, Clock, CheckCircle, XCircle, Search, Download, Eye 
} from 'lucide-react';

const mockData = [
  {
    id: 1,
    name: "Alex Johnson",
    email: "alex@university.edu",
    studentId: "STU-45678",
    avatar: "https://i.pravatar.cc/150?img=12",
    idProofUrl: "https://picsum.photos/id/1015/800/600",
    submitted: "2 hours ago",
    status: "pending"
  },
  {
    id: 2,
    name: "Sarah Chen",
    email: "sarah@uni.ac",
    studentId: "ID-99231",
    avatar: "https://i.pravatar.cc/150?img=48",
    idProofUrl: "https://picsum.photos/id/201/800/600",
    submitted: "Yesterday",
    status: "approved"
  },
  {
    id: 3,
    name: "Michael Okoro",
    email: "michael@stu.edu.et",
    studentId: "STU-78412",
    avatar: "https://i.pravatar.cc/150?img=67",
    idProofUrl: "https://picsum.photos/id/133/800/600",
    submitted: "3 hours ago",
    status: "pending"
  },
  {
    id: 4,
    name: "Fatima Ahmed",
    email: "fatima@university.edu",
    studentId: "ID-33456",
    avatar: "https://i.pravatar.cc/150?img=39",
    idProofUrl: "https://picsum.photos/id/180/800/600",
    submitted: "1 day ago",
    status: "rejected"
  },
  {
    id: 5,
    name: "Daniel Kebede",
    email: "daniel@aaustudents.edu.et",
    studentId: "STU-11234",
    avatar: "https://i.pravatar.cc/150?img=64",
    idProofUrl: "https://picsum.photos/id/201/800/600",
    submitted: "5 hours ago",
    status: "pending"
  },
];

export default function VerificationPage({ CurrentPage }) {
  const [data, setData] = useState(mockData);
  const [activeTab, setActiveTab] = useState('requests');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredData = data
    .filter(item => {
      if (activeTab !== 'all' && item.status !== activeTab) return false;
      if (searchTerm === '') return true;
      return (
        item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.studentId.toLowerCase().includes(searchTerm.toLowerCase())
      );
    });

  const stats = {
    pending: data.filter(d => d.status === 'pending').length,
    approvedToday: 12,
    rejected: data.filter(d => d.status === 'rejected').length,
    totalVerified: 1284,
  };

  const handleApprove = (id) => {
    setData(prev => prev.map(item => 
      item.id === id ? { ...item, status: 'approved' } : item
    ));
  };

  const handleReject = (id) => {
    setData(prev => prev.map(item => 
      item.id === id ? { ...item, status: 'rejected' } : item
    ));
  };

  const getStatusColor = (status) => {
    if (status === 'pending') return 'bg-yellow-500 text-black px-3 py-1 rounded-full text-xs font-medium';
    if (status === 'approved') return 'bg-emerald-500 px-3 py-1 rounded-full text-xs font-medium text-white';
    return 'bg-red-500 px-3 py-1 rounded-full text-xs font-medium text-white';
  };

  return (
    <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-xl rounded-b-2xl p-6 border
         border-slate-200/50 dark:border-slate-700/50">
      <div className="max-w-7xl ">
        <div className="mb-5">
          <h1 className="text-4xl font-bold mb-1 text-slate-800 dark:text-white">
            Student Verifications
          </h1>
          <p className="text-slate-500 dark:text-slate-400">
            Manual ID verification • Email auto-verified • {stats.pending} pending
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          {[
            { label: "Pending", value: stats.pending, color: "yellow", icon: Clock },
            { label: "Approved Today", value: stats.approvedToday, color: "emerald", icon: CheckCircle },
            { label: "Rejected", value: stats.rejected, color: "red", icon: XCircle },
            { label: "Total Verified", value: stats.totalVerified.toLocaleString(), color: "slate", icon: Users },
          ].map((stat, i) => (
            <div key={i} className="bg-white/70 dark:bg-slate-800/70 backdrop-blur-xl rounded-3xl p-6 border border-slate-200/50 dark:border-slate-700/50 shadow-lg hover:shadow-xl transition-all">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-slate-500 dark:text-slate-400 text-sm font-medium">{stat.label}</p>
                  <p className="text-4xl font-bold mt-2 text-slate-800 dark:text-white">{stat.value}</p>
                </div>
                <div className={`w-12 h-12 text-${stat.color}-500 bg-${stat.color}-100 dark:bg-${stat.color}-900/50 rounded-2xl p-3 flex items-center justify-center`}>
                  <stat.icon className="w-6 h-6" />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Tabs & Controls */}
        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between mb-8 gap-6">
          <div className="flex border-b border-slate-200 dark:border-slate-700">
            {(['all', 'pending', 'approved', 'rejected'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-6 py-4 font-medium text-sm border-b-2 transition-all ${
                  activeTab === tab 
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300'
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
              </button>
            )))}
          </div>

          <div className="flex items-center gap-4 flex-wrap">
            <div className="relative w-80 flex-1 min-w-[300px]">
              <Search className="absolute left-4 top-3 text-slate-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search by name, email or student ID"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full bg-white/50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 pl-11 py-3 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent backdrop-blur-sm"
              />
            </div>

            <select className="bg-white/50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 px-5 py-3 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option>All Universities</option>
              <option>Addis Ababa University</option>
              <option>University of Gondar</option>
              <option>Hawassa University</option>
            </select>

            <button className="flex items-center gap-2 bg-white/70 dark:bg-slate-800/70 hover:bg-white dark:hover:bg-slate-700 border border-slate-200 dark:border-slate-700 px-6 py-3 rounded-2xl text-sm font-medium transition-all backdrop-blur-sm shadow-lg hover:shadow-xl">
              <Download className="w-4 h-4" />
              Export CSV
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white/60 dark:bg-slate-800/60 backdrop-blur-xl rounded-3xl overflow-hidden border border-slate-200/50 dark:border-slate-700/50 shadow-2xl">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700 bg-white/50 dark:bg-slate-700/50 backdrop-blur-sm">
                  <th className="px-8 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Name</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Student Email</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Student ID</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">ID Proof</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Submitted</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Status</th>
                  <th className="px-8 py-5 text-right text-sm font-semibold text-slate-700 dark:text-slate-300">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200/50 dark:divide-slate-700/50">
                {filteredData.map((student) => (
                  <tr key={student.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-all">
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-4">
                        <img 
                          src={student.avatar} 
                          alt={student.name}
                          className="w-12 h-12 rounded-2xl object-cover ring-2 ring-slate-200 dark:ring-slate-700 shadow-lg"
                        />
                        <div>
                          <div className="font-semibold text-slate-800 dark:text-white">{student.name}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-2">
                        <span className="text-sm text-slate-700 dark:text-slate-300 font-mono">{student.email}</span>
                        <span className="text-emerald-500 text-xs font-bold">✓ Verified</span>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <span className="font-mono text-sm bg-slate-100 dark:bg-slate-700 px-3 py-1 rounded-full text-slate-700 dark:text-slate-300">
                        {student.studentId}
                      </span>
                    </td>
                    <td className="px-6 py-5">
                      <button 
                        onClick={() => window.open(student.idProofUrl, '_blank')}
                        className="flex items-center gap-2 text-blue-600 hover:text-blue-500 font-medium transition-all hover:underline"
                      >
                        <Eye className="w-4 h-4" />
                        <span className="text-sm">View ID</span>
                      </button>
                    </td>
                    <td className="px-6 py-5 text-sm text-slate-500 dark:text-slate-400">
                      {student.submitted}
                    </td>
                    <td className="px-6 py-5">
                      <span className={getStatusColor(student.status)}>
                        {student.status.charAt(0).toUpperCase() + student.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-8 py-5 text-right">
                      {student.status === 'pending' ? (
                        <div className="flex gap-2 justify-end">
                          <button 
                            onClick={() => handleApprove(student.id)}
                            className="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-2.5 rounded-2xl text-sm font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
                          >
                            Approve
                          </button>
                          <button 
                            onClick={() => handleReject(student.id)}
                            className="bg-red-500 hover:bg-red-600 text-white px-6 py-2.5 rounded-2xl text-sm font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
                          >
                            Reject
                          </button>
                        </div>
                      ) : (
                        <span className="text-slate-600 dark:text-slate-400 font-semibold text-sm">
                          {student.status === 'approved' ? '✓ Approved' : '✕ Rejected'}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {filteredData.length === 0 && (
          <div className="text-center py-24 text-slate-500 dark:text-slate-400">
            <Users className="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-slate-600" />
            <h3 className="text-xl font-semibold mb-2">No verification requests</h3>
            <p>{activeTab === 'all' ? 'found' : `in ${activeTab} status`}</p>
          </div>
        )}

        <div className="mt-8 text-center text-sm text-slate-500 dark:text-slate-400">
          Showing <span className="font-semibold">{filteredData.length}</span> of <span className="font-semibold">{data.length}</span> total requests
        </div>
      </div>
    </div>
  );
}
