"use client";

import { Drop } from "@phosphor-icons/react";
import { motion } from "framer-motion";

export default function Nav() {
  return (
    <motion.nav
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="fixed top-0 left-0 right-0 z-50 glass"
    >
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#" className="flex items-center gap-2 text-text-primary">
          <Drop size={24} weight="duotone" className="text-accent" />
          <span className="font-semibold text-lg tracking-tight">Drip</span>
        </a>

        <div className="hidden md:flex items-center gap-8 text-sm text-text-secondary">
          <a href="#features" className="hover:text-text-primary transition-colors">Features</a>
          <a href="#pricing" className="hover:text-text-primary transition-colors">Pricing</a>
          <a href="#faq" className="hover:text-text-primary transition-colors">FAQ</a>
        </div>

        <a
          href="#pricing"
          className="bg-accent text-white text-sm font-medium px-5 py-2 rounded-full hover:bg-accent-dark transition-colors"
        >
          Download
        </a>
      </div>
    </motion.nav>
  );
}
