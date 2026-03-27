'use client';

import React, { useState } from 'react';
import { 
  Flag, Eye, CheckCircle, XCircle, Search, Download, MessageCircle, 
  Image, Video, AlertTriangle, ShieldAlert 
} from 'lucide-react';

const mockReports = [
  {
    id: 1,
    type: 'post',
    title: "Study group for CS301 - Addis Ababa University",
    reporter: "Sarah Chen",
    reason: "Spam",
    contentPreview: "Join our premium study group... DM for details",
    mediaType: 'text',
    date: "2 hours ago",
    status: "pending"
  },
  {
    id: 2,
    type: 'comment',
    title: "Great lecture notes! Thanks prof!",
    reporter: "Michael Okoro",
    reason: "Harassment",
    contentPreview: "@user why you always late? useless",
    mediaType: 'text',
    date: "5 hours ago",
    status: "rejected"
  },
  {
    id: 3,
    type: 'image',
    title: "Campus event poster",
    reporter: "Fatima Ahmed",
    reason: "Inappropriate content",
    contentPreview: "Event poster",
    mediaType: 'image',
    date: "1 day ago",
    status: "approved"
  },
  {
    id: 4,
    type: 'post',
    title: "Exam solutions leaked",
    reporter: "Admin Bot",
    reason: "Academic dishonesty",
    contentPreview: "Final exam answers for Math 201...",
    mediaType: 'text',
    date: "3 hours ago",
    status: "pending"
  },
  {
    id: 5,
    type: 'video',
    title: "Lecture recording",
    reporter: "Daniel Kebede",
    reason: "Copyright violation",
    contentPreview: "Full lecture video",
    mediaType: 'video',
    date: "6 hours ago",
    status: "pending"
  },
];

export default function ModerationPage({ CurrentPage }) {
  const [data, setData] = useState(mockReports);
  const [activeTab, setActiveTab] = useState('pending');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredData = data
    .filter(item => {
      if (activeTab !== 'all' && item.status !== activeTab) return false;
      if (searchTerm === '') return true;
      return (
        item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.reporter.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.reason.toLowerCase().includes(searchTerm.toLowerCase())
      );
    });

  const stats = {
    pending: data.filter(d => d.status === 'pending').length,
    approvedToday: 8,
    rejected: data.filter(d => d.status === 'rejected').length,
    totalReports: 247,
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

  const getMediaIcon = (type) => {
    if (type === 'image') return Image;
    if (type === 'video') return Video;
    return MessageCircle;
  };

  return (
    <div className="flex-1  p-8 bg-slate-50 dark:bg-slate-900 min-h-screen">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-2">
            <ShieldAlert className="w-10 h-10 text-red-500" />
            <div>
              <h1 className="text-4xl font-bold text-slate-800 dark:text-white">
                Content Moderation
              </h1>
              <p className="text-slate-500 dark:text-slate-400">
                Review reported content • {stats.pending} pending actions
              </p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
          {[
            { label: "Pending Review", value: stats.pending, color: "yellow", icon: AlertTriangle },
            { label: "Approved Today", value: stats.approvedToday, color: "emerald", icon: CheckCircle },
            { label: "Rejected", value: stats.rejected, color: "red", icon: XCircle },
            { label: "Total Reports", value: stats.totalReports.toLocaleString(), color: "slate", icon: Flag },
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
                    ? 'border-red-500 text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/50' 
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
                placeholder="Search reports by title, reporter, or reason"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full bg-white/50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 pl-11 py-3 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent backdrop-blur-sm"
              />
            </div>
            <select className="bg-white/50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 px-5 py-3 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500">
              <option>All Types</option>
              <option>Posts</option>
              <option>Comments</option>
              <option>Images</option>
              <option>Videos</option>
            </select>
            <button className="flex items-center gap-2 bg-white/70 dark:bg-slate-800/70 hover:bg-white dark:hover:bg-slate-700 border border-slate-200 dark:border-slate-700 px-6 py-3 rounded-2xl text-sm font-medium transition-all backdrop-blur-sm shadow-lg hover:shadow-xl">
              <Download className="w-4 h-4" />
              Export Reports
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white/60 dark:bg-slate-800/60 backdrop-blur-xl rounded-3xl overflow-hidden border border-slate-200/50 dark:border-slate-700/50 shadow-2xl">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700 bg-white/50 dark:bg-slate-700/50 backdrop-blur-sm">
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Type</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Content</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Reporter</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Reason</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Media</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Date</th>
                  <th className="px-6 py-5 text-left text-sm font-semibold text-slate-700 dark:text-slate-300">Status</th>
                  <th className="px-8 py-5 text-right text-sm font-semibold text-slate-700 dark:text-slate-300">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200/50 dark:divide-slate-700/50">
                {filteredData.map((report) => (
                  <tr key={report.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-all">
                    <td className="px-6 py-5">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        report.type === 'post' ? 'bg-blue-100 text-blue-800' :
                        report.type === 'comment' ? 'bg-purple-100 text-purple-800' :
                        report.type === 'image' ? 'bg-green-100 text-green-800' :
                        'bg-indigo-100 text-indigo-800'
                      }`}>
                        {report.type.charAt(0).toUpperCase() + report.type.slice(1)}
                      </span>
                    </td>
                    <td className="px-6 py-5 max-w-md">
                      <div className="font-medium text-slate-800 dark:text-white truncate" title={report.title}>
                        {report.title}
                      </div>
                      <div className="text-sm text-slate-500 dark:text-slate-400 line-clamp-2" title={report.contentPreview}>
                        {report.contentPreview}
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <span className="font-semibold text-slate-700 dark:text-slate-300">{report.reporter}</span>
                    </td>
                    <td className="px-6 py-5">
                      <span className="bg-red-100 dark:bg-red-900/50 text-red-800 dark:text-red-300 px-3 py-1 rounded-full text-xs font-medium">
                        {report.reason}
                      </span>
                    </td>
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-2">
                        <getMediaIcon mediaType={report.mediaType} className="w-5 h-5 text-slate-500" />
                        <span className="text-sm text-slate-500 capitalize">{report.mediaType}</span>
                      </div>
                    </td>
                    <td className="px-6 py-5 text-sm text-slate-500 dark:text-slate-400">
                      {report.date}
                    </td>
                    <td className="px-6 py-5">
                      <span className={getStatusColor(report.status)}>
                        {report.status.charAt(0).toUpperCase() + report.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-8 py-5 text-right">
                      {report.status === 'pending' ? (
                        <div className="flex gap-2 justify-end">
                          <button 
                            onClick={() => handleApprove(report.id)}
                            className="bg-emerald-500 hover:bg-emerald-600 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
                          >
                            Approve
                          </button>
                          <button 
                            onClick={() => handleReject(report.id)}
                            className="bg-red-500 hover:bg-red-600 text-white px-5 py-2.5 rounded-xl text-sm font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
                          >
                            Reject
                          </button>
                        </div>
                      ) : (
                        <span className="text-slate-600 dark:text-slate-400 font-semibold text-sm">
                          {report.status === 'approved' ? '✓ Approved' : '✕ Rejected'}
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
            <Flag className="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-slate-600" />
            <h3 className="text-xl font-semibold mb-2">No reports found</h3>
            <p>{activeTab === 'all' ? 'matching your filters' : `in ${activeTab} status`}</p>
          </div>
        )}

        <div className="mt-8 text-center text-sm text-slate-500 dark:text-slate-400">
          Showing <span className="font-semibold">{filteredData.length}</span> of <span className="font-semibold">{data.length}</span> total reports
        </div>
      </div>
    </div>
  );
}
