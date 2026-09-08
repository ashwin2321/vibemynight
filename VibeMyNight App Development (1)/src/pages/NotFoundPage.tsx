import { Link } from "react-router-dom";

export default function NotFoundPage() {
  return (
    <div
      className="min-h-screen flex items-center justify-center px-6"
      style={{ background: "#07070e" }}
    >
      <div
        className="fixed inset-0 pointer-events-none"
        style={{ background: "radial-gradient(ellipse 50% 40% at 50% 40%, rgba(139,92,246,0.08) 0%, transparent 70%)" }}
      />
      <div className="relative z-10 text-center">
        <div
          className="font-display font-black leading-none mb-4"
          style={{
            fontSize: "clamp(6rem, 20vw, 14rem)",
            background: "linear-gradient(135deg, rgba(139,92,246,0.3), rgba(236,72,153,0.2))",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            backgroundClip: "text",
          }}
        >
          404
        </div>
        <h2 className="font-display font-bold text-3xl mb-3">This night doesn't exist.</h2>
        <p className="mb-8 text-lg" style={{ color: "rgba(255,255,255,0.45)" }}>
          The page you're looking for has left the building.
        </p>
        <Link
          to="/events"
          className="inline-block px-8 py-4 rounded-full font-bold text-base transition-all hover:scale-105"
          style={{ background: "linear-gradient(135deg, #8b5cf6, #ec4899)", boxShadow: "0 0 24px rgba(139,92,246,0.35)" }}
        >
          Back to Events
        </Link>
      </div>
    </div>
  );
}
