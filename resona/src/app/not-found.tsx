import Link from "next/link";

import { Navbar } from "@/components/resona/Navbar";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#07080c] text-zinc-100">
      <div className="mx-auto flex w-full max-w-6xl flex-col px-5 pb-14 pt-6 sm:px-8 lg:px-12">
        <Navbar
          className="mb-16"
          links={[
            { label: "Discover", href: "/discover" },
            { label: "Library", href: "/library" },
            { label: "GitHub", href: "https://github.com", external: true },
          ]}
        />

        <main className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-white/[0.07] to-white/[0.03] px-5 py-14 shadow-[0_0_90px_rgba(125,130,255,0.08)] sm:px-10 sm:py-18 lg:px-14">
          <div className="pointer-events-none absolute -top-40 left-1/2 h-72 w-72 -translate-x-1/2 rounded-full bg-violet-500/15 blur-3xl" />

          <section className="relative z-10 max-w-2xl">
            <p className="mb-4 inline-flex rounded-full border border-white/15 bg-white/5 px-3 py-1 text-xs text-zinc-300">
              Error 404
            </p>
            <h1 className="text-4xl font-semibold leading-tight tracking-tight text-white sm:text-5xl">
              This track got lost in the mix.
            </h1>
            <p className="mt-5 text-base leading-7 text-zinc-300 sm:text-lg">
              The page you are looking for is not available. Head back home or jump into Discover.
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                className="inline-flex h-11 items-center justify-center rounded-full bg-white px-6 text-sm font-medium text-zinc-900 transition hover:bg-zinc-200"
                href="/"
              >
                Back to home
              </Link>
              <Link
                className="inline-flex h-11 items-center justify-center rounded-full border border-white/20 bg-white/5 px-6 text-sm font-medium text-zinc-100 transition hover:border-white/35 hover:bg-white/10"
                href="/discover"
              >
                Open Discover
              </Link>
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}
