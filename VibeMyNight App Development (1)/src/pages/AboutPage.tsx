import { Link } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

const ABOUT_IMG = "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=900&h=600&fit=crop&auto=format";

const stats = [
  { value: "50+", label: "Events Hosted" },
  { value: "20K+", label: "Happy Attendees" },
  { value: "100+", label: "Artists Featured" },
  { value: "5★", label: "Average Rating" },
];

const values = [
  { icon: "⚡", title: "Energy First", desc: "We curate only the most electric, high-energy events that leave you wanting more." },
  { icon: "🎯", title: "Precision Curation", desc: "Every event is handpicked for quality, safety, and an unforgettable experience." },
  { icon: "🔒", title: "Safe & Trusted", desc: "Transparent pricing, no hidden fees, and direct confirmation via WhatsApp." },
  { icon: "🌟", title: "Premium Experience", desc: "From premium venues to world-class artists, we never compromise on quality." },
];

export default function AboutPage() {
  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      {/* Hero */}
      <div className="relative pt-32 pb-24 overflow-hidden">
        <div
          className="absolute inset-0 opacity-10"
          style={{ backgroundImage: `url(${ABOUT_IMG})`, backgroundSize: "cover", backgroundPosition: "center" }}
        />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to bottom, rgba(7,7,14,0.7) 0%, #07070e 100%)" }} />
        <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
          <p className="text-xs font-semibold tracking-widest uppercase mb-3" style={{ color: "#a855f7" }}>Our Story</p>
          <h1 className="font-display font-black text-5xl md:text-6xl mb-6 leading-tight">
            We Live for{" "}
            <span style={{ background: "linear-gradient(135deg, #a855f7, #ec4899)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
              The Night
            </span>
          </h1>
          <p className="text-lg leading-relaxed" style={{ color: "rgba(255,255,255,0.6)", maxWidth: 600, margin: "0 auto" }}>
            VibeMyNight was born from a simple belief: every night has the potential to become a memory you cherish forever. We're here to make that happen.
          </p>
        </div>
      </div>

      {/* Stats */}
      <div className="max-w-5xl mx-auto px-6 mb-20">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-5">
          {stats.map((s) => (
            <div key={s.label} className="p-6 rounded-2xl text-center" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
              <p className="font-display font-black text-4xl mb-1" style={{ background: "linear-gradient(135deg, #a855f7, #ec4899)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>{s.value}</p>
              <p className="text-sm" style={{ color: "rgba(255,255,255,0.5)" }}>{s.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Mission */}
      <div className="max-w-5xl mx-auto px-6 mb-20">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
          <div>
            <p className="text-xs font-semibold tracking-widest uppercase mb-3" style={{ color: "#ec4899" }}>Mission</p>
            <h2 className="font-display font-bold text-4xl mb-5">Creating Nights Worth Living</h2>
            <p className="leading-relaxed mb-5" style={{ color: "rgba(255,255,255,0.6)" }}>
              From traditional Navratri Garba festivals to cutting-edge DJ nights, celebrity concerts to laser shows — VibeMyNight is your one destination for experiences that go beyond the ordinary.
            </p>
            <p className="leading-relaxed" style={{ color: "rgba(255,255,255,0.6)" }}>
              We work with top artists, premier venues, and event organizers across India to bring you curated nightlife experiences with seamless pass inquiry via WhatsApp.
            </p>
          </div>
          <div className="rounded-2xl overflow-hidden" style={{ aspectRatio: "4/3" }}>
            <img src={ABOUT_IMG} alt="Crowd at event" className="w-full h-full object-cover" />
          </div>
        </div>
      </div>

      {/* Values */}
      <div className="max-w-5xl mx-auto px-6 mb-20">
        <p className="text-xs font-semibold tracking-widest uppercase mb-3 text-center" style={{ color: "#60a5fa" }}>Values</p>
        <h2 className="font-display font-bold text-4xl text-center mb-12">What We Stand For</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          {values.map((v) => (
            <div key={v.title} className="flex gap-5 p-6 rounded-2xl" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
              <span className="text-3xl flex-none">{v.icon}</span>
              <div>
                <h3 className="font-display font-bold text-lg mb-1">{v.title}</h3>
                <p className="text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.5)" }}>{v.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="max-w-3xl mx-auto px-6 pb-24 text-center">
        <h2 className="font-display font-bold text-4xl mb-5">Ready to Experience a Night?</h2>
        <p className="mb-8 text-lg" style={{ color: "rgba(255,255,255,0.5)" }}>Browse upcoming events and get your pass in minutes.</p>
        <Link
          to="/events"
          className="inline-block px-10 py-4 rounded-full font-bold text-lg transition-all hover:scale-105"
          style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)", boxShadow: "0 0 30px rgba(139,92,246,0.35)" }}
        >
          Explore Events
        </Link>
      </div>

      <Footer />
    </div>
  );
}
