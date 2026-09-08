import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import AdminLayout from "@/components/AdminLayout";

const stats = [
  { label: "Total Events", value: "12", sub: "+2 this month", color: "#a855f7" },
  { label: "Upcoming Events", value: "8", sub: "Next: 15 Oct", color: "#60a5fa" },
  { label: "Event Days", value: "34", sub: "Across all events", color: "#ec4899" },
  { label: "Artists", value: "47", sub: "+5 new", color: "#f59e0b" },
  { label: "Pass Types", value: "28", sub: "Active passes", color: "#22c55e" },
  { label: "New Inquiries", value: "156", sub: "+23 today", color: "#a855f7" },
  { label: "Confirmed", value: "98", sub: "63% conversion", color: "#22c55e" },
  { label: "Inquiry Value", value: "₹2.4L", sub: "Est. this month", color: "#ec4899" },
];

const trendData = [
  { date: "Sep 1", inquiries: 12 },
  { date: "Sep 5", inquiries: 19 },
  { date: "Sep 10", inquiries: 15 },
  { date: "Sep 15", inquiries: 27 },
  { date: "Sep 20", inquiries: 34 },
  { date: "Sep 25", inquiries: 28 },
  { date: "Sep 30", inquiries: 42 },
  { date: "Oct 5", inquiries: 38 },
  { date: "Oct 10", inquiries: 51 },
];

const statusData = [
  { name: "Confirmed", value: 98, color: "#22c55e" },
  { name: "New", value: 56, color: "#a855f7" },
  { name: "Contacted", value: 32, color: "#60a5fa" },
  { name: "Cancelled", value: 14, color: "#ef4444" },
];

const demandData = [
  { name: "Navratri Nights", inquiries: 89 },
  { name: "Celebrity Night", inquiries: 45 },
  { name: "DJ Night Goa", inquiries: 37 },
  { name: "Garba Fest", inquiries: 31 },
  { name: "Laser Night", inquiries: 22 },
];

const passData = [
  { name: "Regular", sales: 210 },
  { name: "VIP", sales: 87 },
  { name: "Couple", sales: 54 },
  { name: "Early Bird", sales: 32 },
];

const recentInquiries = [
  { id: "VMN-001847", name: "Raj Patel", event: "Navratri Nights", pass: "VIP", total: "₹1,998", status: "NEW", statusColor: "#a855f7" },
  { id: "VMN-001846", name: "Priya Shah", event: "Celebrity Night", pass: "Couple", total: "₹2,998", status: "CONFIRMED", statusColor: "#22c55e" },
  { id: "VMN-001845", name: "Amit Joshi", event: "DJ Night Goa", pass: "Regular", total: "₹799", status: "CONTACTED", statusColor: "#60a5fa" },
  { id: "VMN-001844", name: "Neha Mehta", event: "Navratri Nights", pass: "VIP", total: "₹999", status: "CONFIRMED", statusColor: "#22c55e" },
  { id: "VMN-001843", name: "Vikram Singh", event: "Garba Fest", pass: "Regular", total: "₹399", status: "CANCELLED", statusColor: "#ef4444" },
];

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="px-3 py-2 rounded-lg text-xs" style={{ background: "#1a1a35", border: "1px solid rgba(255,255,255,0.1)" }}>
      <p style={{ color: "rgba(255,255,255,0.5)" }}>{label}</p>
      <p className="font-bold" style={{ color: "#a855f7" }}>{payload[0].value}</p>
    </div>
  );
};

export default function AdminDashboardPage() {
  return (
    <AdminLayout>
      <div className="mb-6">
        <h1 className="font-display font-bold text-2xl">Dashboard</h1>
        <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.45)" }}>Welcome back — here's what's happening.</p>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {stats.map((s) => (
          <div key={s.label} className="p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
            <p className="text-xs mb-1" style={{ color: "rgba(255,255,255,0.45)" }}>{s.label}</p>
            <p className="font-display font-black text-2xl mb-1" style={{ color: s.color }}>{s.value}</p>
            <p className="text-xs" style={{ color: "rgba(255,255,255,0.35)" }}>{s.sub}</p>
          </div>
        ))}
      </div>

      {/* Charts row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5 mb-5">
        {/* Inquiry trend */}
        <div className="lg:col-span-2 p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <h3 className="font-semibold text-sm mb-4">Inquiry Trend</h3>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={trendData}>
              <CartesianGrid stroke="rgba(255,255,255,0.05)" strokeDasharray="4 4" />
              <XAxis dataKey="date" tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 10 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 10 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Line type="monotone" dataKey="inquiries" stroke="#a855f7" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Status pie */}
        <div className="p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <h3 className="font-semibold text-sm mb-4">Inquiry Status</h3>
          <ResponsiveContainer width="100%" height={120}>
            <PieChart>
              <Pie data={statusData} cx="50%" cy="50%" innerRadius={35} outerRadius={55} dataKey="value" strokeWidth={0}>
                {statusData.map((entry, i) => (
                  <Cell key={i} fill={entry.color} />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
          <div className="grid grid-cols-2 gap-1 mt-2">
            {statusData.map((s) => (
              <div key={s.name} className="flex items-center gap-1.5 text-xs">
                <span className="w-2 h-2 rounded-full flex-none" style={{ background: s.color }} />
                <span style={{ color: "rgba(255,255,255,0.5)" }}>{s.name}</span>
                <span className="ml-auto font-semibold">{s.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Charts row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-8">
        <div className="p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <h3 className="font-semibold text-sm mb-4">Event Demand</h3>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={demandData} layout="vertical">
              <XAxis type="number" tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 10 }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fill: "rgba(255,255,255,0.5)", fontSize: 10 }} axisLine={false} tickLine={false} width={110} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="inquiries" fill="#a855f7" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div className="p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <h3 className="font-semibold text-sm mb-4">Pass Demand</h3>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={passData}>
              <CartesianGrid stroke="rgba(255,255,255,0.05)" strokeDasharray="4 4" />
              <XAxis dataKey="name" tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: "rgba(255,255,255,0.35)", fontSize: 10 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="sales" fill="#ec4899" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent inquiries */}
      <div className="p-5 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-sm">Recent Inquiries</h3>
          <a href="/admin/inquiries" className="text-xs font-medium" style={{ color: "#a855f7" }}>View all →</a>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.06)" }}>
                {["ID", "Customer", "Event", "Pass", "Total", "Status"].map((h) => (
                  <th key={h} className="text-left pb-3 pr-4 text-xs font-semibold" style={{ color: "rgba(255,255,255,0.4)" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {recentInquiries.map((row) => (
                <tr key={row.id} style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
                  <td className="py-3 pr-4 font-mono text-xs" style={{ color: "#c084fc" }}>{row.id}</td>
                  <td className="py-3 pr-4 font-medium">{row.name}</td>
                  <td className="py-3 pr-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>{row.event}</td>
                  <td className="py-3 pr-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>{row.pass}</td>
                  <td className="py-3 pr-4 font-bold" style={{ color: "#a855f7" }}>{row.total}</td>
                  <td className="py-3">
                    <span className="px-2 py-1 rounded-full text-xs font-bold" style={{ background: `${row.statusColor}20`, color: row.statusColor }}>
                      {row.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </AdminLayout>
  );
}
