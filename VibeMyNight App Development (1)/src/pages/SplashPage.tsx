import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import vmnPng from "@/imports/vmn.png";

export default function SplashPage() {
  const navigate = useNavigate();
  const [phase, setPhase] = useState(0); // 0=appear, 1=glow, 2=fade

  useEffect(() => {
    const t1 = setTimeout(() => setPhase(1), 400);
    const t2 = setTimeout(() => setPhase(2), 1800);
    const t3 = setTimeout(() => navigate("/home"), 2600);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [navigate]);

  return (
    <div
      className="fixed inset-0 flex flex-col items-center justify-center"
      style={{
        background: "#07070e",
        opacity: phase === 2 ? 0 : 1,
        transition: phase === 2 ? "opacity 0.7s ease" : "opacity 0.4s ease",
      }}
    >
      {/* Radial glow behind logo */}
      <div
        style={{
          position: "absolute",
          width: 320,
          height: 320,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(139,92,246,0.25) 0%, rgba(236,72,153,0.1) 50%, transparent 80%)",
          opacity: phase >= 1 ? 1 : 0,
          transition: "opacity 1.2s ease",
          filter: "blur(20px)",
        }}
      />

      <div
        style={{
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? "scale(1)" : "scale(0.85)",
          transition: "opacity 0.6s ease, transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)",
        }}
      >
        <img
          src={vmnPng}
          alt="VibeMyNight"
          width={96}
          height={96}
          style={{
            width: 96,
            height: 96,
            objectFit: "contain",
            filter: phase >= 1 ? "drop-shadow(0 0 24px rgba(139,92,246,0.8)) drop-shadow(0 0 48px rgba(236,72,153,0.4))" : "none",
            transition: "filter 1.2s ease",
          }}
        />
      </div>

      <div
        className="mt-5 font-display font-bold text-2xl tracking-tight"
        style={{
          background: "linear-gradient(135deg, #a855f7, #ec4899)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          backgroundClip: "text",
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? "translateY(0)" : "translateY(8px)",
          transition: "opacity 0.6s ease 0.2s, transform 0.6s ease 0.2s",
        }}
      >
        VibeMyNight
      </div>

      {/* Loading dots */}
      <div className="flex gap-1.5 mt-8" style={{ opacity: phase >= 1 ? 1 : 0, transition: "opacity 0.4s ease 0.5s" }}>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="w-1.5 h-1.5 rounded-full"
            style={{
              background: "linear-gradient(135deg, #a855f7, #ec4899)",
              animation: `pulse 1.2s ${i * 0.2}s infinite`,
            }}
          />
        ))}
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 0.3; transform: scale(0.8); }
          50% { opacity: 1; transform: scale(1.2); }
        }
      `}</style>
    </div>
  );
}
