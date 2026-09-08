import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import VmnLogo from "./VmnLogo";

const navItems = [
  { to: "/admin/dashboard", label: "Dashboard", icon: "◈" },
  { to: "/admin/events", label: "Events", icon: "🎪" },
  { to: "/admin/artists", label: "Artists", icon: "🎤" },
  { to: "/admin/facilities", label: "Facilities", icon: "🏛️" },
  { to: "/admin/inquiries", label: "Inquiries", icon: "📋" },
  { to: "/admin/settings", label: "Settings", icon: "⚙️" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className="min-h-screen flex" style={{ background: "#07070e" }}>
      {/* Sidebar */}
      <aside
        className="fixed top-0 left-0 h-screen flex flex-col z-40 transition-all duration-300"
        style={{
          width: collapsed ? 64 : 220,
          background: "#0d0d1f",
          borderRight: "1px solid rgba(255,255,255,0.07)",
        }}
      >
        <div className="flex items-center justify-between px-4 h-16" style={{ borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
          {!collapsed && <VmnLogo size="sm" />}
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="w-7 h-7 flex items-center justify-center rounded-lg text-sm transition-colors hover:bg-white/10"
            style={{ color: "rgba(255,255,255,0.5)", marginLeft: collapsed ? "auto" : 0, marginRight: collapsed ? "auto" : 0 }}
          >
            {collapsed ? "→" : "←"}
          </button>
        </div>

        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map(({ to, label, icon }) => {
            const active = location.pathname === to;
            return (
              <Link
                key={to}
                to={to}
                title={collapsed ? label : undefined}
                className="flex items-center gap-3 px-4 py-3 mx-2 rounded-xl text-sm font-medium transition-all hover:bg-white/5 mb-0.5"
                style={
                  active
                    ? { background: "rgba(139,92,246,0.15)", color: "#c084fc", border: "1px solid rgba(139,92,246,0.2)" }
                    : { color: "rgba(255,255,255,0.5)", border: "1px solid transparent" }
                }
              >
                <span className="text-base flex-none">{icon}</span>
                {!collapsed && <span>{label}</span>}
              </Link>
            );
          })}
        </nav>

        <div className="p-3" style={{ borderTop: "1px solid rgba(255,255,255,0.06)" }}>
          <button
            onClick={() => navigate("/admin/login")}
            className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-sm font-medium transition-all hover:bg-white/5"
            style={{ color: "rgba(255,255,255,0.4)" }}
          >
            <span className="text-base">↩</span>
            {!collapsed && <span>Logout</span>}
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div
        className="flex-1 flex flex-col min-h-screen transition-all duration-300"
        style={{ marginLeft: collapsed ? 64 : 220 }}
      >
        {/* Top bar */}
        <header
          className="sticky top-0 z-30 h-16 flex items-center justify-between px-6"
          style={{
            background: "rgba(7,7,14,0.92)",
            backdropFilter: "blur(12px)",
            borderBottom: "1px solid rgba(255,255,255,0.06)",
          }}
        >
          <div className="relative">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5" style={{ color: "rgba(255,255,255,0.35)" }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
            </svg>
            <input
              type="text"
              placeholder="Search…"
              className="pl-9 pr-4 py-2 rounded-lg text-sm outline-none w-56"
              style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", color: "#fff" }}
            />
          </div>
          <div className="flex items-center gap-3">
            <button className="w-8 h-8 rounded-full flex items-center justify-center relative" style={{ background: "rgba(255,255,255,0.06)" }}>
              <span className="text-sm">🔔</span>
              <span className="absolute -top-0.5 -right-0.5 w-3.5 h-3.5 rounded-full text-[9px] flex items-center justify-center font-bold" style={{ background: "#ec4899" }}>3</span>
            </button>
            <div className="w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm" style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)" }}>
              A
            </div>
          </div>
        </header>

        <main className="flex-1 p-6 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
