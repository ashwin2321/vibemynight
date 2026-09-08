import { Link, useSearchParams } from "react-router-dom";

export default function SuccessPage() {
  const [params] = useSearchParams();
  const inquiryId = params.get("id") || "VMN-000123";
  const eventName = params.get("event") === "navratri-nights" ? "Navratri Nights 2026" : "VibeMyNight Event";
  const day = params.get("day") || "2";
  const passType = params.get("pass") || "VIP";
  const qty = params.get("qty") || "2";
  const total = params.get("total") || "1998";
  const name = params.get("name") || "Guest";

  return (
    <div
      className="min-h-screen flex items-center justify-center px-6"
      style={{ background: "#07070e" }}
    >
      {/* Radial glow */}
      <div
        className="fixed inset-0 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse 60% 50% at 50% 30%, rgba(139,92,246,0.12) 0%, transparent 70%)",
        }}
      />

      <div className="relative z-10 w-full max-w-lg text-center">
        {/* Animated check */}
        <div className="relative w-24 h-24 mx-auto mb-6">
          <div
            className="absolute inset-0 rounded-full animate-ping"
            style={{ background: "rgba(139,92,246,0.15)" }}
          />
          <div
            className="relative w-24 h-24 rounded-full flex items-center justify-center"
            style={{
              background: "linear-gradient(135deg, rgba(139,92,246,0.2), rgba(236,72,153,0.1))",
              border: "2px solid rgba(139,92,246,0.4)",
            }}
          >
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#a855f7" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="20 6 9 17 4 12" />
            </svg>
          </div>
        </div>

        <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#a855f7" }}>
          Received
        </p>
        <h1 className="font-display font-black text-4xl mb-2">Inquiry Received!</h1>
        <p className="mb-2" style={{ color: "rgba(255,255,255,0.5)" }}>Hey {name}, your inquiry has been submitted.</p>

        {/* Inquiry ID */}
        <div
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full mb-8 font-mono text-sm font-bold"
          style={{
            background: "rgba(139,92,246,0.1)",
            border: "1px solid rgba(139,92,246,0.3)",
            color: "#c084fc",
          }}
        >
          🎫 {inquiryId}
        </div>

        {/* Summary */}
        <div
          className="p-6 rounded-2xl text-left mb-8"
          style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)" }}
        >
          <h3 className="font-display font-bold text-lg mb-4">Booking Summary</h3>
          <div className="space-y-3">
            {[
              ["Event", eventName],
              ["Day", `Day ${day}`],
              ["Pass", passType],
              ["Quantity", qty],
              ["Estimated Total", `₹${parseInt(total).toLocaleString()}`],
            ].map(([label, value]) => (
              <div key={label} className="flex justify-between text-sm">
                <span style={{ color: "rgba(255,255,255,0.45)" }}>{label}</span>
                <span className={`font-semibold ${label === "Estimated Total" ? "text-purple-400" : ""}`}>{value}</span>
              </div>
            ))}
          </div>
          <p className="mt-4 text-xs" style={{ color: "rgba(255,255,255,0.35)" }}>
            Our team will reach out to confirm your booking. Please keep your inquiry ID ready.
          </p>
        </div>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row gap-3">
          <a
            href="https://wa.me/917041615131?text=Hi%2C%20I%20just%20submitted%20a%20pass%20inquiry.%20My%20Inquiry%20ID%20is%20"
            target="_blank"
            rel="noopener noreferrer"
            className="flex-1 flex items-center justify-center gap-2 py-4 rounded-xl font-bold text-base transition-all hover:scale-105"
            style={{ background: "#25D366", color: "#fff" }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" /></svg>
            Continue on WhatsApp
          </a>
          <Link
            to="/events"
            className="flex-1 flex items-center justify-center py-4 rounded-xl font-semibold text-base transition-all hover:bg-white/10"
            style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)" }}
          >
            Back to Events
          </Link>
        </div>
      </div>
    </div>
  );
}
