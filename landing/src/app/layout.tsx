import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Drip — Know exactly where your data goes",
  description:
    "A native macOS menu bar app that tracks your iPhone hotspot data usage in real time. See every byte, get alerts before you hit your cap, and never worry about overage charges again.",
  openGraph: {
    title: "Drip — Hotspot Data Usage Tracker for macOS",
    description:
      "Track your iPhone hotspot data in real time from your Mac menu bar.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
