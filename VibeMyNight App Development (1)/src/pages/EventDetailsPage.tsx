import { useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

const EVENT_DATA = {
  id: "navratri-nights",
  name: "Navratri Nights 2026",
  tagline: "5 Epic Nights. Unlimited Garba. Unforgettable Artists.",
  location: "Grand Arena, Ahmedabad",
  city: "Ahmedabad, Gujarat",
  venue: "Grand Arena",
  address: "Near GMDC Ground, Ahmedabad",
  organizer: "VibeMyNight Events",
  description: "Experience the grandest Navratri celebration ever. Five nights of traditional Garba, live singers, laser shows, and premium vibes at the iconic Grand Arena. Thousands of dancers, world-class lighting, and memories that last forever.",
  heroImage: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=1600&h=700&fit=crop&auto=format",
  gallery: [
    "https://images.unsplash.com/photo-1578736641330-3155e606cd40?w=800&h=600&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&h=600&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1598495496118-f8763b94bde5?w=800&h=600&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=800&h=600&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&h=600&fit=crop&auto=format",
    "https://images.unsplash.com/photo-1618176581836-9dcf475e2b4a?w=800&h=600&fit=crop&auto=format",
  ],
  highlights: ["Live Singer", "Traditional Garba", "Laser Show", "DJ Night", "Premium Venue", "Massive Dance Floor"],
  facilities: ["Parking", "Food & Beverages", "VIP Area", "Security", "CCTV", "First Aid", "Washrooms", "Drinking Water", "Family Friendly"],
  days: [
    { day: 1, date: "15 OCT", fullDate: "15 October 2026", program: "Opening Garba Night", time: "08:00 PM — 01:00 AM", artists: [{ name: "Falguni Pathak", type: "Garba Queen", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=200&h=200&fit=crop&auto=format" }], passes: [{ name: "Regular", price: 499, available: 500, benefits: ["General entry", "Dance floor access"] }, { name: "VIP", price: 999, available: 100, benefits: ["Priority entry", "VIP zone", "Refreshments"] }, { name: "Couple", price: 1499, available: 50, benefits: ["2 tickets", "VIP zone", "Special seating"] }] },
    { day: 2, date: "16 OCT", fullDate: "16 October 2026", program: "Garba Night", time: "09:00 PM — 12:00 AM", artists: [{ name: "Kirtidan Gadhvi", type: "Folk Singer", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=200&h=200&fit=crop&auto=format" }, { name: "Aishwarya Majmudar", type: "Playback Singer", image: "https://images.unsplash.com/photo-1526218626217-dc65a29bb444?w=200&h=200&fit=crop&auto=format" }], passes: [{ name: "Regular", price: 499, available: 420, benefits: ["General entry", "Dance floor access"] }, { name: "VIP", price: 999, available: 7, benefits: ["Priority entry", "VIP zone", "Refreshments"] }, { name: "Couple", price: 1499, available: 0, benefits: ["2 tickets", "VIP zone", "Special seating"] }] },
    { day: 3, date: "17 OCT", fullDate: "17 October 2026", program: "DJ & Laser Night", time: "09:00 PM — 02:00 AM", artists: [{ name: "DJ NYK", type: "Electronic DJ", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=200&h=200&fit=crop&auto=format" }], passes: [{ name: "Regular", price: 599, available: 350, benefits: ["General entry", "Dance floor access"] }, { name: "VIP", price: 1199, available: 80, benefits: ["Priority entry", "VIP zone", "Refreshments"] }, { name: "Couple", price: 1799, available: 30, benefits: ["2 tickets", "VIP zone", "Special seating"] }] },
    { day: 4, date: "18 OCT", fullDate: "18 October 2026", program: "Celebrity Night", time: "08:00 PM — 12:00 AM", artists: [{ name: "B Praak", type: "Bollywood Singer", image: "https://images.unsplash.com/photo-1581417478175-a9ef18f210c2?w=200&h=200&fit=crop&auto=format" }, { name: "Neha Kakkar", type: "Pop Singer", image: "https://images.unsplash.com/photo-1603646316167-f29f06f51475?w=200&h=200&fit=crop&auto=format" }], passes: [{ name: "Regular", price: 799, available: 300, benefits: ["General entry", "Dance floor access"] }, { name: "VIP", price: 1499, available: 60, benefits: ["Priority entry", "VIP zone", "Refreshments"] }, { name: "Couple", price: 2199, available: 25, benefits: ["2 tickets", "VIP zone", "Special seating"] }] },
    { day: 5, date: "19 OCT", fullDate: "19 October 2026", program: "Grand Finale Night", time: "08:00 PM — 03:00 AM", artists: [{ name: "Falguni Pathak", type: "Garba Queen", image: "https://images.unsplash.com/photo-1603646315107-acbf16a28c6e?w=200&h=200&fit=crop&auto=format" }, { name: "Kirtidan Gadhvi", type: "Folk Singer", image: "https://images.unsplash.com/photo-1595422656857-ced3a4a0ce25?w=200&h=200&fit=crop&auto=format" }, { name: "DJ NYK", type: "Electronic DJ", image: "https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=200&h=200&fit=crop&auto=format" }], passes: [{ name: "Regular", price: 899, available: 200, benefits: ["General entry", "Dance floor access"] }, { name: "VIP", price: 1799, available: 40, benefits: ["Priority entry", "VIP zone", "Refreshments"] }, { name: "Couple", price: 2599, available: 15, benefits: ["2 tickets", "VIP zone", "Special seating"] }] },
  ],
  faqs: [
    { q: "Is this event family friendly?", a: "Yes, families and children are welcome. We have a dedicated family zone." },
    { q: "What is the dress code?", a: "Traditional attire (chaniya choli / kurta) is preferred but not mandatory." },
    { q: "Can I get a refund?", a: "All pass inquiries are final. Contact our WhatsApp for special cases." },
    { q: "Is food available at the venue?", a: "Yes, a variety of food stalls will be available inside the venue." },
  ],
  rules: ["No outside food or beverages", "Traditional attire preferred", "No smoking inside dance area", "Age limit: 10+ years", "Carry a valid ID proof"],
};

export default function EventDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const event = EVENT_DATA; // use same event for all IDs as demo

  const [selectedDay, setSelectedDay] = useState(0);
  const [selectedPass, setSelectedPass] = useState<number | null>(null);
  const [qty, setQty] = useState(1);
  const [galleryIdx, setGalleryIdx] = useState(0);
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [openRule, setOpenRule] = useState(false);

  const day = event.days[selectedDay];
  const pass = selectedPass !== null ? day.passes[selectedPass] : null;
  const total = pass ? pass.price * qty : 0;

  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      {/* HERO */}
      <div className="relative h-[60vh] min-h-[400px] overflow-hidden">
        <div className="absolute inset-0 bg-cover bg-center" style={{ backgroundImage: `url(${event.heroImage})` }} />
        <div className="absolute inset-0" style={{ background: "linear-gradient(to top, #07070e 0%, rgba(7,7,14,0.5) 50%, rgba(7,7,14,0.2) 100%)" }} />
        <div className="absolute bottom-0 left-0 right-0 p-8 max-w-7xl mx-auto">
          <p className="text-xs font-semibold tracking-widest uppercase mb-3" style={{ color: "#a855f7" }}>
            {event.city}
          </p>
          <h1 className="font-display font-black text-4xl md:text-6xl mb-3">{event.name}</h1>
          <p className="text-base mb-6" style={{ color: "rgba(255,255,255,0.6)" }}>{event.tagline}</p>
          <div className="flex flex-wrap gap-3">
            <span className="flex items-center gap-1.5 text-sm" style={{ color: "rgba(255,255,255,0.7)" }}>📍 {event.location}</span>
            <span className="flex items-center gap-1.5 text-sm" style={{ color: "rgba(255,255,255,0.7)" }}>📅 15–19 Oct 2026</span>
            <span className="flex items-center gap-1.5 text-sm font-bold" style={{ color: "#a855f7" }}>from ₹499</span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-12">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
          {/* Main content */}
          <div className="lg:col-span-2 space-y-12">
            {/* Description */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-4">About This Event</h2>
              <p className="text-base leading-relaxed" style={{ color: "rgba(255,255,255,0.65)" }}>{event.description}</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-6">
                {[["📅", "Dates", "15–19 Oct 2026"], ["📍", "Venue", event.venue], ["🏙️", "City", event.city], ["👤", "Organizer", event.organizer]].map(([icon, label, val]) => (
                  <div key={label as string} className="p-4 rounded-xl" style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}>
                    <span className="text-xl block mb-1">{icon}</span>
                    <p className="text-xs mb-0.5" style={{ color: "rgba(255,255,255,0.4)" }}>{label}</p>
                    <p className="text-sm font-semibold">{val}</p>
                  </div>
                ))}
              </div>
            </section>

            {/* Highlights */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Highlights</h2>
              <div className="flex flex-wrap gap-3">
                {event.highlights.map((h) => (
                  <span key={h} className="px-4 py-2 rounded-full text-sm font-medium" style={{ background: "rgba(139,92,246,0.1)", border: "1px solid rgba(139,92,246,0.2)", color: "#c084fc" }}>
                    ✦ {h}
                  </span>
                ))}
              </div>
            </section>

            {/* Gallery */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Gallery</h2>
              <div className="rounded-2xl overflow-hidden mb-3" style={{ aspectRatio: "16/9" }}>
                <img src={event.gallery[galleryIdx]} alt="Gallery" className="w-full h-full object-cover transition-all duration-300" />
              </div>
              <div className="flex gap-2 overflow-x-auto scrollbar-hide">
                {event.gallery.map((img, i) => (
                  <button
                    key={i}
                    onClick={() => setGalleryIdx(i)}
                    className="flex-none w-16 h-16 rounded-lg overflow-hidden transition-all"
                    style={{ border: i === galleryIdx ? "2px solid #a855f7" : "2px solid transparent", opacity: i === galleryIdx ? 1 : 0.5 }}
                  >
                    <img src={img} alt="" className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            </section>

            {/* Day selector */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Choose Your Night</h2>
              <div className="flex gap-3 overflow-x-auto scrollbar-hide pb-2 mb-6">
                {event.days.map((d, i) => (
                  <button
                    key={i}
                    onClick={() => { setSelectedDay(i); setSelectedPass(null); setQty(1); }}
                    className="flex-none flex flex-col items-center px-5 py-3 rounded-xl transition-all"
                    style={
                      selectedDay === i
                        ? {
                            background: "linear-gradient(135deg, #8b5cf6, #ec4899)",
                            boxShadow: "0 0 20px rgba(139,92,246,0.4)",
                          }
                        : { background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.09)" }
                    }
                  >
                    <span className="text-xs font-bold opacity-70">DAY {d.day}</span>
                    <span className="font-bold text-base">{d.date}</span>
                  </button>
                ))}
              </div>

              {/* Selected day info */}
              <div className="p-6 rounded-2xl mb-6" style={{ background: "rgba(139,92,246,0.07)", border: "1px solid rgba(139,92,246,0.15)" }}>
                <div className="flex flex-wrap gap-6">
                  <div>
                    <p className="text-xs mb-1" style={{ color: "rgba(255,255,255,0.4)" }}>Day</p>
                    <p className="font-bold text-lg">Day {day.day} — {day.fullDate}</p>
                  </div>
                  <div>
                    <p className="text-xs mb-1" style={{ color: "rgba(255,255,255,0.4)" }}>Program</p>
                    <p className="font-semibold">{day.program}</p>
                  </div>
                  <div>
                    <p className="text-xs mb-1" style={{ color: "rgba(255,255,255,0.4)" }}>Time</p>
                    <p className="font-semibold">{day.time}</p>
                  </div>
                </div>
              </div>

              {/* Artists for selected day */}
              <h3 className="font-display font-semibold text-lg mb-4">Performing Artists</h3>
              <div className="flex gap-4 mb-8">
                {day.artists.map((a, i) => (
                  <div
                    key={a.name}
                    className="flex items-center gap-3 px-4 py-3 rounded-xl"
                    style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.07)" }}
                  >
                    <img src={a.image} alt={a.name} className="w-10 h-10 rounded-full object-cover" />
                    <div>
                      <p className="font-semibold text-sm">{a.name}</p>
                      <p className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>{a.type}</p>
                    </div>
                    {i === 0 && <span className="ml-1 px-2 py-0.5 rounded-full text-xs" style={{ background: "rgba(139,92,246,0.2)", color: "#c084fc" }}>Headliner</span>}
                  </div>
                ))}
              </div>

              {/* Passes */}
              <h3 className="font-display font-semibold text-lg mb-4">Choose Your Pass</h3>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
                {day.passes.map((p, i) => {
                  const soldOut = p.available === 0;
                  const lowStock = p.available > 0 && p.available <= 10;
                  const selected = selectedPass === i;
                  return (
                    <button
                      key={p.name}
                      onClick={() => !soldOut && setSelectedPass(i)}
                      disabled={soldOut}
                      className="p-5 rounded-2xl text-left transition-all"
                      style={
                        selected
                          ? { background: "rgba(139,92,246,0.15)", border: "2px solid #8b5cf6", boxShadow: "0 0 20px rgba(139,92,246,0.25)" }
                          : soldOut
                          ? { background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", opacity: 0.5, cursor: "not-allowed" }
                          : { background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.09)", cursor: "pointer" }
                      }
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <span className="font-display font-bold text-lg">{p.name}</span>
                          {soldOut && <span className="ml-2 text-xs px-2 py-0.5 rounded-full" style={{ background: "#374151", color: "#9ca3af" }}>SOLD OUT</span>}
                          {lowStock && !soldOut && <span className="ml-2 text-xs px-2 py-0.5 rounded-full" style={{ background: "rgba(245,158,11,0.15)", color: "#fbbf24" }}>Only {p.available} left</span>}
                        </div>
                        {selected && <span className="w-5 h-5 rounded-full flex items-center justify-center text-xs" style={{ background: "#8b5cf6" }}>✓</span>}
                      </div>
                      <p className="font-black text-2xl mb-3" style={{ color: soldOut ? "rgba(255,255,255,0.3)" : "#a855f7" }}>₹{p.price.toLocaleString()}</p>
                      <ul className="space-y-1">
                        {p.benefits.map((b) => (
                          <li key={b} className="text-xs flex items-center gap-1.5" style={{ color: "rgba(255,255,255,0.5)" }}>
                            <span style={{ color: "#a855f7" }}>✓</span> {b}
                          </li>
                        ))}
                      </ul>
                    </button>
                  );
                })}
              </div>

              {/* Quantity + total */}
              {selectedPass !== null && pass && (
                <div className="p-6 rounded-2xl mb-8" style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.09)" }}>
                  <div className="flex items-center justify-between mb-4">
                    <span className="font-semibold">Quantity</span>
                    <div className="flex items-center gap-3">
                      <button onClick={() => setQty(Math.max(1, qty - 1))} className="w-9 h-9 rounded-full flex items-center justify-center font-bold transition-all hover:bg-purple-500/20" style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}>−</button>
                      <span className="font-bold text-xl w-8 text-center">{qty}</span>
                      <button onClick={() => setQty(Math.min(10, qty + 1))} className="w-9 h-9 rounded-full flex items-center justify-center font-bold transition-all hover:bg-purple-500/20" style={{ background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.1)" }}>+</button>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-sm mb-1" style={{ color: "rgba(255,255,255,0.5)" }}>
                    <span>₹{pass.price.toLocaleString()} × {qty}</span>
                    <span>₹{(pass.price * qty).toLocaleString()}</span>
                  </div>
                  <div className="flex items-center justify-between font-bold text-lg pt-3" style={{ borderTop: "1px solid rgba(255,255,255,0.08)" }}>
                    <span>Estimated Total</span>
                    <span style={{ color: "#a855f7" }}>₹{total.toLocaleString()}</span>
                  </div>
                </div>
              )}
            </section>

            {/* Venue */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Venue</h2>
              <div className="p-6 rounded-2xl flex items-center justify-between" style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.09)" }}>
                <div>
                  <h3 className="font-display font-bold text-xl mb-1">{event.venue}</h3>
                  <p style={{ color: "rgba(255,255,255,0.5)" }}>{event.address}</p>
                </div>
                <a href="#" className="flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all hover:scale-105" style={{ background: "rgba(59,130,246,0.15)", border: "1px solid rgba(59,130,246,0.3)", color: "#60a5fa" }}>
                  📍 Get Directions
                </a>
              </div>
            </section>

            {/* Facilities */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">Facilities</h2>
              <div className="flex flex-wrap gap-2.5">
                {event.facilities.map((f) => (
                  <span key={f} className="px-3 py-2 rounded-xl text-sm" style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", color: "rgba(255,255,255,0.7)" }}>
                    {f}
                  </span>
                ))}
              </div>
            </section>

            {/* Rules */}
            <section>
              <button
                onClick={() => setOpenRule(!openRule)}
                className="w-full flex items-center justify-between p-5 rounded-2xl text-left transition-all"
                style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.07)" }}
              >
                <span className="font-display font-bold text-lg">Event Rules & Guidelines</span>
                <span style={{ transform: openRule ? "rotate(180deg)" : "none", transition: "transform 0.2s" }}>▾</span>
              </button>
              {openRule && (
                <div className="mt-2 p-5 rounded-2xl" style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)" }}>
                  <ul className="space-y-2">
                    {event.rules.map((r) => (
                      <li key={r} className="flex items-center gap-2 text-sm" style={{ color: "rgba(255,255,255,0.65)" }}>
                        <span style={{ color: "#ec4899" }}>•</span> {r}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </section>

            {/* FAQ */}
            <section>
              <h2 className="font-display font-bold text-2xl mb-5">FAQ</h2>
              <div className="space-y-2">
                {event.faqs.map((faq, i) => (
                  <div key={i} className="rounded-xl overflow-hidden" style={{ border: "1px solid rgba(255,255,255,0.07)" }}>
                    <button
                      onClick={() => setOpenFaq(openFaq === i ? null : i)}
                      className="w-full flex items-center justify-between p-4 text-left"
                      style={{ background: "rgba(255,255,255,0.03)" }}
                    >
                      <span className="font-medium text-sm">{faq.q}</span>
                      <span style={{ transform: openFaq === i ? "rotate(180deg)" : "none", transition: "transform 0.2s" }}>▾</span>
                    </button>
                    {openFaq === i && (
                      <div className="px-4 pb-4 text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.55)" }}>
                        {faq.a}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </section>
          </div>

          {/* Sticky sidebar CTA */}
          <div className="lg:col-span-1">
            <div className="sticky top-24">
              <div className="p-6 rounded-2xl" style={{ background: "#12122a", border: "1px solid rgba(255,255,255,0.09)" }}>
                <h3 className="font-display font-bold text-xl mb-1">Get Your Pass</h3>
                <p className="text-sm mb-5" style={{ color: "rgba(255,255,255,0.5)" }}>Select a night and pass type below.</p>

                {pass && (
                  <div className="mb-4 p-4 rounded-xl" style={{ background: "rgba(139,92,246,0.08)", border: "1px solid rgba(139,92,246,0.15)" }}>
                    <p className="text-sm font-semibold mb-0.5">{pass.name} Pass — Day {day.day}</p>
                    <p className="text-xs mb-2" style={{ color: "rgba(255,255,255,0.5)" }}>{day.fullDate} · {day.program}</p>
                    <p className="font-black text-2xl" style={{ color: "#a855f7" }}>₹{total.toLocaleString()}</p>
                    <p className="text-xs" style={{ color: "rgba(255,255,255,0.4)" }}>₹{pass.price.toLocaleString()} × {qty}</p>
                  </div>
                )}

                <Link
                  to={selectedPass !== null ? `/inquiry?event=${event.id}&day=${day.day}&pass=${pass?.name}&qty=${qty}&total=${total}` : "#"}
                  onClick={selectedPass === null ? (e) => e.preventDefault() : undefined}
                  className="block w-full py-4 rounded-xl font-bold text-base text-center transition-all hover:scale-[1.02]"
                  style={
                    selectedPass !== null
                      ? { background: "linear-gradient(135deg, #8b5cf6, #ec4899)", boxShadow: "0 0 24px rgba(139,92,246,0.35)" }
                      : { background: "rgba(255,255,255,0.07)", color: "rgba(255,255,255,0.4)", cursor: "default" }
                  }
                >
                  {selectedPass !== null ? "Inquire Now" : "Select a Pass First"}
                </Link>

                <a
                  href="https://wa.me/917041615131"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-3 flex items-center justify-center gap-2 w-full py-3 rounded-xl text-sm font-semibold transition-all hover:scale-[1.02]"
                  style={{ background: "rgba(37,211,102,0.1)", border: "1px solid rgba(37,211,102,0.2)", color: "#25D366" }}
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" /></svg>
                  Chat on WhatsApp
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Footer />
    </div>
  );
}
