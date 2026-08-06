"use client";

import { useRef, useState } from "react";

type Props = {
  photos: string[];
  alt: string;
  /** Tailwind aspect-ratio class for the viewport. */
  aspect?: string;
  className?: string;
};

// Dependency-free swipeable gallery: native horizontal scroll-snap (works by
// touch/trackpad with zero JS, matters for the low-end-Android/3G audience
// this whole product targets), JS only drives the dot indicator and the
// desktop prev/next buttons. Used both on listing cards (small) and the
// annonce detail page (large) — same component, different `aspect`.
export default function PhotoCarousel({ photos, alt, aspect = "aspect-[4/3]", className = "" }: Props) {
  const [active, setActive] = useState(0);
  const scrollerRef = useRef<HTMLDivElement>(null);

  function handleScroll() {
    const el = scrollerRef.current;
    if (!el || el.clientWidth === 0) return;
    const index = Math.round(el.scrollLeft / el.clientWidth);
    setActive(Math.max(0, Math.min(index, photos.length - 1)));
  }

  function goTo(index: number) {
    const el = scrollerRef.current;
    if (!el) return;
    el.scrollTo({ left: index * el.clientWidth, behavior: "smooth" });
  }

  if (photos.length === 0) {
    return (
      <div className={`flex ${aspect} w-full items-center justify-center bg-brand-surface text-sm text-brand-muted ${className}`}>
        Photo à venir
      </div>
    );
  }

  if (photos.length === 1) {
    return (
      <div className={`${aspect} w-full overflow-hidden ${className}`}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={photos[0]} alt={alt} loading="lazy" className="h-full w-full object-cover" />
      </div>
    );
  }

  return (
    <div className={`group/carousel relative ${className}`}>
      <div
        ref={scrollerRef}
        onScroll={handleScroll}
        className={`flex ${aspect} w-full snap-x snap-mandatory overflow-x-auto scroll-smooth [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden`}
      >
        {photos.map((src, i) => (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            key={src + i}
            src={src}
            alt={`${alt} — photo ${i + 1}/${photos.length}`}
            loading={i === 0 ? "eager" : "lazy"}
            className="h-full w-full flex-none snap-center object-cover"
          />
        ))}
      </div>

      {/* Prev/next — desktop convenience, hidden until hover so it doesn't
          clutter the card grid; touch users just swipe. */}
      <button
        type="button"
        aria-label="Photo précédente"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          goTo(Math.max(0, active - 1));
        }}
        className={`absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-1.5 text-white opacity-0 backdrop-blur-sm transition-opacity group-hover/carousel:opacity-100 ${active === 0 ? "hidden" : "hidden sm:block"}`}
      >
        <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <button
        type="button"
        aria-label="Photo suivante"
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          goTo(Math.min(photos.length - 1, active + 1));
        }}
        className={`absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-black/40 p-1.5 text-white opacity-0 backdrop-blur-sm transition-opacity group-hover/carousel:opacity-100 ${active === photos.length - 1 ? "hidden" : "hidden sm:block"}`}
      >
        <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
        </svg>
      </button>

      {/* Les petits ronds */}
      <div className="pointer-events-none absolute inset-x-0 bottom-2 flex justify-center gap-1.5">
        {photos.map((_, i) => (
          <span
            key={i}
            className={`h-1.5 rounded-full shadow-sm transition-all ${
              i === active ? "w-4 bg-white" : "w-1.5 bg-white/60"
            }`}
          />
        ))}
      </div>
    </div>
  );
}
