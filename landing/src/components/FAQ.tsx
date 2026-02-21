"use client";

import FadeIn from "./FadeIn";
import { CaretDown } from "@phosphor-icons/react";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

const faqs = [
  {
    q: "How does Drip detect my hotspot?",
    a: "Drip monitors your network interfaces and detects iPhone hotspots by their unique IP address range (172.20.10.x). It works automatically with WiFi, USB, and Bluetooth tethering — no configuration needed.",
  },
  {
    q: "Why does Drip ask for location permission?",
    a: "Starting with macOS 14, Apple requires location permission to read the WiFi network name (SSID). Drip uses this to display the name of your hotspot. Your actual location is never read or stored — we only need the permission to access the network name.",
  },
  {
    q: "Does Drip send my data anywhere?",
    a: "No. Drip has zero network calls. All your usage data is stored locally on your Mac in UserDefaults. There are no accounts, no cloud sync, and no analytics. Your data never leaves your machine.",
  },
  {
    q: "Can I track multiple hotspots?",
    a: "Yes. Drip automatically creates a profile for each new hotspot it detects. Each profile has its own data limit, alert thresholds, and billing cycle reset — so you can track your iPhone, iPad, or any other tethered device separately.",
  },
  {
    q: "How accurate is the data tracking?",
    a: "Drip reads byte counters directly from macOS network interfaces, the same data the system uses internally. It polls every 2 seconds and tracks download and upload separately. The accuracy matches what your carrier reports.",
  },
  {
    q: "Does it work with Android hotspots?",
    a: "Currently, Drip is optimized for iPhone hotspots which use the 172.20.10.x IP range. Android hotspots use different ranges and are on the roadmap for a future update.",
  },
  {
    q: "What macOS versions are supported?",
    a: "Drip requires macOS 13 Ventura or later. It's built with Swift and SwiftUI, taking advantage of the latest MenuBarExtra API for a native menu bar experience.",
  },
];

function FAQItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="border-b border-border">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between py-5 text-left group"
      >
        <span className="text-base font-medium pr-4 group-hover:text-accent transition-colors">
          {q}
        </span>
        <motion.span
          animate={{ rotate: open ? 180 : 0 }}
          transition={{ duration: 0.3 }}
        >
          <CaretDown size={18} weight="bold" className="text-text-tertiary shrink-0" />
        </motion.span>
      </button>
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="overflow-hidden"
          >
            <p className="pb-5 text-sm text-text-secondary leading-relaxed">
              {a}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function FAQ() {
  return (
    <section id="faq" className="py-30 bg-surface-muted">
      <div className="max-w-2xl mx-auto px-6">
        <FadeIn className="text-center mb-12">
          <h2 className="text-3xl md:text-5xl font-semibold tracking-tight mb-4">
            Questions &amp; <span className="serif-accent text-accent">answers</span>
          </h2>
        </FadeIn>

        <FadeIn delay={0.1}>
          <div>
            {faqs.map((faq) => (
              <FAQItem key={faq.q} q={faq.q} a={faq.a} />
            ))}
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
