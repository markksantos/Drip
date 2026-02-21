"use client";

import FadeIn from "./FadeIn";

export default function Screenshots() {
  return (
    <section className="py-30 bg-white">
      <div className="max-w-6xl mx-auto px-6">
        <FadeIn className="text-center mb-16">
          <h2 className="text-3xl md:text-5xl font-semibold tracking-tight mb-4">
            Lives in your <span className="serif-accent text-accent">menu bar</span>
          </h2>
          <p className="text-text-secondary text-lg max-w-2xl mx-auto">
            One click to see everything. No windows cluttering your desktop.
          </p>
        </FadeIn>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Connected state */}
          <FadeIn delay={0.1}>
            <div className="bg-surface-muted rounded-2xl p-8 border border-border">
              <div className="text-xs font-medium text-text-tertiary uppercase tracking-wider mb-4">
                Connected
              </div>
              <div className="bg-white rounded-xl shadow-lg shadow-black/5 border border-border overflow-hidden max-w-xs mx-auto">
                <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border">
                  <div className="w-2.5 h-2.5 rounded-full bg-[#FF5F57]" />
                  <div className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                  <div className="w-2.5 h-2.5 rounded-full bg-[#28CA41]" />
                </div>
                <div className="p-4 space-y-3">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-green-500" />
                    <span className="text-sm font-medium">Mark&apos;s iPhone</span>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs text-text-secondary mb-1">
                      <span>Usage</span>
                      <span className="font-medium text-text-primary">7.8 GB / 10 GB</span>
                    </div>
                    <div className="h-1.5 bg-surface-muted rounded-full overflow-hidden">
                      <div className="h-full w-[78%] bg-yellow-500 rounded-full" />
                    </div>
                  </div>
                  <div className="flex justify-between text-xs text-text-tertiary">
                    <span>&#8595; 5.9 GB</span>
                    <span>&#8593; 1.9 GB</span>
                  </div>
                </div>
              </div>
              <p className="text-sm text-text-secondary text-center mt-5">
                Usage bar shifts from blue to yellow to red as you approach your limit.
              </p>
            </div>
          </FadeIn>

          {/* Settings */}
          <FadeIn delay={0.2}>
            <div className="bg-surface-muted rounded-2xl p-8 border border-border">
              <div className="text-xs font-medium text-text-tertiary uppercase tracking-wider mb-4">
                Settings
              </div>
              <div className="bg-white rounded-xl shadow-lg shadow-black/5 border border-border overflow-hidden max-w-xs mx-auto">
                <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border">
                  <div className="w-2.5 h-2.5 rounded-full bg-[#FF5F57]" />
                  <div className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                  <div className="w-2.5 h-2.5 rounded-full bg-[#28CA41]" />
                  <span className="flex-1 text-center text-xs text-text-tertiary">Settings</span>
                </div>
                <div className="p-4 space-y-3">
                  <div className="flex gap-2 text-xs border-b border-border pb-2">
                    <span className="text-accent font-medium border-b-2 border-accent pb-1">General</span>
                    <span className="text-text-tertiary">Profiles</span>
                    <span className="text-text-tertiary">History</span>
                    <span className="text-text-tertiary">About</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span>Launch at Login</span>
                    <div className="w-8 h-4.5 bg-accent rounded-full relative">
                      <div className="absolute right-0.5 top-0.5 w-3.5 h-3.5 bg-white rounded-full" />
                    </div>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span>Show in Menu Bar</span>
                    <div className="w-8 h-4.5 bg-accent rounded-full relative">
                      <div className="absolute right-0.5 top-0.5 w-3.5 h-3.5 bg-white rounded-full" />
                    </div>
                  </div>
                  <div className="text-sm">
                    <span className="text-text-secondary text-xs">Display Format</span>
                    <div className="flex gap-1 mt-1">
                      <span className="bg-accent text-white text-xs px-2 py-0.5 rounded">GB</span>
                      <span className="bg-surface-muted text-xs px-2 py-0.5 rounded text-text-tertiary">GB + %</span>
                      <span className="bg-surface-muted text-xs px-2 py-0.5 rounded text-text-tertiary">%</span>
                    </div>
                  </div>
                </div>
              </div>
              <p className="text-sm text-text-secondary text-center mt-5">
                Configure data limits, alert thresholds, and display preferences per profile.
              </p>
            </div>
          </FadeIn>
        </div>
      </div>
    </section>
  );
}
