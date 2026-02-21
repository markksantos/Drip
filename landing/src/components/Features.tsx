"use client";

import FadeIn from "./FadeIn";
import {
  WifiHigh,
  ChartLineUp,
  Bell,
  ShieldCheck,
  Timer,
  UsersThree,
} from "@phosphor-icons/react";
import { type Icon } from "@phosphor-icons/react";

interface Feature {
  icon: Icon;
  title: string;
  description: string;
  span?: string;
}

const features: Feature[] = [
  {
    icon: WifiHigh,
    title: "Auto-detect hotspot",
    description:
      "Drip recognizes when you connect to an iPhone hotspot instantly — WiFi, USB, or Bluetooth. No setup required.",
    span: "md:col-span-2",
  },
  {
    icon: ChartLineUp,
    title: "Real-time tracking",
    description:
      "Watch bytes flow in real time. Download vs upload split, session totals, and cumulative billing cycle usage.",
  },
  {
    icon: Bell,
    title: "Smart alerts",
    description:
      "Get notified at 50%, 75%, and 90% of your data cap. Customizable thresholds per profile.",
  },
  {
    icon: ShieldCheck,
    title: "Completely private",
    description:
      "No accounts, no cloud, no analytics. Every byte of data stays on your Mac. Period.",
  },
  {
    icon: Timer,
    title: "Billing cycle sync",
    description:
      "Set your reset date — daily, weekly, or monthly. Usage resets automatically so your numbers always match your plan.",
    span: "md:col-span-2",
  },
  {
    icon: UsersThree,
    title: "Multiple profiles",
    description:
      "Track different hotspots separately. Each profile gets its own data limit, alerts, and reset cycle.",
  },
];

export default function Features() {
  return (
    <section id="features" className="py-30 bg-surface-muted">
      <div className="max-w-6xl mx-auto px-6">
        <FadeIn className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-semibold tracking-tight mb-4">
            Every byte, <span className="serif-accent text-accent">accounted</span> for
          </h2>
          <p className="text-text-secondary text-lg max-w-2xl mx-auto">
            Built for Mac users who tether and need to know exactly where their
            data is going.
          </p>
        </FadeIn>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {features.map((feature, i) => (
            <FadeIn
              key={feature.title}
              delay={i * 0.08}
              className={feature.span ?? ""}
            >
              <div className="group bg-white rounded-2xl p-7 border border-border hover:shadow-lg hover:shadow-black/4 hover:border-accent/20 transition-all duration-400 h-full">
                <feature.icon
                  size={28}
                  weight="duotone"
                  className="text-accent mb-4"
                />
                <h3 className="text-lg font-semibold mb-2 tracking-tight">
                  {feature.title}
                </h3>
                <p className="text-text-secondary text-sm leading-relaxed">
                  {feature.description}
                </p>
              </div>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}
