"use client";

import FadeIn from "./FadeIn";
import { Check, AppleLogo } from "@phosphor-icons/react";

const features = [
  "Unlimited hotspot tracking",
  "Real-time byte counter",
  "Smart data cap alerts",
  "Multiple hotspot profiles",
  "Billing cycle sync",
  "Session history",
  "100% private — no cloud",
  "Lifetime updates",
];

export default function Pricing() {
  return (
    <section id="pricing" className="py-30 bg-white">
      <div className="max-w-3xl mx-auto px-6">
        <FadeIn className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-semibold tracking-tight mb-4">
            One price, <span className="serif-accent text-accent">forever</span>
          </h2>
          <p className="text-text-secondary text-lg">
            No subscriptions. Pay once, own it for life.
          </p>
        </FadeIn>

        <FadeIn delay={0.15}>
          <div className="glass rounded-3xl p-10 md:p-12 max-w-lg mx-auto text-center">
            <div className="text-sm font-medium text-accent mb-2">Drip for macOS</div>
            <div className="flex items-baseline justify-center gap-1 mb-1">
              <span className="text-5xl font-semibold tracking-tight">$9</span>
            </div>
            <div className="text-text-tertiary text-sm mb-8">One-time purchase</div>

            <ul className="text-left space-y-3 mb-10">
              {features.map((f) => (
                <li key={f} className="flex items-start gap-3 text-sm">
                  <Check
                    size={18}
                    weight="bold"
                    className="text-accent mt-0.5 shrink-0"
                  />
                  <span>{f}</span>
                </li>
              ))}
            </ul>

            <a
              href="#"
              className="w-full flex items-center justify-center gap-2 bg-accent text-white font-medium py-3.5 rounded-full text-base hover:bg-accent-dark hover:scale-[1.02] hover:shadow-lg transition-all duration-300"
            >
              <AppleLogo size={18} weight="fill" />
              Download for macOS
            </a>

            <p className="text-xs text-text-tertiary mt-4">
              Requires macOS 13 Ventura or later
            </p>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
