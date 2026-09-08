import { useState } from "react";
import AdminLayout from "@/components/AdminLayout";

const STATUSES = ["NEW", "CONTACTED", "CONFIRMED", "CANCELLED", "COMPLETED"];

const inquiries = [
  { id: "VMN-001847", name: "Raj Patel", mobile: "+91 98765 43210", event: "Navratri Nights 2026", day: "Day 2", pass: "VIP", qty: 2, total: 1998, status: "NEW", date: "5 Sep 2026", message: "Looking for VIP experience with wife." },
  { id: "VMN-001846", name: "Priya Shah", mobile: "+91 99887 76655", event: "Celebrity Night Live", day: "Day 1", pass: "Couple", qty: 1, total: 2998, status: "CONFIRMED", date: "4 Sep 2026", message: "Anniversary celebration. Need front row." },
  { id: "VMN-001845", name: "Amit Joshi", mobile: "+91 70123 45678", event: "DJ Night Goa", day: "Day 1", pass: "Regular", qty: 3, total: 2397, status: "CONTACTED", date: "4 Sep 2026", message: "Group booking for college friends." },
  { id: "VMN-001844", name: "Neha Mehta", mobile: "+91 88001 23456", event: "Navratri Nights 2026", day: "Day 4", pass: "VIP", qty: 1, total: 1499, status: "CONFIRMED", date: "3 Sep 2026", message: "" },
  { id: "VMN-001843", name: "Vikram Singh", mobile: "+91 77123 89010", event: "Garba Fest Night", day: "Day 1", pass: "Regular", qty: 2, total: 798, status: "CANCELLED", date: "3 Sep 2026", message: "" },
  { id: "VMN-001842", name: "Sonal Desai", mobile: "+91 95432 10987", event: "Navratri Nights 2026", day: "Day 1", pass: "Couple", qty: 1, total: 1499, status: "NEW", date: "2 Sep 2026", message: "First time attending. Any tips?" },
  { id: "VMN-001841", name: "Karan Mehta", mobile: "+91 91234 56789", event: "Celebrity Night Live", day: "Day 1", pass: "VIP", qty: 2, total: 1998, status: "COMPLETED", date: "1 Sep 2026", message: "" },
];

const statusColors: Record<string, string> = {
  NEW: "#a855f7", CONTACTED: "#60a5fa", CONFIRMED: "#22c55e", CANCELLED: "#ef4444", COMPLETED: "#6b7280",
};

