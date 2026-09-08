import { Link, useParams } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

const ARTISTS: Record<string, {
  name: string; type: string; bio: string; fullBio: string;
  heroImage: string; portrait: string;
  instagram: string; facebook: string; youtube: string;
  upcomingEvents: { id: string; name: string; date: string; location: string; image: string }[];
  stats: { label: string; value: string }[];
  genres: string[];
}> = {
  "dj-nyk": {
    name: "DJ NYK",
    type: "Electronic DJ / Producer",
    bio: "One of India's most celebrated DJs, known for electrifying sets across the biggest festivals.",
    fullBio: "DJ NYK (Nikhil Khaitan) has been rocking dance floors for over a decade. Known for his high-energy Bollywood remixes and electronic drops, he has performed at every major festival and nightclub across India. His signature style blends Bollywood, EDM, and Punjabi beats into an unstoppable set that keeps crowds on their feet till dawn.",
    heroImage: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=1400&h=700&fit=crop&auto=format",
    portrait: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=400&h=500&fit=crop&auto=format",
    instagram: "@djnyk",
    facebook: "djnyk",
    youtube: "DJNYK",
    genres: ["EDM", "Bollywood Remix", "Punjabi Beats", "Commercial House"],
    stats: [
      { label: "Shows", value: "500+" },
      { label: "Cities", value: "80+" },
      { label: "Years Active", value: "12+" },
      { label: "Fans", value: "2M+" },
    ],
    upcomingEvents: [
      { id: "navratri-nights", name: "Navratri Nights 2026", date: "17 Oct 2026", location: "Ahmedabad", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=400&h=250&fit=crop&auto=format" },
      { id: "dj-night-goa", name: "DJ Night — Goa Edition", date: "1 Nov 2026", location: "Goa", image: "https://images.unsplash.com/photo-1618176581836-9dcf475e2b4a?w=400&h=250&fit=crop&auto=format" },
    ],
  },
  "falguni-pathak": {
    name: "Falguni Pathak",
    type: "Garba Queen / Folk Singer",
    bio: "The undisputed Queen of Garba, Falguni Pathak has been the soul of Navratri for generations.",
    fullBio: "Falguni Pathak is synonymous with Navratri. Known as the 'Dandiya Queen' and 'Pop Queen of India', she has won millions of hearts with her melodious voice and vibrant performances. Her songs like Maine Payal Hai Chhankaai and Meri Chunar Udd Udd Jaye remain timeless anthems that fill dance floors every Navratri season.",
    heroImage: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=1400&h=700&fit=crop&auto=format",
    portrait: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=400&h=500&fit=crop&auto=format",
    instagram: "@falgunipathak369",
    facebook: "falgunipathak",
    youtube: "FalguniPathak",
    genres: ["Garba", "Dandiya", "Folk Pop", "Bollywood"],
    stats: [
      { label: "Shows", value: "1000+" },
      { label: "Albums", value: "15+" },
      { label: "Years Active", value: "30+" },
      { label: "Fans", value: "10M+" },
    ],
    upcomingEvents: [
      { id: "navratri-nights", name: "Navratri Nights 2026 — Day 1", date: "15 Oct 2026", location: "Ahmedabad", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=400&h=250&fit=crop&auto=format" },
      { id: "navratri-nights", name: "Navratri Nights 2026 — Grand Finale", date: "19 Oct 2026", location: "Ahmedabad", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=400&h=250&fit=crop&auto=format" },
    ],
  },
};

const DEFAULT_ARTIST = ARTISTS["dj-nyk"];

const relatedArtists = [
  { id: "falguni-pathak", name: "Falguni Pathak", type: "Garba Queen", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=200&h=200&fit=crop&auto=format" },
  { id: "b-praak", name: "B Praak", type: "Bollywood Singer", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=200&h=200&fit=crop&auto=format" },
  { id: "kirtidan-gadhvi", name: "Kirtidan Gadhvi", type: "Folk Singer", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=200&h=200&fit=crop&auto=format" },
];

export default function ArtistDetailsPage() {
  const { id } = useParams<{ id: string }>();
  const artist = (id && ARTISTS[id]) ? ARTISTS[id] : DEFAULT_ARTIST;

  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      {/* Hero */}
      <div className="relative h-[70vh] min-h-[500px] overflow-hidden">
        <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${artist.heroImage})` }} />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, #07070e 0%, rgba(7,7,14,0.5) 50%, rgba(7,7,14,0.2) 100%)" }} />
        <div
          className="absolute inset-0 pointer-events-none"
          style={{ background: "radial-gradient(ellipse 60% 80% at 30% 60%, rgba(139,92,246,0.15) 0%, transparent 70%)" }}
        />
      </div>

      {/* Artist card overlapping hero */}
      <div className="max-w-7xl mx-auto px-6" style={{ marginTop: "-180px", position: "relative", zIndex: 10 }}>
        <div className="flex flex-col md:flex-row gap-8 items-end mb-12">
          {/* Portrait */}
          <div
            className="w-40 h-52 md:w-52 md:h-72 rounded-2xl overflow-hidden flex-none"
            style={{
              border: "3px solid rgba(139,92,246,0.4)",
              boxShadow: "0 0 40px rgba(139,92,246,0.3)",
            }}
          >
            <img src={artist.portrait} alt={artist.name} className="w-full h-full object-cover" />
          </div>

          {/* Info */}
          <div className="pb-2">
            <span
              className="inline-block px-3 py-1 rounded-full text-xs font-semibold mb-3"
              style={{ background: "rgba(139,92,246,0.15)", border: "1px solid rgba(139,92,246,0.3)", color: "#c084fc" }}
            >
              {artist.type}
            </span>
            <h1 className="font-display font-black text-5xl md:text-6xl mb-3 leading-none">{artist.name}</h1>
            <p className="text-base max-w-xl mb-5" style={{ color: "rgba(255,255,255,0.6)" }}>{artist.bio}</p>

            {/* Social links */}
            <div className="flex gap-3 flex-wrap">
              <a href={`https://instagram.com/${artist.instagram}`} target="_blank" rel="noopener noreferrer"
                className="flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all hover:scale-105"
                style={{ background: "rgba(228,64,95,0.15)", border: "1px solid rgba(228,64,95,0.3)", color: "#f472b6" }}>
                📸 Instagram
              </a>
              <a href={`https://youtube.com/@${artist.youtube}`} target="_blank" rel="noopener noreferrer"
                className="flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all hover:scale-105"
                style={{ background: "rgba(239,68,68,0.15)", border: "1px solid rgba(239,68,68,0.3)", color: "#f87171" }}>
                ▶ YouTube
              </a>
              <a href={`https://facebook.com/${artist.facebook}`} target="_blank" rel="noopener noreferrer"
                className="flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all hover:scale-105"
                style={{ background: "rgba(59,130,246,0.15)", border: "1px solid rgba(59,130,246,0.3)", color: "#60a5fa" }}>
                👤 Facebook
              </a>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
          <div className="lg:col-span-2 space-y-12">
            {/* Stats */}
            <div className="grid grid-cols-4 gap-4">
              {artist.stats.map((s) => (
                <div key={s.label} className="p-5 rounded-2xl text-center" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
                  <p className="font-display font-black text-3xl mb-1" style={{ background: "linear-gradient(135deg, #a855f7, #ec4899)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
                    {s.value}
                  </p>
                  <p className="text-xs" style={{ color: "rgba(255,255,255,0.45)" }}>{s.label}</p>
                </div>
              ))}
            </div>

            {/* Biography */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-4">About</h2>
              <p className="text-base leading-relaxed" style={{ color: "rgba(255,255,255,0.65)" }}>{artist.fullBio}</p>
            </section>

            {/* Genres */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-4">Genres & Style</h2>
              <div className="flex flex-wrap gap-3">
                {artist.genres.map((g) => (
                  <span key={g} className="px-4 py-2 rounded-full text-sm font-medium"
                    style={{ background: "rgba(139,92,246,0.1)", border: "1px solid rgba(139,92,246,0.2)", color: "#c084fc" }}>
                    {g}
                  </span>
                ))}
              </div>
            </section>

            {/* Upcoming events */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Upcoming Events</h2>
              <div className="space-y-4">
                {artist.upcomingEvents.map((ev, i) => (
                  <Link key={i} to={`/events/${ev.id}`}
                    className="flex gap-4 p-4 rounded-2xl transition-all hover:-translate-y-0.5 group"
                    style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
                    <div className="w-20 h-20 rounded-xl overflow-hidden flex-none bg-vmn-elevated">
                      <img src={ev.image} alt={ev.name} className="w-full h-full object-cover transition-transform group-hover:scale-105" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-sm mb-1 truncate">{ev.name}</h3>
                      <p className="text-xs mb-2" style={{ color: "rgba(255,255,255,0.45)" }}>📅 {ev.date}</p>
                      <p className="text-xs" style={{ color: "rgba(255,255,255,0.45)" }}>📍 {ev.location}</p>
                    </div>
                    <span className="self-center text-xs font-semibold px-3 py-1.5 rounded-full flex-none"
                      style={{ background: "rgba(139,92,246,0.15)", color: "#c084fc", border: "1px solid rgba(139,92,246,0.2)" }}>
                      View →
                    </span>
                  </Link>
                ))}
              </div>
            </section>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Get pass CTA */}
            <div className="p-6 rounded-2xl" style={{ background: "linear-gradient(135deg, rgba(139,92,246,0.12), rgba(236,72,153,0.08))", border: "1px solid rgba(139,92,246,0.2)" }}>
              <h3 className="font-display font-bold text-lg mb-2">Watch Live</h3>
              <p className="text-sm mb-4" style={{ color: "rgba(255,255,255,0.55)" }}>Catch {artist.name} at an upcoming event.</p>
              <Link to="/events" className="block w-full py-3 rounded-xl font-bold text-sm text-center transition-all hover:scale-[1.02]"
                style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)", boxShadow: "0 0 20px rgba(139,92,246,0.3)" }}>
                Browse Events
              </Link>
            </div>

            {/* Related Artists */}
            <div>
              <h3 className="font-display font-bold text-lg mb-4">Other Artists</h3>
              <div className="space-y-3">
                {relatedArtists.map((a) => (
                  <Link key={a.id} to={`/artists/${a.id}`}
                    className="flex items-center gap-3 p-3 rounded-xl transition-all hover:bg-white/5 group"
                    style={{ border: "1px solid rgba(255,255,255,0.06)" }}>
                    <img src={a.image} alt={a.name} className="w-10 h-10 rounded-full object-cover" />
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-sm truncate">{a.name}</p>
                      <p className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>{a.type}</p>
                    </div>
                    <span className="text-white/30 group-hover:text-white/60 transition-colors">→</span>
                  </Link>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-16">
        <Footer />
      </div>
    </div>
  );
}
