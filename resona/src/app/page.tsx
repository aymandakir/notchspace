import type { Metadata } from "next";

import { Navbar } from "@/components/resona/Navbar";

export const metadata: Metadata = {
  title: "Resona",
  description:
    "Resona is an open-source, privacy-first music streaming experience with smart discovery and elegant listening across every session.",
  alternates: {
    canonical: "/",
  },
};

export default function Home() {
  return (
    <div className="min-h-screen bg-[#07080c] text-zinc-100">
      <div className="mx-auto flex w-full max-w-6xl flex-col px-5 pb-14 pt-6 sm:px-8 lg:px-12">
        <Navbar
          className="mb-16"
          links={[
            { label: "Discover", href: "/discover" },
            { label: "GitHub", href: "https://github.com", external: true },
          ]}
        />

        <main className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-white/[0.07] to-white/[0.03] px-5 py-12 shadow-[0_0_90px_rgba(125,130,255,0.08)] sm:px-10 sm:py-16 lg:px-14">
          <div className="pointer-events-none absolute -top-40 left-1/2 h-72 w-72 -translate-x-1/2 rounded-full bg-violet-500/15 blur-3xl" />

          <section className="relative z-10 max-w-2xl">
            <p className="mb-4 inline-flex rounded-full border border-white/15 bg-white/5 px-3 py-1 text-xs text-zinc-300">
              Open music streaming, your way
            </p>
            <h1 className="text-4xl font-semibold leading-tight tracking-tight text-white sm:text-5xl">
              Stream freely with privacy at the core.
            </h1>
            <p className="mt-5 text-base leading-7 text-zinc-300 sm:text-lg">
              Resona is the open-source music platform built for modern listeners, blending smart discovery with a calm, privacy-first experience.
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <a
                className="inline-flex h-11 items-center justify-center rounded-full bg-white px-6 text-sm font-medium text-zinc-900 transition hover:bg-zinc-200"
                href="#"
              >
                Explore demo
              </a>
              <a
                className="inline-flex h-11 items-center justify-center rounded-full border border-white/20 bg-white/5 px-6 text-sm font-medium text-zinc-100 transition hover:border-white/35 hover:bg-white/10"
                href="https://github.com"
                target="_blank"
                rel="noreferrer"
              >
                View on GitHub
              </a>
            </div>
          </section>

          <section id="features" className="relative z-10 mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                title: "Open-source",
                description: "Inspect, fork, and shape every part of your listening experience.",
              },
              {
                title: "Smart discovery",
                description: "Find new favorites through recommendations tuned to your taste.",
              },
              {
                title: "Privacy-first",
                description: "Your listening data stays yours with transparent, minimal tracking.",
              },
            ].map((feature) => (
              <article
                key={feature.title}
                className="rounded-2xl border border-white/10 bg-black/20 p-5 backdrop-blur"
              >
                <h2 className="text-lg font-medium text-white">{feature.title}</h2>
                <p className="mt-2 text-sm leading-6 text-zinc-300">{feature.description}</p>
              </article>
            ))}
          </section>
        </main>
      </div>
    </div>
  );
}
