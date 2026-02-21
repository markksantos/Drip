"use client";

import FadeIn from "./FadeIn";
import { Star } from "@phosphor-icons/react";

export default function SocialProof() {
  return (
    <section className="py-16 border-y border-border bg-white">
      <div className="max-w-5xl mx-auto px-6">
        <FadeIn>
          <div className="flex flex-col md:flex-row items-center justify-center gap-8 md:gap-16 text-text-secondary text-sm">
            <div className="flex items-center gap-1.5">
              {[...Array(5)].map((_, i) => (
                <Star key={i} size={16} weight="fill" className="text-amber-400" />
              ))}
              <span className="ml-1.5 font-medium text-text-primary">4.9</span>
              <span className="text-text-tertiary">on the Mac App Store</span>
            </div>
            <div className="h-4 w-px bg-border hidden md:block" />
            <div>
              <span className="font-medium text-text-primary">2,400+</span>{" "}
              <span className="text-text-tertiary">Mac users tracking their data</span>
            </div>
            <div className="h-4 w-px bg-border hidden md:block" />
            <div>
              <span className="font-medium text-text-primary">Zero</span>{" "}
              <span className="text-text-tertiary">data ever leaves your Mac</span>
            </div>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
