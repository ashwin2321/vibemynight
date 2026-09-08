import { Link } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

const HERO_IMG = "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format";
const CTA_IMG = "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=700&fit=crop&auto=format";

const featuredEvents = [
  {
    id: "navratri-nights",
    name: "Navratri Nights 2026",
    location: "Grand Arena, Ahmedabad",
    date: "15–19 Oct 2026",
    artist: "Falguni Pathak & More",
    price: "₹499",
    image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=600&h=400&fit=crop&auto=format",
    badge: "FEATURED",
    badgeColor: "#a855f7",
  },
  {
    id: "celebrity-night",
    name: "Celebrity Night Live",
    location: "Sky Lounge, Mumbai",
    date: "22 Oct 2026",
    artist: "B Praak & Neha Kakkar",
    price: "₹999",
    image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=600&h=400&fit=crop&auto=format",
    badge: "HOT",
    badgeColor: "#ec4899",
  },
  {
    id: "dj-night-goa",
    name: "DJ Night — Goa Edition",
    location: "Beach Club, Goa",
    date: "1 Nov 2026",
    artist: "DJ NYK",
    price: "₹799",
    image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=600&h=400&fit=crop&auto=format",
    badge: "UPCOMING",
    badgeColor: "#3b82f6",
  },
  {
    id: "garba-fest",
    name: "Garba Festival Night",
    location: "Exhibition Ground, Surat",
    date: "16–18 Oct 2026",
    artist: "Kirtidan Gadhvi",
    price: "₹399",
    image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=600&h=400&fit=crop&auto=format",
    badge: "FESTIVAL",
    badgeColor: "#f59e0b",
  },
];

