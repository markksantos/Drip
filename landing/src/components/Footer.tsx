"use client";

import { Drop } from "@phosphor-icons/react";

export default function Footer() {
  return (
    <footer className="py-12 border-t border-border bg-white">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2 text-text-secondary">
            <Drop size={20} weight="duotone" className="text-accent" />
            <span className="font-medium text-text-primary">Drip</span>
            <span className="text-sm text-text-tertiary ml-2">
              &copy; {new Date().getFullYear()}
            </span>
          </div>

          <div className="flex items-center gap-6 text-sm text-text-tertiary">
            <a href="#" className="hover:text-text-primary transition-colors">
              Privacy
            </a>
            <a href="#" className="hover:text-text-primary transition-colors">
              Support
            </a>
            <a href="#" className="hover:text-text-primary transition-colors">
              Twitter
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
