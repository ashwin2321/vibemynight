import { useState } from "react";
import { useNavigate } from "react-router-dom";
import VmnLogo from "@/components/VmnLogo";

const BG = "https://images.unsplash.com/photo-1578736641330-3155e606cd40?w=900&h=1100&fit=crop&auto=format";

export default function AdminLoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (!email || !password) { setError("Please enter your credentials."); return; }
    setLoading(true);
    setTimeout(() => navigate("/admin/dashboard"), 1000);
  }

  return (
    <div className="min-h-screen grid grid-cols-1 md:grid-cols-2">
      {/* Left: Brand panel */}
      <div className="hidden md:flex relative overflow-hidden">
        <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${BG})` }} />
        <div className="absolute inset-0" style={{ background: "linear-gradient(135deg, rgba(7,7,14,0.85) 0%, rgba(139,92,246,0.3) 100%)" }} />
        <div className="relative z-10 flex flex-col justify-end p-12">
          <VmnLogo size="lg" />
          <h2 className="font-display font-black text-4xl mt-6 mb-3 leading-tight">
            Admin Portal
          </h2>
          <p className="text-base" style={{ color: "rgba(255,255,255,0.6)" }}>
            Manage events, artists, passes, and inquiries from one place.
          </p>
        </div>
      </div>

      {/* Right: Login form */}
      <div
        className="flex items-center justify-center p-8"
        style={{ background: "#07070e" }}
      >
        <div className="w-full max-w-sm">
          <div className="md:hidden mb-8 flex justify-center">
            <VmnLogo size="md" />
          </div>

          <h1 className="font-display font-bold text-3xl mb-1">Welcome back</h1>
          <p className="text-sm mb-8" style={{ color: "rgba(255,255,255,0.45)" }}>Sign in to your admin account</p>

          {error && (
            <div className="mb-4 p-3 rounded-xl text-sm" style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.3)", color: "#f87171" }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2" style={{ color: "rgba(255,255,255,0.7)" }}>Email</label>
              <input
                type="email"
                placeholder="admin@vibemynight.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3.5 rounded-xl text-sm outline-none transition-all"
                style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2" style={{ color: "rgba(255,255,255,0.7)" }}>Password</label>
              <input
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3.5 rounded-xl text-sm outline-none transition-all"
                style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }}
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full py-4 rounded-xl font-bold text-base transition-all hover:scale-[1.02] mt-2 disabled:opacity-60"
              style={{
                background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                boxShadow: "0 0 24px rgba(139,92,246,0.3)",
              }}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Signing in…
                </span>
              ) : "Sign In"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
