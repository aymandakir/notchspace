import type { Metadata } from "next";

import { AppScreenLayout } from "@/components/resona/AppScreenLayout";
import { PlaylistCard } from "@/components/resona/PlaylistCard";
import { TrackRow } from "@/components/resona/TrackRow";
import {
  libraryFavoriteTracks,
  libraryRecentlyPlayed,
  librarySavedPlaylists,
} from "@/data/resona-mock";

export const metadata: Metadata = {
  title: "Library",
  description:
    "Access your Resona library with saved playlists, recent listening history, and favorite tracks in a focused premium interface.",
  alternates: {
    canonical: "/library",
  },
};

export default function LibraryPage() {
  return (
    <AppScreenLayout
      navLinks={[
        { label: "Discover", href: "/discover" },
        { label: "Library", href: "/library" },
        { label: "GitHub", href: "https://github.com", external: true },
      ]}
      nowPlaying="Signal Bloom"
      artist="Iris North"
      currentTime="0:56"
      totalTime="3:44"
      progressPercent={25}
    >
      <section className="relative z-10">
        <h1 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">Your Library</h1>
        <p className="mt-2 text-sm text-zinc-300 sm:text-base">
          A personal space for what you save, replay, and love most.
        </p>
      </section>

      <section className="relative z-10 mt-10">
        <h2 className="mb-4 text-xl font-medium text-white">Saved playlists</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {librarySavedPlaylists.map((playlist) => (
            <PlaylistCard
              key={playlist.id}
              title={playlist.title}
              subtitle={playlist.subtitle}
              description={playlist.description}
              trackCount={`${playlist.tracks.length} tracks`}
            />
          ))}
        </div>
      </section>

      <section className="relative z-10 mt-10">
        <h2 className="mb-4 text-xl font-medium text-white">Recently played</h2>
        <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/20">
          <div className="grid grid-cols-[1fr_auto] border-b border-white/10 px-4 py-3 text-xs uppercase tracking-[0.12em] text-zinc-400 sm:grid-cols-[1.2fr_1fr_auto]">
            <span>Track</span>
            <span className="hidden sm:block">Artist</span>
            <span>Time</span>
          </div>
          <ul>
            {libraryRecentlyPlayed.map((track) => (
              <TrackRow key={track.id} {...track} />
            ))}
          </ul>
        </div>
      </section>

      <section className="relative z-10 mt-10">
        <h2 className="mb-4 text-xl font-medium text-white">Favorite tracks</h2>
        <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/20">
          <div className="grid grid-cols-[1fr_auto] border-b border-white/10 px-4 py-3 text-xs uppercase tracking-[0.12em] text-zinc-400 sm:grid-cols-[1.2fr_1fr_auto]">
            <span>Track</span>
            <span className="hidden sm:block">Artist</span>
            <span>Time</span>
          </div>
          <ul>
            {libraryFavoriteTracks.map((track) => (
              <TrackRow key={track.id} {...track} />
            ))}
          </ul>
        </div>
      </section>
    </AppScreenLayout>
  );
}
