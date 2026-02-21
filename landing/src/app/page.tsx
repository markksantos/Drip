import Nav from "@/components/Nav";
import Hero from "@/components/Hero";
import SocialProof from "@/components/SocialProof";
import Features from "@/components/Features";
import Screenshots from "@/components/Screenshots";
import Testimonials from "@/components/Testimonials";
import Pricing from "@/components/Pricing";
import FAQ from "@/components/FAQ";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-surface-muted">
      <Nav />
      <Hero />
      <SocialProof />
      <Features />
      <Screenshots />
      <Testimonials />
      <Pricing />
      <FAQ />
      <Footer />
    </main>
  );
}
