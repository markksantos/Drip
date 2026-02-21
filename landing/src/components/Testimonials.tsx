"use client";

import FadeIn from "./FadeIn";
import { Star } from "@phosphor-icons/react";

const testimonials = [
  {
    name: "Sarah K.",
    role: "Freelance Designer",
    text: "I tether from coffee shops constantly. Drip saved me from a $50 overage charge on the first day. Worth every penny.",
    stars: 5,
  },
  {
    name: "James T.",
    role: "Software Engineer",
    text: "Finally, something that actually tells me how much data I'm burning on my Mac. The menu bar icon filling up is genius.",
    stars: 5,
  },
  {
    name: "Maria L.",
    role: "Remote PM",
    text: "I didn't realize a single Zoom call was eating 1.5 GB. Drip caught it and now I manage my hotspot sessions way better.",
    stars: 5,
  },
  {
    name: "Alex R.",
    role: "Digital Nomad",
    text: "Clean, simple, does exactly what it says. No account, no cloud sync, no BS. Just data tracking on my Mac. Love it.",
    stars: 5,
  },
  {
    name: "Chris M.",
    role: "Photographer",
    text: "The billing cycle reset is clutch. It matches my T-Mobile plan exactly so I always know where I stand.",
    stars: 5,
  },
];

export default function Testimonials() {
  return (
    <section className="py-30 bg-surface-muted">
      <div className="max-w-6xl mx-auto px-6">
        <FadeIn className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-semibold tracking-tight mb-4">
            People <span className="serif-accent text-accent">love</span> it
          </h2>
          <p className="text-text-secondary text-lg">
            Don&apos;t take our word for it.
          </p>
        </FadeIn>

        <div className="columns-1 md:columns-2 lg:columns-3 gap-4 space-y-4">
          {testimonials.map((t, i) => (
            <FadeIn key={t.name} delay={i * 0.08}>
              <div className="glass rounded-2xl p-6 break-inside-avoid">
                <div className="flex gap-0.5 mb-3">
                  {[...Array(t.stars)].map((_, j) => (
                    <Star key={j} size={14} weight="fill" className="text-amber-400" />
                  ))}
                </div>
                <p className="text-sm text-text-primary leading-relaxed mb-4">
                  &ldquo;{t.text}&rdquo;
                </p>
                <div>
                  <div className="text-sm font-medium">{t.name}</div>
                  <div className="text-xs text-text-tertiary">{t.role}</div>
                </div>
              </div>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}
