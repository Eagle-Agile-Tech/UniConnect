// components/User/log/signin.jsx
import { useState } from "react";
import { Mail, Lock } from "lucide-react";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    
    // Simulate API call
    setTimeout(() => {
      if (email === "admin@example.com" && password === "admin123") {
        console.log("Login successful");
        setLoading(false);
      } else {
        setError("Invalid email or password");
        setLoading(false);
      }
    }, 1500);
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 text-white overflow-hidden">
      
      {/* Animated Background Blobs */}
      <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] bg-purple-600 rounded-full mix-blend-multiply filter blur-[128px] opacity-70 animate-blob"></div>
      <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-orange-500 rounded-full mix-blend-multiply filter blur-[128px] opacity-70 animate-blob animation-delay-2000"></div>
      <div className="absolute bottom-[-10%] left-1/2 transform -translate-x-1/2 w-[500px] h-[500px] bg-pink-600 rounded-full mix-blend-multiply filter blur-[128px] opacity-70 animate-blob animation-delay-4000"></div>
      
      {/* Glass Card */}
      <div className="relative z-10 w-[96%] max-w-[720px] p-[60px_50px_70px] rounded-[48px] border border-white/10 bg-white/5 backdrop-blur-[40px] text-center shadow-[0_100px_100px_rgba(0,0,0,0.1)] transition-all duration-500 hover:scale-[1.02]">
        
        {/* Logo/Icon */}
        <div className="mb-6 flex justify-center">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-orange-500 to-purple-600 flex items-center justify-center">
            <span className="text-3xl font-bold">U</span>
          </div>
        </div>
        
        <h2 className="mb-4 text-4xl font-semibold bg-gradient-to-r from-white to-gray-400 bg-clip-text text-transparent">
          Welcome Admin
        </h2>
        <p className="mb-10 text-gray-400 text-sm">Sign in to access your dashboard</p>

        {/* Error Message */}
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-400 p-3 rounded-lg mb-6 text-sm animate-shake">
            ❌ {error}
          </div>
        )}

        {/* Form */}
        <form className="grid gap-5" onSubmit={handleLogin}>
          
          {/* Email Input */}
          <div className="relative group">
            <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-white/50 w-5 h-5 group-focus-within:text-orange-500 transition-colors" />
            <input
              type="email"
              placeholder="Email address"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
              className="w-full h-14 rounded-full bg-white/5 text-white placeholder-white/30 pl-12 pr-6 outline-none focus:bg-white/10 focus:ring-2 focus:ring-orange-500 transition-all"
              required
            />
          </div>

          {/* Password Input */}
          <div className="relative group">
            <Lock className="absolute left-5 top-1/2 -translate-y-1/2 text-white/50 w-5 h-5 group-focus-within:text-orange-500 transition-colors" />
            <input
              type={showPassword ? "text" : "password"}
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
              className="w-full h-14 rounded-full bg-white/5 text-white placeholder-white/30 pl-12 pr-12 outline-none focus:bg-white/10 focus:ring-2 focus:ring-orange-500 transition-all"
              required
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-5 top-1/2 -translate-y-1/2 text-white/50 hover:text-white"
            >
              {showPassword ? "👁️" : "👁️‍🗨️"}
            </button>
          </div>

          {/* Options */}
          <div className="flex items-center justify-between text-sm text-gray-400">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="w-4 h-4 rounded border-white/20 bg-white/5 accent-orange-500 cursor-pointer"
                disabled={loading}
              />
              <span className="select-none">Remember me</span>
            </label>

            <button
              type="button"
              className="hover:text-orange-500 transition-colors"
              disabled={loading}
            >
              Forgot password?
            </button>
          </div>

          {/* Sign In Button */}
          <button
            type="submit"
            disabled={loading}
            className="relative w-full h-14 rounded-full bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 transition-all font-medium disabled:opacity-50 disabled:cursor-not-allowed overflow-hidden group"
          >
            <span className={`relative z-10 ${loading ? 'opacity-0' : 'opacity-100'}`}>
              Sign In
            </span>
            {loading && (
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              </div>
            )}
          </button>
        </form>

        {/* Demo Credentials */}
        <div className="mt-8 pt-6 border-t border-white/10">
          <p className="text-xs text-gray-500 mb-2">Demo Credentials:</p>
          <div className="text-xs text-gray-400 space-y-1">
            <p>📧 Email: admin@example.com</p>
            <p>🔑 Password: admin123</p>
          </div>
        </div>
      </div>

      {/* Add these styles to your global CSS or tailwind.config.js */}
      <style jsx>{`
        @keyframes blob {
          0%, 100% { transform: translate(0px, 0px) scale(1); }
          33% { transform: translate(30px, -50px) scale(1.1); }
          66% { transform: translate(-20px, 20px) scale(0.9); }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
        .animation-delay-4000 {
          animation-delay: 4s;
        }
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-10px); }
          75% { transform: translateX(10px); }
        }
        .animate-shake {
          animation: shake 0.3s ease-in-out;
        }
      `}</style>
    </div>
  );
}