const upcomingEvents = [
  { id: "laser-night", name: "Laser Show Night", location: "GMDC Ground, Ahmedabad", date: "5 Nov 2026", price: "₹599", image: "https://images.unsplash.com/photo-1618176581836-9dcf475e2b4a?w=400&h=280&fit=crop&auto=format" },
  { id: "retro-night", name: "Retro Bollywood Night", location: "Sports Club, Baroda", date: "12 Nov 2026", price: "₹449", image: "https://images.unsplash.com/photo-1545128485-c400e7702796?w=400&h=280&fit=crop&auto=format" },
  { id: "live-concert", name: "Live Unplugged Concert", location: "Open Air Arena, Pune", date: "20 Nov 2026", price: "₹699", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=400&h=280&fit=crop&auto=format" },
  { id: "sufi-night", name: "Sufi Night — Soulful Edition", location: "Palace Grounds, Jaipur", date: "28 Nov 2026", price: "₹549", image: "https://images.unsplash.com/photo-1581417478175-a9ef18f210c2?w=400&h=280&fit=crop&auto=format" },
  { id: "new-year-bash", name: "New Year Bash 2027", location: "Grand Arena, Ahmedabad", date: "31 Dec 2026", price: "₹1,499", image: "https://images.unsplash.com/photo-1598495496118-f8763b94bde5?w=400&h=280&fit=crop&auto=format" },
  { id: "indie-night", name: "Indie Music Night", location: "Social, Bengaluru", date: "8 Jan 2027", price: "₹349", image: "https://images.unsplash.com/photo-1559228461-4fa1e7eb677c?w=400&h=280&fit=crop&auto=format" },
];

const whyCards = [
  { icon: "✦", title: "Discover", desc: "Find amazing events, concerts and festival nights near you." },
  { icon: "★", title: "Experience", desc: "Live artists, laser shows and unforgettable nights." },
  { icon: "◈", title: "Easy Inquiry", desc: "Request your pass in seconds — no complex checkout." },
  { icon: "◆", title: "Trusted", desc: "Simple, transparent booking confirmed via WhatsApp." },
];

const artists = [
  { name: "DJ NYK", type: "DJ / Producer", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=300&h=300&fit=crop&auto=format" },
  { name: "Falguni Pathak", type: "Garba Singer", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=300&h=300&fit=crop&auto=format" },
  { name: "B Praak", type: "Live Singer", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=300&h=300&fit=crop&auto=format" },
  { name: "Neha Kakkar", type: "Pop Singer", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=300&h=300&fit=crop&auto=format" },
  { name: "Kirtidan Gadhvi", type: "Folk Singer", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=300&h=300&fit=crop&auto=format" },
];

const experiences = [
  { label: "Live Singer", icon: "🎤" },
  { label: "Celebrity Night", icon: "⭐" },
  { label: "DJ Night", icon: "🎧" },
  { label: "Laser Show", icon: "✨" },
  { label: "Massive Dance Floor", icon: "💃" },
  { label: "Premium Venue", icon: "🏛️" },
  { label: "Traditional Garba", icon: "🪔" },
];

export default function HomePage() {
  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      {/* HERO */}
      <section className="relative h-screen min-h-[600px] flex items-center overflow-hidden">
        <div
          className="absolute inset-0 bg-center bg-cover"
          style={{ backgroundImage: `url(${HERO_IMG})` }}
        />
        <div
          className="absolute inset-0"
          style={{
            background: "linear-gradient(to right, rgba(7,7,14,0.92) 0%, rgba(7,7,14,0.6) 60%, rgba(7,7,14,0.3) 100%)",
          }}
        />
        {/* Neon accent blob */}
        <div
          className="absolute -top-20 left-1/3 w-96 h-96 rounded-full pointer-events-none"
          style={{
            background: "radial-gradient(circle, rgba(139,92,246,0.15) 0%, transparent 70%)",
            filter: "blur(40px)",
          }}
        />

        <div className="relative z-10 max-w-7xl mx-auto px-6 w-full pt-16">
          <div
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold mb-6"
            style={{
              background: "rgba(139,92,246,0.15)",
              border: "1px solid rgba(139,92,246,0.3)",
              color: "#c084fc",
            }}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-purple-400 animate-pulse" />
            Events Now Live
          </div>
          <h1
            className="font-display font-black leading-none mb-6"
            style={{ fontSize: "clamp(2.5rem, 7vw, 5rem)", maxWidth: 700 }}
          >
            Experience The Night.{" "}
            <span
              style={{
                background: "linear-gradient(135deg, #a855f7 0%, #ec4899 60%, #60a5fa 100%)",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text",
              }}
            >
              Create The Memory.
            </span>
          </h1>
          <p className="text-lg mb-10 max-w-xl" style={{ color: "rgba(255,255,255,0.6)" }}>
            Discover the best events, artists and unforgettable experiences with VibeMyNight.
          </p>
          <div className="flex flex-wrap gap-4">
            <Link
              to="/events"
              className="px-7 py-3.5 rounded-full font-semibold text-base transition-all hover:scale-105"
              style={{
                background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                boxShadow: "0 0 30px rgba(139,92,246,0.4)",
              }}
            >
              Explore Events
            </Link>
            <a
              href="https://wa.me/917041615131"
              target="_blank"
              rel="noopener noreferrer"
              className="px-7 py-3.5 rounded-full font-semibold text-base transition-all hover:bg-white/10"
              style={{
                background: "rgba(255,255,255,0.06)",
                border: "1px solid rgba(255,255,255,0.15)",
              }}
            >
              Get Your Pass
            </a>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1.5 opacity-40">
          <span className="text-xs tracking-widest uppercase">Scroll</span>
          <div className="w-px h-8 bg-white/40" />
        </div>
      </section>

      {/* FEATURED EVENTS */}
      <section className="py-24 max-w-7xl mx-auto px-6">
        <div className="flex items-end justify-between mb-12">
          <div>
            <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#a855f7" }}>
              Don't Miss
            </p>
            <h2 className="font-display font-bold text-4xl">Featured Nights</h2>
            <p className="mt-2 text-base" style={{ color: "rgba(255,255,255,0.5)" }}>
              Discover the most happening events right now.
            </p>
          </div>
          <Link to="/events" className="hidden md:flex items-center gap-2 text-sm font-medium transition-colors hover:text-white" style={{ color: "#a855f7" }}>
            View All <span>→</span>
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {featuredEvents.map((ev) => (
            <EventCard key={ev.id} event={ev} featured />
          ))}
        </div>
      </section>

      {/* UPCOMING EVENTS */}
      <section className="py-10 max-w-7xl mx-auto px-6">
        <div className="flex items-end justify-between mb-10">
          <div>
            <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#60a5fa" }}>
              Calendar
            </p>
            <h2 className="font-display font-bold text-4xl">Upcoming Events</h2>
          </div>
          <Link to="/events" className="hidden md:flex items-center gap-2 text-sm font-medium transition-colors hover:text-white" style={{ color: "#60a5fa" }}>
            View All <span>→</span>
          </Link>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {upcomingEvents.map((ev) => (
            <UpcomingCard key={ev.id} event={ev} />
          ))}
        </div>
      </section>

      {/* WHY VIBEMYNIGHT */}
      <section className="py-24 max-w-7xl mx-auto px-6">
        <div className="text-center mb-14">
          <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#ec4899" }}>
            Why Us
          </p>
          <h2 className="font-display font-bold text-4xl">Why VibeMyNight?</h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {whyCards.map((card) => (
            <div
              key={card.title}
              className="p-7 rounded-2xl transition-all hover:-translate-y-1"
              style={{
                background: "rgba(255,255,255,0.03)",
                border: "1px solid rgba(255,255,255,0.07)",
              }}
            >
              <div
                className="w-11 h-11 rounded-xl flex items-center justify-center text-xl mb-5"
                style={{ background: "rgba(139,92,246,0.12)", border: "1px solid rgba(139,92,246,0.2)" }}
              >
                {card.icon}
              </div>
              <h3 className="font-display font-bold text-lg mb-2">{card.title}</h3>
              <p className="text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.5)" }}>{card.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* FEATURED ARTISTS */}
      <section className="py-16 max-w-7xl mx-auto px-6">
        <div className="text-center mb-12">
          <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#a855f7" }}>
            Lineup
          </p>
          <h2 className="font-display font-bold text-4xl">Featured Artists</h2>
        </div>
        <div className="flex gap-5 overflow-x-auto scrollbar-hide pb-4">
          {artists.map((a) => (
            <div
              key={a.name}
              className="flex-none w-48 rounded-2xl overflow-hidden transition-all hover:-translate-y-1 cursor-pointer"
              style={{ border: "1px solid rgba(255,255,255,0.07)" }}
            >
              <div className="aspect-square overflow-hidden bg-vmn-elevated">
                <img
                  src={a.image}
                  alt={a.name}
                  className="w-full h-full object-cover transition-transform hover:scale-105"
                />
              </div>
              <div className="p-4">
                <p className="font-display font-semibold text-sm">{a.name}</p>
                <p className="text-xs mt-0.5" style={{ color: "rgba(255,255,255,0.45)" }}>{a.type}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* EVENT EXPERIENCES */}
      <section className="py-16 max-w-7xl mx-auto px-6">
        <div className="text-center mb-12">
          <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#60a5fa" }}>
            What Awaits
          </p>
          <h2 className="font-display font-bold text-4xl">Event Experiences</h2>
        </div>
        <div className="flex flex-wrap justify-center gap-4">
          {experiences.map((exp) => (
            <div
              key={exp.label}
              className="flex items-center gap-3 px-5 py-3 rounded-full transition-all hover:-translate-y-0.5"
              style={{
                background: "rgba(255,255,255,0.04)",
                border: "1px solid rgba(255,255,255,0.09)",
              }}
            >
              <span className="text-xl">{exp.icon}</span>
              <span className="font-medium text-sm">{exp.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FINAL CTA */}
      <section className="relative py-28 overflow-hidden my-10 mx-6 rounded-3xl">
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{ backgroundImage: `url(${CTA_IMG})` }}
        />
        <div
          className="absolute inset-0"
          style={{ background: "linear-gradient(135deg, rgba(7,7,14,0.92) 0%, rgba(139,92,246,0.35) 100%)" }}
        />
        <div className="relative z-10 text-center px-6">
          <h2
            className="font-display font-black text-5xl md:text-6xl mb-6 leading-tight"
            style={{
              background: "linear-gradient(135deg, #fff 0%, #c084fc 60%, #f472b6 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
            }}
          >
            YOUR NEXT NIGHT<br />STARTS HERE
          </h2>
          <p className="mb-8 text-lg" style={{ color: "rgba(255,255,255,0.6)" }}>
            Don't wait. Your unforgettable experience is one click away.
          </p>
          <Link
            to="/events"
            className="inline-block px-10 py-4 rounded-full font-bold text-lg transition-all hover:scale-105"
            style={{
              background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
              boxShadow: "0 0 40px rgba(139,92,246,0.5)",
            }}
          >
            Explore Events
          </Link>
        </div>
      </section>

      <Footer />
    </div>
  );
}

function EventCard({ event, featured }: { event: typeof featuredEvents[0]; featured?: boolean }) {
  return (
    <Link to={`/events/${event.id}`} className="group block">
      <div
        className="rounded-2xl overflow-hidden transition-all duration-300 hover:-translate-y-1.5"
        style={{
          background: "#12122a",
          border: "1px solid rgba(255,255,255,0.07)",
          boxShadow: "0 8px 32px rgba(0,0,0,0.4)",
        }}
      >
        <div className="relative aspect-[4/3] overflow-hidden bg-vmn-elevated">
          <img
            src={event.image}
            alt={event.name}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgba(7,7,14,0.7) 0%, transparent 60%)" }} />
          <span
            className="absolute top-3 left-3 px-2.5 py-1 rounded-full text-xs font-bold"
            style={{ background: event.badgeColor, color: "#fff" }}
          >
            {event.badge}
          </span>
        </div>
        <div className="p-4">
          <h3 className="font-display font-bold text-base leading-snug mb-1">{event.name}</h3>
          <p className="text-xs mb-3" style={{ color: "rgba(255,255,255,0.45)" }}>
            📍 {event.location}
          </p>
          <div className="flex items-center justify-between text-xs mb-4" style={{ color: "rgba(255,255,255,0.5)" }}>
            <span>📅 {event.date}</span>
            <span>🎤 {event.artist.split(" ")[0]}</span>
          </div>
          <div className="flex items-center justify-between">
            <div>
              <span className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>from </span>
              <span className="font-bold text-base" style={{ color: "#a855f7" }}>{event.price}</span>
            </div>
            <span
              className="px-3 py-1.5 rounded-full text-xs font-semibold"
              style={{ background: "rgba(139,92,246,0.15)", color: "#c084fc", border: "1px solid rgba(139,92,246,0.2)" }}
            >
              View Event
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}

function UpcomingCard({ event }: { event: typeof upcomingEvents[0] }) {
  return (
    <Link to={`/events/${event.id}`} className="group flex gap-4 p-4 rounded-2xl transition-all hover:-translate-y-0.5" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
      <div className="w-20 h-20 rounded-xl overflow-hidden flex-none bg-vmn-elevated">
        <img src={event.image} alt={event.name} className="w-full h-full object-cover transition-transform group-hover:scale-105" />
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="font-display font-semibold text-sm leading-snug mb-1 truncate">{event.name}</h3>
        <p className="text-xs mb-1.5 truncate" style={{ color: "rgba(255,255,255,0.4)" }}>📍 {event.location}</p>
        <div className="flex items-center justify-between">
          <span className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>📅 {event.date}</span>
          <span className="font-bold text-sm" style={{ color: "#a855f7" }}>{event.price}</span>
        </div>
      </div>
    </Link>
  );
}
