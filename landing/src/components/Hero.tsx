"use client";

import { motion } from "framer-motion";
import { ArrowDown, AppleLogo } from "@phosphor-icons/react";
import dynamic from "next/dynamic";

const HeroScene = dynamic(() => import("./HeroScene"), { ssr: false });

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      <HeroScene />

      <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-accent-light/60 text-accent text-sm font-medium mb-8">
            <AppleLogo size={16} weight="fill" />
            Native macOS menu bar app
          </div>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="text-5xl md:text-7xl font-semibold tracking-tight leading-[1.08] mb-6"
        >
          Know exactly where
          <br />
          your <span className="serif-accent text-accent">data</span> goes
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.45 }}
          className="text-lg md:text-xl text-text-secondary max-w-2xl mx-auto mb-10 leading-relaxed"
        >
          Drip lives in your menu bar and tracks every byte when you tether to
          your iPhone. Real-time usage, smart alerts before you hit your cap,
          and your data never leaves your Mac.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <a
            href="#pricing"
            className="bg-accent text-white font-medium px-8 py-3.5 rounded-full text-base hover:bg-accent-dark hover:scale-[1.02] hover:shadow-lg transition-all duration-300"
          >
            Download for macOS
          </a>
          <a
            href="#features"
            className="flex items-center gap-2 text-text-secondary font-medium px-6 py-3.5 rounded-full text-base hover:text-text-primary transition-colors"
          >
            See how it works
            <ArrowDown size={18} weight="bold" />
          </a>
        </motion.div>

        {/* Floating app screenshot */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="mt-16 md:mt-20"
        >
          <motion.div
            animate={{ y: [0, -8, 0] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            className="relative mx-auto max-w-md"
          >
            {/* Menu bar mockup */}
            <div className="bg-white rounded-2xl shadow-2xl shadow-black/8 border border-border overflow-hidden">
              {/* macOS title bar */}
              <div className="flex items-center gap-2 px-4 py-3 border-b border-border bg-surface-muted">
                <div className="w-3 h-3 rounded-full bg-[#FF5F57]" />
                <div className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
                <div className="w-3 h-3 rounded-full bg-[#28CA41]" />
                <div className="flex-1 text-center text-xs text-text-tertiary font-medium">
                  Drip
                </div>
              </div>
              {/* Popover content */}
              <div className="p-5 space-y-4">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-green-500" />
                  <span className="text-sm font-medium">
                    Connected to Mark&apos;s iPhone
                  </span>
                </div>
                <div>
                  <div className="flex justify-between text-xs text-text-secondary mb-1.5">
                    <span>Data Usage</span>
                    <span className="font-medium text-text-primary">4.2 GB / 10 GB</span>
                  </div>
                  <div className="h-2 bg-surface-muted rounded-full overflow-hidden">
                    <div className="h-full w-[42%] bg-accent rounded-full" />
                  </div>
                </div>
                <div className="flex justify-between text-xs text-text-secondary">
                  <span className="flex items-center gap-1">
                    <span className="text-accent">&#8595;</span> 3.1 GB
                  </span>
                  <span className="flex items-center gap-1">
                    <span className="text-orange-500">&#8593;</span> 1.1 GB
                  </span>
                </div>
                <div className="flex justify-between text-xs text-text-tertiary pt-1 border-t border-border">
                  <span>Session: 1h 23m</span>
                  <span>This session: 2.1 GB</span>
                </div>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
