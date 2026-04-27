"use client";

import { useEffect, useMemo, useState } from "react";

import { AppScreenLayout } from "@/components/resona/AppScreenLayout";
import { PlaylistCard } from "@/components/resona/PlaylistCard";
import { TrackRow } from "@/components/resona/TrackRow";
import { discoverPlaylists } from "@/data/resona-mock";

export default function DiscoverPageClient() {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPlaylistId, setSelectedPlaylistId] = useState(discoverPlaylists[0].id);
  const [selectedTrackId, setSelectedTrackId] = useState(discoverPlaylists[0].tracks[0].id);

  const selectedPlaylist = useMemo(
    () => discoverPlaylists.find((playlist) => playlist.id === selectedPlaylistId) ?? discoverPlaylists[0],
    [selectedPlaylistId],
  );

  const visibleTracks = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();
    if (!normalizedQuery) {
      return selectedPlaylist.tracks;
    }

    return selectedPlaylist.tracks.filter((track) => {
      const haystack = `${track.name} ${track.artist}`.toLowerCase();
      return haystack.includes(normalizedQuery);
    });
  }, [searchQuery, selectedPlaylist]);

  useEffect(() => {
    const firstTrack = visibleTracks[0];
    if (!firstTrack) {
      return;
    }

    const isSelectedTrackVisible = visibleTracks.some((track) => track.id === selectedTrackId);
    if (!isSelectedTrackVisible) {
      setSelectedTrackId(firstTrack.id);
    }
  }, [visibleTracks, selectedTrackId]);

  const selectedTrack =
    visibleTracks.find((track) => track.id === selectedTrackId) ??
    selectedPlaylist.tracks.find((track) => track.id === selectedTrackId) ??
    selectedPlaylist.tracks[0];

  return (
    <AppScreenLayout
      navLinks={[
        { label: "Discover", href: "/discover" },
        { label: "Library", href: "/library" },
        { label: "GitHub", href: "https://github.com", external: true },
      ]}
      nowPlaying={selectedTrack?.name ?? "No track selected"}
      artist={selectedTrack?.artist ?? "Resona"}
      currentTime={selectedTrack ? "1:24" : "0:00"}
      totalTime={selectedTrack?.duration ?? "0:00"}
      progressPercent={selectedTrack ? 40 : 0}
    >
      <section className="relative z-10">
        <h1 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">Discover</h1>
        <p className="mt-2 text-sm text-zinc-300 sm:text-base">
          Search songs, artists, and moods curated for your next session.
        </p>
        <div className="mt-6">
          <label className="sr-only" htmlFor="discover-search">
            Search songs, artists, or moods
          </label>
          <input
            id="discover-search"
            type="search"
            placeholder="Search songs, artists, or moods..."
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            className="h-13 w-full rounded-2xl border border-white/15 bg-black/30 px-5 text-base text-zinc-100 outline-none ring-violet-300/40 transition placeholder:text-zinc-500 focus:border-violet-300/40 focus:ring-2"
          />
        </div>
      </section>

      <section className="relative z-10 mt-10">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-medium text-white">Featured playlists</h2>
          <button className="text-sm text-zinc-300 transition hover:text-white" type="button">
            View all
          </button>
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {discoverPlaylists.map((playlist) => (
            <PlaylistCard
              key={playlist.id}
              title={playlist.title}
              subtitle={playlist.subtitle}
              description={playlist.description}
              trackCount={`${playlist.tracks.length} tracks`}
              isActive={playlist.id === selectedPlaylistId}
              onClick={() => setSelectedPlaylistId(playlist.id)}
            />
          ))}
        </div>
      </section>

      <section className="relative z-10 mt-10">
        <h2 className="mb-4 text-xl font-medium text-white">{selectedPlaylist.title} tracks</h2>
        <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/20">
          <div className="grid grid-cols-[1fr_auto] border-b border-white/10 px-4 py-3 text-xs uppercase tracking-[0.12em] text-zinc-400 sm:grid-cols-[1.2fr_1fr_auto]">
            <span>Track</span>
            <span className="hidden sm:block">Artist</span>
            <span>Time</span>
          </div>
          <ul>
            {visibleTracks.map((track) => (
              <TrackRow
                key={track.id}
                {...track}
                isActive={selectedTrack?.id === track.id}
                onClick={() => setSelectedTrackId(track.id)}
              />
            ))}
            {visibleTracks.length === 0 ? (
              <li className="px-4 py-6 text-sm text-zinc-400">No tracks found for this search.</li>
            ) : null}
          </ul>
        </div>
      </section>
    </AppScreenLayout>
  );
}
