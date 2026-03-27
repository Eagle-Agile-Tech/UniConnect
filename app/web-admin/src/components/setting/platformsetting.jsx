import { 
  Settings, User, Shield, Globe, Database, Bell, Lock, CreditCard, 
  Save, Search, ChevronDown, ToggleRight, CheckCircle 
} from 'lucide-react';
import React, { useState } from 'react';


const settingsSections = [
  {
    id: "general",
    title: "General Settings",
    description: "Platform-wide preferences and branding",
    icon: Settings,
    items: [
      { key: "platform_name", label: "Platform Name", type: "text", value: "Uniconnect" },
      { key: "tagline", label: "Tagline", type: "text", value: "Connect with Ethiopian Universities" },
      { key: "timezone", label: "Default Timezone", type: "select", value: "Africa/Addis_Ababa", options: ["Africa/Addis_Ababa", "UTC", "Africa/Nairobi"] },
      { key: "language", label: "Default Language", type: "select", value: "en", options: ["en", "am", "ti"] },
    ]
  },
  {
  id: "features",
  title: "Feature Flags",
  description: "Enable/disable platform features",
  icon: ToggleRight,  // ✅ Fixed
  items: [
    // ... rest unchanged
  ]
},

  {
    id: "policies",
    title: "Content Policies",
    description: "Moderation rules and guidelines",
    icon: Shield,
    items: [
      { key: "spam_threshold", label: "Spam Score Threshold", type: "slider", value: 75, min: 50, max: 100 },
      { key: "max_image_size", label: "Max Image Size (MB)", type: "number", value: 5 },
      { key: "daily_post_limit", label: "Daily Post Limit", type: "number", value: 50 },
      { key: "allowed_domains", label: "Allowed Email Domains", type: "textarea", value: "edu.et,university.edu" },
    ]
  },
  {
    id: "api",
    title: "API & Integrations",
    description: "Third-party connections and API keys",
    icon: Globe,
    items: [
      { key: "api_rate_limit", label: "API Rate Limit (req/min)", type: "number", value: 100 },
      { key: "stripe_key", label: "Stripe Publishable Key", type: "password", value: "pk_live_..." },
      { key: "google_oauth", label: "Google OAuth Enabled", type: "toggle", value: true },
      { key: "zoom_integration", label: "Zoom Integration", type: "toggle", value: false },
    ]
  },
  {
    id: "backup",
    title: "Backup & Logs",
    description: "Data management and audit logs",
    icon: Database,
    items: [
      { key: "auto_backup", label: "Automatic Backups", type: "toggle", value: true },
      { key: "retention_days", label: "Log Retention (days)", type: "number", value: 90 },
      { key: "backup_frequency", label: "Backup Frequency", type: "select", value: "daily", options: ["daily", "weekly", "monthly"] },
      { key: "export_logs", label: "Export All Logs", type: "button", value: "Export Now" },
    ]
  },
];