export default function AdminInquiriesPage() {
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("All");
  const [selected, setSelected] = useState<typeof inquiries[0] | null>(null);
  const [status, setStatus] = useState("");

  const filtered = inquiries.filter((i) => {
    const s = search.toLowerCase();
    const matches = i.name.toLowerCase().includes(s) || i.id.toLowerCase().includes(s) || i.event.toLowerCase().includes(s);
    const statusMatch = filterStatus === "All" || i.status === filterStatus;
    return matches && statusMatch;
  });

  return (
    <AdminLayout>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-display font-bold text-2xl">Inquiries</h1>
          <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.45)" }}>Manage pass inquiries</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-bold" style={{ background: "rgba(139,92,246,0.15)", color: "#c084fc", border: "1px solid rgba(139,92,246,0.2)" }}>
          {inquiries.filter((i) => i.status === "NEW").length} new
        </div>
      </div>

      {/* Filters */}
      <div className="p-4 rounded-2xl mb-5 flex flex-wrap gap-3" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
        <div className="relative flex-1 min-w-48">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5" style={{ color: "rgba(255,255,255,0.4)" }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
          <input
            type="text"
            placeholder="Search by name, ID, event…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2.5 rounded-xl text-sm outline-none"
            style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", color: "#fff" }}
          />
        </div>
        <div className="flex gap-2">
          {["All", ...STATUSES].map((s) => (
            <button
              key={s}
              onClick={() => setFilterStatus(s)}
              className="px-3 py-2 rounded-lg text-xs font-medium transition-all"
              style={filterStatus === s ? { background: "linear-gradient(135deg, #8b5cf6, #ec4899)", color: "#fff" } : { background: "rgba(255,255,255,0.05)", color: "rgba(255,255,255,0.6)" }}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-5">
        {/* Table */}
        <div className={`${selected ? "lg:col-span-3" : "lg:col-span-5"} rounded-2xl overflow-hidden`} style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
                {["ID", "Customer", "Event", "Pass", "Total", "Status", "Date"].map((h) => (
                  <th key={h} className="text-left px-4 py-3.5 text-xs font-semibold" style={{ color: "rgba(255,255,255,0.4)" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((row) => (
                <tr
                  key={row.id}
                  onClick={() => { setSelected(row); setStatus(row.status); }}
                  className="cursor-pointer transition-colors hover:bg-white/[0.03]"
                  style={{
                    borderBottom: "1px solid rgba(255,255,255,0.04)",
                    background: selected?.id === row.id ? "rgba(139,92,246,0.07)" : undefined,
                  }}
                >
                  <td className="px-4 py-3.5 font-mono text-xs" style={{ color: "#c084fc" }}>{row.id}</td>
                  <td className="px-4 py-3.5 font-medium text-sm">{row.name}</td>
                  <td className="px-4 py-3.5 text-xs" style={{ color: "rgba(255,255,255,0.55)" }}>{row.event.split(" ").slice(0, 2).join(" ")}</td>
                  <td className="px-4 py-3.5 text-xs" style={{ color: "rgba(255,255,255,0.55)" }}>{row.pass}</td>
                  <td className="px-4 py-3.5 font-bold text-sm" style={{ color: "#a855f7" }}>₹{row.total.toLocaleString()}</td>
                  <td className="px-4 py-3.5">
                    <span className="px-2 py-1 rounded-full text-xs font-bold" style={{ background: `${statusColors[row.status]}20`, color: statusColors[row.status] }}>
                      {row.status}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>{row.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Detail panel */}
        {selected && (
          <div className="lg:col-span-2 p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
            <div className="flex items-start justify-between mb-5">
              <div>
                <p className="font-mono text-xs mb-0.5" style={{ color: "#c084fc" }}>{selected.id}</p>
                <h3 className="font-display font-bold text-lg">{selected.name}</h3>
                <p className="text-xs" style={{ color: "rgba(255,255,255,0.45)" }}>{selected.mobile}</p>
              </div>
              <button onClick={() => setSelected(null)} className="text-white/40 hover:text-white text-lg">✕</button>
            </div>

            <div className="space-y-3 mb-5 p-4 rounded-xl" style={{ background: "rgba(255,255,255,0.03)" }}>
              {[
                ["Event", selected.event],
                ["Day", selected.day],
                ["Pass", selected.pass],
                ["Quantity", String(selected.qty)],
                ["Total", `₹${selected.total.toLocaleString()}`],
                ["Date", selected.date],
              ].map(([k, v]) => (
                <div key={k} className="flex justify-between text-sm">
                  <span style={{ color: "rgba(255,255,255,0.4)" }}>{k}</span>
                  <span className="font-semibold">{v}</span>
                </div>
              ))}
            </div>

            {selected.message && (
              <div className="mb-5 p-3 rounded-xl text-sm" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.06)", color: "rgba(255,255,255,0.6)" }}>
                "{selected.message}"
              </div>
            )}

            <div className="mb-4">
              <label className="block text-xs font-semibold mb-2" style={{ color: "rgba(255,255,255,0.5)" }}>Update Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl text-sm outline-none"
                style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }}
              >
                {STATUSES.map((s) => (
                  <option key={s} value={s} style={{ background: "#12122a" }}>{s}</option>
                ))}
              </select>
            </div>

            <button
              className="w-full py-3 rounded-xl font-semibold text-sm mb-2.5 transition-all hover:scale-[1.02]"
              style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)" }}
            >
              Update Status
            </button>
            <a
              href={`https://wa.me/${selected.mobile.replace(/\D/g, "")}?text=Hi+${selected.name}%2C+your+pass+inquiry+${selected.id}+has+been+${status.toLowerCase()}.`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 w-full py-3 rounded-xl font-semibold text-sm transition-all hover:scale-[1.02]"
              style={{ background: "rgba(37,211,102,0.1)", border: "1px solid rgba(37,211,102,0.2)", color: "#25D366" }}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" /></svg>
              Open WhatsApp
            </a>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
