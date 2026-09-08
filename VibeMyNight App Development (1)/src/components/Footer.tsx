import { Link } from "react-router-dom";
import VmnLogo from "./VmnLogo";

export default function Footer() {
  return (
    <footer
      style={{
        background: "#07070e",
        borderTop: "1px solid rgba(255,255,255,0.06)",
      }}
    >
      <div className="max-w-7xl mx-auto px-6 py-16">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10 mb-12">
          <div className="md:col-span-1">
            <VmnLogo size="md" />
            <p className="mt-4 text-sm leading-relaxed" style={{ color: "rgba(255,255,255,0.4)" }}>
              Discover the best events, artists and unforgettable nightlife experiences.
            </p>
            <a
              href="https://wa.me/917041615131"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-5 inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all hover:scale-105"
              style={{ background: "#25D366", color: "#fff" }}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" />
              </svg>
              Chat on WhatsApp
            </a>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-white mb-4 font-display">Quick Links</h4>
            <ul className="space-y-2.5">
              {[
                { to: "/", label: "Home" },
                { to: "/events", label: "Events" },
                { to: "/about", label: "About" },
                { to: "/contact", label: "Contact" },
              ].map(({ to, label }) => (
                <li key={to}>
                  <Link
                    to={to}
                    className="text-sm transition-colors hover:text-white"
                    style={{ color: "rgba(255,255,255,0.45)" }}
                  >
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-white mb-4 font-display">Contact</h4>
            <ul className="space-y-2.5">
              <li>
                <a
                  href="https://wa.me/917041615131"
                  className="text-sm transition-colors hover:text-white"
                  style={{ color: "rgba(255,255,255,0.45)" }}
                >
                  +91 70416 15131
                </a>
              </li>
              <li>
                <a
                  href="mailto:hello@vibemynight.com"
                  className="text-sm transition-colors hover:text-white"
                  style={{ color: "rgba(255,255,255,0.45)" }}
                >
                  hello@vibemynight.com
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="text-sm font-semibold text-white mb-4 font-display">Follow Us</h4>
            <div className="flex gap-3">
              {[
                { label: "Instagram", href: "#", color: "#E1306C" },
                { label: "Facebook", href: "#", color: "#1877F2" },
              ].map(({ label, href, color }) => (
                <a
                  key={label}
                  href={href}
                  className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold transition-all hover:scale-110"
                  style={{ background: color, color: "#fff" }}
                >
                  {label[0]}
                </a>
              ))}
            </div>
          </div>
        </div>

        <div
          className="pt-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs"
          style={{
            borderTop: "1px solid rgba(255,255,255,0.06)",
            color: "rgba(255,255,255,0.3)",
          }}
        >
          <span>© 2026 VibeMyNight. All rights reserved.</span>
          <div className="flex gap-4">
            <a href="#" className="hover:text-white transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-white transition-colors">Terms of Service</a>
            <Link to="/admin/login" className="hover:text-white transition-colors">Admin</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
