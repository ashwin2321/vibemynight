import vmnPng from "@/imports/vmn.png";

interface VmnLogoProps {
  size?: "sm" | "md" | "lg";
  withText?: boolean;
  className?: string;
}

export default function VmnLogo({ size = "md", withText = true, className = "" }: VmnLogoProps) {
  const iconSizes = { sm: 28, md: 36, lg: 52 };
  const px = iconSizes[size];
  const textClass = size === "sm" ? "text-base" : size === "lg" ? "text-2xl" : "text-lg";

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <img
        src={vmnPng}
        alt="VibeMyNight logo mark"
        width={px}
        height={px}
        style={{ width: px, height: px, objectFit: "contain" }}
      />
      {withText && (
        <span
          className={`font-display font-bold tracking-tight ${textClass}`}
          style={{
            background: "linear-gradient(135deg, #a855f7, #ec4899)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            backgroundClip: "text",
          }}
        >
          VibeMyNight
        </span>
      )}
    </div>
  );
}
