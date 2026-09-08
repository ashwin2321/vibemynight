import { useState } from "react";
import AdminLayout from "@/components/AdminLayout";

const ARTIST_TYPES = ["DJ / Producer", "Garba Singer", "Bollywood Singer", "Folk Singer", "Pop Singer", "Live Band", "Classical"];

const initialArtists = [
  { id: 1, name: "DJ NYK", type: "DJ / Producer", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=80&h=80&fit=crop&auto=format", featured: true, status: "ACTIVE", instagram: "@djnyk", events: 3 },
  { id: 2, name: "Falguni Pathak", type: "Garba Singer", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=80&h=80&fit=crop&auto=format", featured: true, status: "ACTIVE", instagram: "@falgunipathak369", events: 2 },
  { id: 3, name: "B Praak", type: "Bollywood Singer", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=80&h=80&fit=crop&auto=format", featured: false, status: "ACTIVE", instagram: "@bpraak", events: 1 },
  { id: 4, name: "Neha Kakkar", type: "Pop Singer", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=80&h=80&fit=crop&auto=format", featured: false, status: "ACTIVE", instagram: "@nehakakkar", events: 1 },
  { id: 5, name: "Kirtidan Gadhvi", type: "Folk Singer", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=80&h=80&fit=crop&auto=format", featured: false, status: "ACTIVE", instagram: "@kirtidangadhvi", events: 2 },
  { id: 6, name: "Aishwarya Majmudar", type: "Bollywood Singer", image: "https://images.unsplash.com/photo-1574892591041-905fbbd00515?w=80&h=80&fit=crop&auto=format", featured: false, status: "INACTIVE", instagram: "@aishwaryam", events: 0 },
];

type Artist = typeof initialArtists[0];

const EMPTY_FORM = { name: "", type: "DJ / Producer", instagram: "", facebook: "", youtube: "", shortBio: "", fullBio: "", featured: false, status: "ACTIVE" };

export default function AdminArtistsPage() {
  const [artists, setArtists] = useState(initialArtists);
  const [search, setSearch] = useState("");
  const [view, setView] = useState<"grid" | "table">("grid");
  const [modal, setModal] = useState<"create" | "edit" | null>(null);
  const [editing, setEditing] = useState<Artist | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [confirmDelete, setConfirmDelete] = useState<number | null>(null);

  const filtered = artists.filter((a) =>
    a.name.toLowerCase().includes(search.toLowerCase()) || a.type.toLowerCase().includes(search.toLowerCase())
  );

  function openCreate() {
    setForm(EMPTY_FORM);
    setEditing(null);
    setModal("create");
  }

  function openEdit(a: Artist) {
    setForm({ name: a.name, type: a.type, instagram: a.instagram, facebook: "", youtube: "", shortBio: "", fullBio: "", featured: a.featured, status: a.status });
    setEditing(a);
    setModal("edit");
  }

  function saveForm() {
    if (modal === "create") {
      setArtists([...artists, { id: Date.now(), name: form.name || "New Artist", type: form.type, image: "https://images.unsplash.com/photo-1574892591041-905fbbd00515?w=80&h=80&fit=crop&auto=format", featured: form.featured, status: form.status, instagram: form.instagram, events: 0 }]);
    } else if (editing) {
      setArtists(artists.map((a) => a.id === editing.id ? { ...a, name: form.name, type: form.type, featured: form.featured, status: form.status, instagram: form.instagram } : a));
    }
    setModal(null);
  }

  return (
    <AdminLayout>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-display font-bold text-2xl">Artists</h1>
          <p className="text-sm mt-0.5" style={{ color: "rgba(255,255,255,0.45)" }}>{artists.length} artists in the system</p>
        </div>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all hover:scale-105"
          style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)" }}
        >
          + Add Artist
        </button>
      </div>

      {/* Toolbar */}
      <div className="p-4 rounded-2xl mb-5 flex flex-wrap items-center gap-3" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
        <div className="relative flex-1 min-w-48">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5" style={{ color: "rgba(255,255,255,0.4)" }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
          <input type="text" placeholder="Search artists…" value={search} onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2.5 rounded-xl text-sm outline-none"
            style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", color: "#fff" }} />
        </div>
        <div className="flex gap-1 p-1 rounded-lg" style={{ background: "rgba(255,255,255,0.05)" }}>
          {(["grid", "table"] as const).map((v) => (
            <button key={v} onClick={() => setView(v)}
              className="px-3 py-1.5 rounded-md text-xs font-medium transition-all capitalize"
              style={view === v ? { background: "rgba(139,92,246,0.3)", color: "#c084fc" } : { color: "rgba(255,255,255,0.45)" }}>
              {v === "grid" ? "⊞ Grid" : "☰ Table"}
            </button>
          ))}
        </div>
      </div>

      {/* Grid view */}
      {view === "grid" ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {filtered.map((a) => (
            <div key={a.id} className="rounded-2xl overflow-hidden transition-all hover:-translate-y-1"
              style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
              <div className="relative aspect-square overflow-hidden">
                <img src={a.image} alt={a.name} className="w-full h-full object-cover" />
                <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgba(7,7,14,0.8) 0%, transparent 60%)" }} />
                {a.featured && (
                  <span className="absolute top-2 right-2 px-2 py-0.5 rounded-full text-xs font-bold"
                    style={{ background: "#a855f7", color: "#fff" }}>★</span>
                )}
                <span className={`absolute top-2 left-2 px-2 py-0.5 rounded-full text-xs font-bold`}
                  style={{ background: a.status === "ACTIVE" ? "rgba(34,197,94,0.9)" : "rgba(107,114,128,0.9)", color: "#fff" }}>
                  {a.status}
                </span>
              </div>
              <div className="p-3">
                <p className="font-semibold text-sm truncate">{a.name}</p>
                <p className="text-xs mb-3 truncate" style={{ color: "rgba(255,255,255,0.45)" }}>{a.type}</p>
                <p className="text-xs mb-3" style={{ color: "rgba(255,255,255,0.35)" }}>{a.events} event{a.events !== 1 ? "s" : ""}</p>
                <div className="flex gap-1.5">
                  <button onClick={() => openEdit(a)}
                    className="flex-1 py-1.5 rounded-lg text-xs font-medium transition-all hover:bg-white/10"
                    style={{ background: "rgba(255,255,255,0.06)", color: "rgba(255,255,255,0.8)" }}>
                    Edit
                  </button>
                  <button onClick={() => setConfirmDelete(a.id)}
                    className="py-1.5 px-2.5 rounded-lg text-xs transition-all hover:bg-red-500/20"
                    style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}>
                    ✕
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl overflow-hidden" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.07)" }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
                {["Artist", "Type", "Events", "Featured", "Status", "Actions"].map((h) => (
                  <th key={h} className="text-left px-5 py-4 text-xs font-semibold" style={{ color: "rgba(255,255,255,0.4)" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((a) => (
                <tr key={a.id} className="transition-colors hover:bg-white/[0.02]" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <img src={a.image} alt={a.name} className="w-10 h-10 rounded-full object-cover flex-none" />
                      <div>
                        <p className="font-medium">{a.name}</p>
                        <p className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>{a.instagram}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>{a.type}</td>
                  <td className="px-5 py-4 text-xs" style={{ color: "rgba(255,255,255,0.6)" }}>{a.events}</td>
                  <td className="px-5 py-4">
                    {a.featured ? <span className="text-yellow-400 text-sm">★ Featured</span> : <span style={{ color: "rgba(255,255,255,0.25)" }}>—</span>}
                  </td>
                  <td className="px-5 py-4">
                    <span className="px-2.5 py-1 rounded-full text-xs font-bold"
                      style={{ background: a.status === "ACTIVE" ? "rgba(34,197,94,0.15)" : "rgba(107,114,128,0.15)", color: a.status === "ACTIVE" ? "#22c55e" : "#6b7280" }}>
                      {a.status}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex gap-2">
                      <button onClick={() => openEdit(a)}
                        className="px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-white/10 transition-all"
                        style={{ background: "rgba(255,255,255,0.06)", color: "rgba(255,255,255,0.8)" }}>
                        Edit
                      </button>
                      <button onClick={() => setConfirmDelete(a.id)}
                        className="px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-red-500/20 transition-all"
                        style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}>
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Create / Edit Modal */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(6px)" }}>
          <div className="w-full max-w-lg rounded-2xl overflow-y-auto max-h-[90vh]" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.1)" }}>
            <div className="flex items-center justify-between p-6 sticky top-0" style={{ background: "#12122a", borderBottom: "1px solid rgba(255,255,255,0.07)" }}>
              <h2 className="font-display font-bold text-xl">{modal === "create" ? "Add Artist" : "Edit Artist"}</h2>
              <button onClick={() => setModal(null)} className="text-white/40 hover:text-white text-xl">✕</button>
            </div>

            <div className="p-6 space-y-4">
              <FormField label="Name *" value={form.name} onChange={(v) => setForm({ ...form, name: v })} placeholder="Artist full name" />
              <div>
                <label className="block text-xs font-semibold mb-2" style={{ color: "rgba(255,255,255,0.55)" }}>Type *</label>
                <select value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}
                  className="w-full px-3 py-3 rounded-xl text-sm outline-none"
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }}>
                  {ARTIST_TYPES.map((t) => <option key={t} value={t} style={{ background: "#12122a" }}>{t}</option>)}
                </select>
              </div>
              <FormField label="Instagram" value={form.instagram} onChange={(v) => setForm({ ...form, instagram: v })} placeholder="@handle" />
              <FormField label="Facebook" value={form.facebook} onChange={(v) => setForm({ ...form, facebook: v })} placeholder="Facebook page name" />
              <FormField label="YouTube" value={form.youtube} onChange={(v) => setForm({ ...form, youtube: v })} placeholder="YouTube channel" />
              <div>
                <label className="block text-xs font-semibold mb-2" style={{ color: "rgba(255,255,255,0.55)" }}>Short Bio</label>
                <textarea rows={2} value={form.shortBio} onChange={(e) => setForm({ ...form, shortBio: e.target.value })} placeholder="One-line bio..."
                  className="w-full px-3 py-3 rounded-xl text-sm outline-none resize-none"
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }} />
              </div>
              <div>
                <label className="block text-xs font-semibold mb-2" style={{ color: "rgba(255,255,255,0.55)" }}>Full Bio</label>
                <textarea rows={4} value={form.fullBio} onChange={(e) => setForm({ ...form, fullBio: e.target.value })} placeholder="Detailed biography..."
                  className="w-full px-3 py-3 rounded-xl text-sm outline-none resize-none"
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }} />
              </div>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.featured} onChange={(e) => setForm({ ...form, featured: e.target.checked })}
                    className="w-4 h-4 rounded accent-purple-500" />
                  <span style={{ color: "rgba(255,255,255,0.7)" }}>Featured Artist</span>
                </label>
                <label className="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" checked={form.status === "ACTIVE"} onChange={(e) => setForm({ ...form, status: e.target.checked ? "ACTIVE" : "INACTIVE" })}
                    className="w-4 h-4 rounded accent-green-500" />
                  <span style={{ color: "rgba(255,255,255,0.7)" }}>Active</span>
                </label>
              </div>
            </div>

            <div className="flex gap-3 p-6 pt-0">
              <button onClick={() => setModal(null)}
                className="flex-1 py-3 rounded-xl text-sm font-semibold"
                style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}>
                Cancel
              </button>
              <button onClick={saveForm}
                className="flex-1 py-3 rounded-xl text-sm font-semibold transition-all hover:scale-[1.02]"
                style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)" }}>
                {modal === "create" ? "Add Artist" : "Save Changes"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete confirm */}
      {confirmDelete !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(4px)" }}>
          <div className="p-6 rounded-2xl w-80" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.1)" }}>
            <h3 className="font-bold text-lg mb-2">Remove Artist?</h3>
            <p className="text-sm mb-6" style={{ color: "rgba(255,255,255,0.5)" }}>This will remove the artist from the system.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirmDelete(null)}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}>Cancel</button>
              <button onClick={() => { setArtists(artists.filter((a) => a.id !== confirmDelete)); setConfirmDelete(null); }}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold"
                style={{ background: "#ef4444" }}>Remove</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}

function FormField({ label, value, onChange, placeholder }: { label: string; value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div>
      <label className="block text-xs font-semibold mb-2" style={{ color: "rgba(255,255,255,0.55)" }}>{label}</label>
      <input type="text" value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
        className="w-full px-3 py-3 rounded-xl text-sm outline-none"
        style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }} />
    </div>
  );
}
