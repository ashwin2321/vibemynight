import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export default function InquiryPage() {
  const navigate = useNavigate();
  const [params] = useSearchParams();

  const eventId = params.get("event") || "navratri-nights";
  const day = params.get("day") || "2";
  const passType = params.get("pass") || "VIP";
  const qty = params.get("qty") || "2";
  const total = params.get("total") || "1998";

  const [form, setForm] = useState({ name: "", mobile: "", email: "", message: "" });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  function validate() {
    const e: Record<string, string> = {};
    if (!form.name.trim()) e.name = "Full name is required";
    if (!form.mobile.match(/^[6-9]\d{9}$/)) e.mobile = "Enter a valid 10-digit mobile number";
    if (form.email && !form.email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) e.email = "Enter a valid email address";
    return e;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const errs = validate();
    if (Object.keys(errs).length) { setErrors(errs); return; }
    setLoading(true);
    setTimeout(() => {
      const id = "VMN-" + String(Math.floor(100000 + Math.random() * 900000));
      navigate(`/success?id=${id}&event=${eventId}&day=${day}&pass=${passType}&qty=${qty}&total=${total}&name=${encodeURIComponent(form.name)}`);
    }, 1400);
  }

  const eventName: Record<string, string> = {
    "navratri-nights": "Navratri Nights 2026",
    "celebrity-night": "Celebrity Night Live",
    "dj-night-goa": "DJ Night — Goa Edition",
  };

  return (
    <div style={{ background: "#07070e", minHeight: "100vh" }}>
      <Navbar />

      <div className="pt-32 pb-24 max-w-3xl mx-auto px-6">
        <p className="text-xs font-semibold tracking-widest uppercase mb-2" style={{ color: "#a855f7" }}>
          Pass Inquiry
        </p>
        <h1 className="font-display font-black text-4xl mb-2">Almost There</h1>
        <p className="mb-10" style={{ color: "rgba(255,255,255,0.5)" }}>Fill in your details and we'll confirm via WhatsApp.</p>

        {/* Summary card */}
        <div className="p-6 rounded-2xl mb-8" style={{ background: "rgba(139,92,246,0.07)", border: "1px solid rgba(139,92,246,0.15)" }}>
          <h2 className="font-display font-bold text-lg mb-4">Inquiry Summary</h2>
          <div className="grid grid-cols-2 gap-y-3">
            {[
              ["Event", eventName[eventId] || "Navratri Nights 2026"],
              ["Day", `Day ${day}`],
              ["Date", day === "2" ? "16 October 2026" : "15 October 2026"],
              ["Pass", passType],
              ["Quantity", qty],
              ["Estimated Total", `₹${parseInt(total).toLocaleString()}`],
            ].map(([label, value]) => (
              <div key={label}>
                <p className="text-xs mb-0.5" style={{ color: "rgba(255,255,255,0.4)" }}>{label}</p>
                <p className={`font-semibold text-sm ${label === "Estimated Total" ? "text-purple-400" : ""}`}>{value}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          <InputField
            label="Full Name *"
            placeholder="Your full name"
            value={form.name}
            onChange={(v) => { setForm({ ...form, name: v }); setErrors({ ...errors, name: "" }); }}
            error={errors.name}
          />
          <InputField
            label="Mobile Number *"
            placeholder="10-digit mobile number"
            value={form.mobile}
            onChange={(v) => { setForm({ ...form, mobile: v }); setErrors({ ...errors, mobile: "" }); }}
            error={errors.mobile}
            type="tel"
          />
          <InputField
            label="Email Address"
            placeholder="your@email.com (optional)"
            value={form.email}
            onChange={(v) => { setForm({ ...form, email: v }); setErrors({ ...errors, email: "" }); }}
            error={errors.email}
            type="email"
          />
          <div>
            <label className="block text-sm font-medium mb-2" style={{ color: "rgba(255,255,255,0.8)" }}>Message (optional)</label>
            <textarea
              rows={3}
              placeholder="Any special requirements or questions..."
              value={form.message}
              onChange={(e) => setForm({ ...form, message: e.target.value })}
              className="w-full px-4 py-3 rounded-xl text-sm outline-none transition-all resize-none"
              style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.09)", color: "#fff" }}
            />
          </div>

          <p className="text-sm" style={{ color: "rgba(255,255,255,0.4)" }}>
            ⓘ Your inquiry will be saved and our team will contact you for confirmation. No payment is required at this step.
          </p>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 rounded-xl font-bold text-base transition-all hover:scale-[1.02] disabled:opacity-60 disabled:scale-100"
            style={{
              background: loading ? "rgba(139,92,246,0.5)" : "linear-gradient(135deg, #8b5cf6, #ec4899)",
              boxShadow: loading ? "none" : "0 0 24px rgba(139,92,246,0.35)",
            }}
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                Submitting…
              </span>
            ) : (
              "Submit Inquiry"
            )}
          </button>
        </form>
      </div>

      <Footer />
    </div>
  );
}

function InputField({
  label,
  placeholder,
  value,
  onChange,
  error,
  type = "text",
}: {
  label: string;
  placeholder: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
  type?: string;
}) {
  return (
    <div>
      <label className="block text-sm font-medium mb-2" style={{ color: "rgba(255,255,255,0.8)" }}>{label}</label>
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-4 py-3.5 rounded-xl text-sm outline-none transition-all"
        style={{
          background: "rgba(255,255,255,0.05)",
          border: error ? "1px solid #ef4444" : "1px solid rgba(255,255,255,0.09)",
          color: "#fff",
        }}
      />
      {error && <p className="mt-1.5 text-xs" style={{ color: "#f87171" }}>{error}</p>}
    </div>
  );
}
