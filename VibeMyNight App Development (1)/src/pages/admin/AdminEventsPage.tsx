import { useState } from "react";
import { Link } from "react-router-dom";
import AdminLayout from "@/components/AdminLayout";

const events = [
  { id: 1, name: "Navratri Nights 2026", dates: "15–19 Oct 2026", days: 5, location: "Ahmedabad", status: "LIVE", statusColor: "#22c55e", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=60&h=60&fit=crop&auto=format" },
  { id: 2, name: "Celebrity Night Live", dates: "22 Oct 2026", days: 1, location: "Mumbai", status: "UPCOMING", statusColor: "#60a5fa", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=60&h=60&fit=crop&auto=format" },
  { id: 3, name: "DJ Night — Goa Edition", dates: "1 Nov 2026", days: 1, location: "Goa", status: "UPCOMING", statusColor: "#60a5fa", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=60&h=60&fit=crop&auto=format" },
  { id: 4, name: "Garba Festival Night", dates: "16–18 Oct 2026", days: 3, location: "Surat", status: "LIVE", statusColor: "#22c55e", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=60&h=60&fit=crop&auto=format" },
  { id: 5, name: "Summer Beats Festival", dates: "5 Oct 2026", days: 1, location: "Jaipur", status: "SOLD OUT", statusColor: "#6b7280", image: "https://images.unsplash.com/photo-1559228461-4fa1e7eb677c?w=60&h=60&fit=crop&auto=format" },
  { id: 6, name: "New Year Bash 2027", dates: "31 Dec 2026", days: 1, location: "Ahmedabad", status: "DRAFT", statusColor: "#f59e0b", image: "https://images.unsplash.com/photo-1598495496118-f8763b94bde5?w=60&h=60&fit=crop&auto=format" },
];

export default function AdminEventsPage() {
  const [search, setSearch] = useState("");
  const [confirm, setConfirm] = useState<number | null>(null);

  const filtered = events.filter((e) =>
    e.name.toLowerCase().includes(search.toLowerCase()) || e.location.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <AdminLayout>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-display font-bold text-2xl">Events</h1>
          <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.45)" }}>Manage all events</p>
        </div>
        <Link
          to="/admin/events/create"
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all hover:scale-105"
          style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)" }}
        >
          + Create Event
        </Link>
      </div>

      {/* Search + filters */}
      <div className="p-5 rounded-2xl mb-5" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
        <div className="flex flex-wrap gap-3">
          <div className="relative flex-1 min-w-52">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5" style={{ color: "rgba(255,255,255,0.4)" }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
            </svg>
            <input
              type="text"
              placeholder="Search events…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2.5 rounded-xl text-sm outline-none"
              style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", color: "#fff" }}
            />
          </div>
          {["All", "Live", "Upcoming", "Draft", "Sold Out"].map((f) => (
            <button key={f} className="px-3 py-2 rounded-lg text-xs font-medium transition-all hover:bg-white/10" style={{ background: "rgba(255,255,255,0.05)", color: "rgba(255,255,255,0.6)" }}>
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="rounded-2xl overflow-hidden" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
              {["Event", "Dates", "Days", "Location", "Status", "Actions"].map((h) => (
                <th key={h} className="text-left px-5 py-4 text-xs font-semibold" style={{ color: "rgba(255,255,255,0.4)" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map((ev) => (
              <tr key={ev.id} className="transition-colors hover:bg-white/[0.02]" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <img src={ev.image} alt={ev.name} className="w-10 h-10 rounded-lg object-cover flex-none" />
                    <span className="font-medium">{ev.name}</span>
                  </div>
                </td>
                <td className="px-5 py-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>{ev.dates}</td>
                <td className="px-5 py-4">
                  <span className="px-2 py-1 rounded-lg text-xs font-semibold" style={{ background: "rgba(139,92,246,0.1)", color: "#c084fc" }}>
                    {ev.days} {ev.days === 1 ? "Day" : "Days"}
                  </span>
                </td>
                <td className="px-5 py-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>📍 {ev.location}</td>
                <td className="px-5 py-4">
                  <span className="px-2.5 py-1 rounded-full text-xs font-bold" style={{ background: `${ev.statusColor}20`, color: ev.statusColor }}>
                    {ev.status}
                  </span>
                </td>
                <td className="px-5 py-4">
                  <div className="flex gap-1.5">
                    {["View", "Edit", "Days"].map((action) => (
                      <button
                        key={action}
                        className="px-2.5 py-1 rounded-lg text-xs font-medium transition-all hover:bg-white/10"
                        style={{ background: "rgba(255,255,255,0.05)", color: "rgba(255,255,255,0.7)" }}
                      >
                        {action}
                      </button>
                    ))}
                    <button
                      onClick={() => setConfirm(ev.id)}
                      className="px-2.5 py-1 rounded-lg text-xs font-medium transition-all hover:bg-red-500/20"
                      style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Delete confirm modal */}
      {confirm !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)" }}>
          <div className="p-6 rounded-2xl w-80" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.1)" }}>
            <h3 className="font-bold text-lg mb-2">Delete Event?</h3>
            <p className="text-sm mb-6" style={{ color: "rgba(255,255,255,0.5)" }}>This action cannot be undone.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirm(null)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold" style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}>Cancel</button>
              <button onClick={() => setConfirm(null)} className="flex-1 py-2.5 rounded-xl text-sm font-semibold" style={{ background: "#ef4444" }}>Delete</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
