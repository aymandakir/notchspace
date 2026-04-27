import type { ReactNode } from "react";

import { MiniPlayer } from "./MiniPlayer";
import { Navbar, type NavbarLink } from "./Navbar";

type AppScreenLayoutProps = {
  children: ReactNode;
  navLinks: NavbarLink[];
  nowPlaying: string;
  artist: string;
  currentTime: string;
  totalTime: string;
  progressPercent: number;
};

export function AppScreenLayout({
  children,
  navLinks,
  nowPlaying,
  artist,
  currentTime,
  totalTime,
  progressPercent,
}: AppScreenLayoutProps) {
  return (
    <div className="min-h-screen bg-[#07080c] pb-32 text-zinc-100">
      <div className="mx-auto w-full max-w-6xl px-5 pb-10 pt-6 sm:px-8 lg:px-12">
        <Navbar links={navLinks} />

        <main className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-b from-white/[0.07] to-white/[0.03] px-5 py-8 shadow-[0_0_90px_rgba(125,130,255,0.08)] sm:px-8 sm:py-10 lg:px-10">
          <div className="pointer-events-none absolute -top-36 left-1/2 h-72 w-72 -translate-x-1/2 rounded-full bg-violet-500/15 blur-3xl" />
          {children}
        </main>
      </div>

      <MiniPlayer
        nowPlaying={nowPlaying}
        artist={artist}
        currentTime={currentTime}
        totalTime={totalTime}
        progressPercent={progressPercent}
      />
    </div>
  );
}
