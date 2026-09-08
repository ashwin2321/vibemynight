import { useState } from "react";
import { Link } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

const allEvents = [
  { id: "navratri-nights", name: "Navratri Nights 2026", location: "Grand Arena, Ahmedabad", date: "15–19 Oct 2026", artist: "Falguni Pathak & More", price: "₹499", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=500&h=350&fit=crop&auto=format", badge: "FEATURED", badgeColor: "#a855f7", status: "upcoming", tags: ["featured", "festival"] },
  { id: "celebrity-night", name: "Celebrity Night Live", location: "Sky Lounge, Mumbai", date: "22 Oct 2026", artist: "B Praak & Neha Kakkar", price: "₹999", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=500&h=350&fit=crop&auto=format", badge: "HOT", badgeColor: "#ec4899", status: "upcoming", tags: ["featured", "nightlife"] },
  { id: "dj-night-goa", name: "DJ Night — Goa Edition", location: "Beach Club, Goa", date: "1 Nov 2026", artist: "DJ NYK", price: "₹799", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=500&h=350&fit=crop&auto=format", badge: "UPCOMING", badgeColor: "#3b82f6", status: "upcoming", tags: ["nightlife"] },
  { id: "garba-fest", name: "Garba Festival Night", location: "Exhibition Ground, Surat", date: "16–18 Oct 2026", artist: "Kirtidan Gadhvi", price: "₹399", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=500&h=350&fit=crop&auto=format", badge: "FESTIVAL", badgeColor: "#f59e0b", status: "upcoming", tags: ["festival"] },
  { id: "laser-night", name: "Laser Show Night", location: "GMDC Ground, Ahmedabad", date: "5 Nov 2026", artist: "Various Artists", price: "₹599", image: "https://images.unsplash.com/photo-1618176581836-9dcf475e2b4a?w=500&h=350&fit=crop&auto=format", badge: "UPCOMING", badgeColor: "#3b82f6", status: "upcoming", tags: ["nightlife"] },
  { id: "retro-night", name: "Retro Bollywood Night", location: "Sports Club, Baroda", date: "12 Nov 2026", artist: "DJ Suketu", price: "₹449", image: "https://images.unsplash.com/photo-1545128485-c400e7702796?w=500&h=350&fit=crop&auto=format", badge: "UPCOMING", badgeColor: "#3b82f6", status: "upcoming", tags: ["nightlife"] },
  { id: "live-concert", name: "Live Unplugged Concert", location: "Open Air Arena, Pune", date: "20 Nov 2026", artist: "Arijit Singh", price: "₹699", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=500&h=350&fit=crop&auto=format", badge: "FEATURED", badgeColor: "#a855f7", status: "upcoming", tags: ["featured"] },
  { id: "new-year-bash", name: "New Year Bash 2027", location: "Grand Arena, Ahmedabad", date: "31 Dec 2026", artist: "Neha Kakkar + DJ NYK", price: "₹1,499", image: "https://images.unsplash.com/photo-1598495496118-f8763b94bde5?w=500&h=350&fit=crop&auto=format", badge: "HOT", badgeColor: "#ec4899", status: "upcoming", tags: ["featured", "nightlife"] },
  { id: "sold-out-event", name: "Summer Beats Festival", location: "Palace Grounds, Jaipur", date: "5 Oct 2026", artist: "Various DJs", price: "₹899", image: "https://images.unsplash.com/photo-1559228461-4fa1e7eb677c?w=500&h=350&fit=crop&auto=format", badge: "SOLD OUT", badgeColor: "#6b7280", status: "soldout", tags: ["festival"] },
];

const filterOptions = ["All", "Upcoming", "Featured", "Festival", "Nightlife", "Sold Out"];

export default function EventsPage() {
  const [search, setSearch] = useState("");
  const [activeFilter, setActiveFilter] = useState("All");

  const filtered = allEvents.filter((ev) => {
    const matchesSearch = ev.name.toLowerCase().includes(search.toLowerCase()) || ev.location.toLowerCase().includes(search.toLowerCase());
    const matchesFilter =
      activeFilter === "All" ||
      (activeFilter === "Upcoming" && ev.status === "upcoming") ||
      (activeFilter === "Sold Out" && ev.status === "soldout") ||
      ev.tags.includes(activeFilter.toLowerCase());
    return matchesSearch && matchesFilter;
  });

  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      {/* Page header */}
      <div className="pt-32 pb-12 max-w-7xl mx-auto px-6">
        <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#a855f7" }}>
          All Events
        </p>
        <h1 className="font-display font-black text-5xl mb-4">Explore Events</h1>
        <p style={{ color: "rgba(255,255,255,0.5)" }}>Discover the nights worth living.</p>
      </div>

      {/* Search + Filters */}
      <div className="max-w-7xl mx-auto px-6 mb-10">
        <div className="relative mb-5">
          <svg className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4" style={{ color: "rgba(255,255,255,0.4)" }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
          <input
            type="text"
            placeholder="Search events, cities…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-3.5 rounded-xl text-sm outline-none transition-all"
            style={{
              background: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.09)",
              color: "#fff",
            }}
          />
        </div>

        <div className="flex gap-2.5 overflow-x-auto scrollbar-hide pb-1">
          {filterOptions.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className="flex-none px-4 py-2 rounded-full text-sm font-medium transition-all"
              style={
                activeFilter === f
                  ? { background: "linear-gradient(135deg, #8b5cf6, #ec4899)", color: "#fff" }
                  : { background: "rgba(255,255,255,0.05)", color: "rgba(255,255,255,0.6)", border: "1px solid rgba(255,255,255,0.09)" }
              }
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Events grid */}
      <div className="max-w-7xl mx-auto px-6 pb-24">
        {filtered.length === 0 ? (
          <div className="text-center py-24">
            <div className="text-6xl mb-4">🎭</div>
            <h3 className="font-display font-bold text-2xl mb-2">No events found</h3>
            <p style={{ color: "rgba(255,255,255,0.4)" }}>Try adjusting your search or filters.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
            {filtered.map((ev) => (
              <Link key={ev.id} to={`/events/${ev.id}`} className="group block">
                <div
                  className="rounded-2xl overflow-hidden transition-all duration-300 hover:-translate-y-1.5 h-full"
                  style={{
                    background: "#12122a",
                    border: "1px solid rgba(255,255,255,0.07)",
                    opacity: ev.status === "soldout" ? 0.7 : 1,
                  }}
                >
                  <div className="relative overflow-hidden" style={{ aspectRatio: "16/10" }}>
                    <img src={ev.image} alt={ev.name} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                    <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgba(7,7,14,0.7) 0%, transparent 60%)" }} />
                    <span className="absolute top-3 left-3 px-2.5 py-1 rounded-full text-xs font-bold" style={{ background: ev.badgeColor, color: "#fff" }}>
                      {ev.badge}
                    </span>
                    {ev.status === "soldout" && (
                      <div className="absolute inset-0 flex items-center justify-center">
                        <span className="px-4 py-2 rounded-full font-bold text-sm" style={{ background: "rgba(0,0,0,0.7)", border: "1px solid rgba(255,255,255,0.2)" }}>
                          SOLD OUT
                        </span>
                      </div>
                    )}
                  </div>
                  <div className="p-4">
                    <h3 className="font-display font-bold text-base leading-snug mb-1">{ev.name}</h3>
                    <p className="text-xs mb-2 truncate" style={{ color: "rgba(255,255,255,0.45)" }}>📍 {ev.location}</p>
                    <div className="text-xs mb-3 flex justify-between" style={{ color: "rgba(255,255,255,0.4)" }}>
                      <span>📅 {ev.date}</span>
                    </div>
                    <div className="flex items-center justify-between pt-3" style={{ borderTop: "1px solid rgba(255,255,255,0.06)" }}>
                      <div>
                        <span className="text-xs" style={{ color: "rgba(255,255,255,0.35)" }}>from </span>
                        <span className="font-bold text-base" style={{ color: ev.status === "soldout" ? "rgba(255,255,255,0.3)" : "#a855f7" }}>{ev.price}</span>
                      </div>
                      {ev.status !== "soldout" && (
                        <span className="px-3 py-1 rounded-full text-xs font-semibold" style={{ background: "rgba(139,92,246,0.15)", color: "#c084fc", border: "1px solid rgba(139,92,246,0.2)" }}>
                          Get Pass
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      <Footer />
    </div>
  );
}