export default function SettingsPage({ CurrentPage }) {
  const [activeSection, setActiveSection] = useState('general');
  const [settings, setSettings] = useState({});

  const currentSection = settingsSections.find(s => s.id === activeSection);

  const updateSetting = (key, value) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  const renderInput = (item) => {
    switch (item.type) {
      case 'text':
      case 'password':
      case 'number':
      case 'textarea':
        const InputTag = item.type === 'textarea' ? 'textarea' : 'input';
        return (
          <InputTag
            type={item.type}
            value={settings[item.key] || item.value}
            onChange={(e) => updateSetting(item.key, e.target.value)}
            className="w-full px-4 py-3 border border-slate-200 dark:border-slate-700 rounded-2xl bg-white/50 dark:bg-slate-800/50 focus:outline-none focus:ring-2 focus:ring-blue-500 backdrop-blur-sm transition-all"
            placeholder={item.label}
          />
        );
      case 'toggle':
        return (
          <button className={`relative w-14 h-7 rounded-full transition-all duration-300 ${
            (settings[item.key] || item.value) ? 'bg-blue-500' : 'bg-slate-300 dark:bg-slate-700'
          }`}>
            <div className={`absolute top-0.5 left-0.5 w-6 h-6 bg-white rounded-full shadow-md transform transition-transform duration-300 ${
              (settings[item.key] || item.value) ? 'translate-x-7' : 'translate-x-0'
            }`} />
          </button>
        );
      case 'select':
        return (
          <select
            value={settings[item.key] || item.value}
            onChange={(e) => updateSetting(item.key, e.target.value)}
            className="w-full px-4 py-3 border border-slate-200 dark:border-slate-700 rounded-2xl bg-white/50 dark:bg-slate-800/50 focus:outline-none focus:ring-2 focus:ring-blue-500 backdrop-blur-sm appearance-none"
          >
            {item.options.map(opt => (
              <option key={opt} value={opt}>{opt.replace('_', ' ').toUpperCase()}</option>
            ))}
          </select>
        );
      case 'slider':
        return (
          <div className="flex items-center gap-4">
            <input
              type="range"
              min={item.min}
              max={item.max}
              value={settings[item.key] || item.value}
              onChange={(e) => updateSetting(item.key, e.target.value)}
              className="flex-1 h-2 bg-slate-200 dark:bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-500 hover:accent-blue-600"
            />
            <span className="font-mono text-sm text-slate-600 dark:text-slate-400 min-w-[3rem]">
              {settings[item.key] || item.value}%
            </span>
          </div>
        );
      case 'button':
        return (
          <button className="flex items-center gap-2 bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white px-6 py-3 rounded-2xl font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200">
            <Database className="w-4 h-4" />
            {item.value}
          </button>
        );
      default:
        return null;
    }
  };

  return (
    <div className="flex-1 ml-72 p-8 bg-slate-50 dark:bg-slate-900 min-h-screen">
      <div className="max-w-6xl mx-auto">
        <div className="mb-12">
          <div className="flex items-center gap-4 mb-6">
            <Settings className="w-12 h-12 text-blue-500 bg-blue-100 dark:bg-blue-900/50 p-3 rounded-3xl" />
            <div>
              <h1 className="text-4xl font-bold text-slate-800 dark:text-white">Platform Settings</h1>
              <p className="text-slate-500 dark:text-slate-400 mt-1">Fine-tune your Uniconnect configuration</p>
            </div>
          </div>
          
          <div className="flex gap-2 bg-slate-100 dark:bg-slate-800/50 p-3 rounded-2xl">
            <button className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-xl font-medium shadow-lg hover:shadow-xl transition-all">
              <Save className="w-4 h-4" />
              Save All Changes
            </button>
            <button className="flex items-center gap-2 px-4 py-2 bg-emerald-500 text-white rounded-xl font-medium shadow-lg hover:shadow-xl transition-all">
              <CheckCircle className="w-4 h-4" />
              Settings Valid
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Sidebar Sections */}
          <div className="lg:col-span-1 space-y-2">
            {settingsSections.map((section) => (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                className={`w-full flex items-center gap-4 p-6 rounded-3xl transition-all group ${
                  activeSection === section.id
                    ? 'bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-2xl shadow-blue-500/25'
                    : 'bg-white/70 dark:bg-slate-800/70 border border-slate-200/50 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/70'
                }`}
              >
                <section.icon className={`w-6 h-6 ${activeSection === section.id ? 'text-white' : 'text-slate-500'}`} />
                <div className="flex-1 text-left">
                  <div className="font-semibold">{section.title}</div>
                  <div className="text-xs text-slate-500 dark:text-slate-400 opacity-75">{section.description}</div>
                </div>
                {activeSection === section.id && (
                  <ChevronDown className="w-4 h-4 text-white/70 transition-transform rotate-180" />
                )}
              </button>
            ))}
          </div>

          {/* Settings Form */}
          <div className="lg:col-span-2 bg-white/60 dark:bg-slate-800/60 backdrop-blur-xl rounded-3xl p-8 border border-slate-200/50 dark:border-slate-700/50 shadow-2xl">
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-slate-800 dark:text-white mb-2">{currentSection.title}</h2>
              <p className="text-slate-500 dark:text-slate-400">{currentSection.description}</p>
            </div>

            <div className="space-y-6">
              {currentSection.items.map((item) => (
                <div key={item.key} className="group">
                  <label className="flex items-center gap-3 mb-3 text-slate-700 dark:text-slate-300 font-semibold">
                    {item.label}
                  </label>
                  <div className="relative">
                    {renderInput(item)}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
