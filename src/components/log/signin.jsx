// components/User/log/signin.jsx
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/useAuth";
import { Mail, Lock } from "lucide-react";

export default function LoginPage() {
  const [animating, setAnimating] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const navigate = useNavigate();
  const { login } = useAuth();

  useEffect(() => {
    document.title = "Admin Sign In | UniConnect";
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      await login({ email, password });
      setAnimating(true);
      setTimeout(() => navigate("/dashboard"), 500);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center bg-slate-900 text-white overflow-hidden">

      {/* Background blobs */}
     
     

      {/* Card */}
 <div
  className={`relative z-10 w-[96%] max-w-[720px] p-[100px_60px_80px] rounded-[48px] 
  border border-white/10 bg-white/5 backdrop-blur-[40px] text-center 
  shadow-[0_100px_100px_rgba(0,0,0,0.1)] transition-all duration-700
  ${animating ? "scale-95 opacity-0" : "scale-100 opacity-100"}`}
>
       

        <h2 className="mb-10 text-4xl font-semibold">Welcome Admin</h2>

        {/* Error */}
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-400 p-3 rounded-lg mb-6 text-xs">
            {error}
          </div>
        )}

        {/* Form */}
        <form className="grid gap-5" onSubmit={handleLogin}>

          {/* Email */}
          <div className="relative">
            <Mail className="absolute left-5 top-1/2 -translate-y-1/2 text-white/50 w-5 h-5" />
            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
              className="w-full h-14 rounded-full bg-white/5 text-white placeholder-white/30 pl-12 pr-6 outline-none"
              required
            />
          </div>

          {/* Password */}
          <div className="relative">
            <Lock className="absolute left-5 top-1/2 -translate-y-1/2 text-white/50 w-5 h-5" />
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
              className="w-full h-14 rounded-full bg-white/5 text-white placeholder-white/30 pl-12 pr-6 outline-none"
              required
            />
          </div>

          {/* Options */}
          <div className="flex items-center justify-between text-xs text-gray-400">
            <label className="flex items-center space-x-2">
              <input
                type="checkbox"
                className="accent-[#6a65ff]"
                disabled={loading}
              />
              <span>Remember me</span>
            </label>

            <button
              type="button"
              className="hover:text-white"
              disabled={loading}
            >
              Forgot password?
            </button>
          </div>

          {/* Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full h-14 rounded-full bg-orange-500 hover:bg-[#864d06] transition font-medium disabled:opacity-50"
          >
            {loading ? "Signing in..." : "Sign In"}
          </button>
        </form>

        
      </div>
    </div>
  );
}
