type MiniPlayerProps = {
  nowPlaying: string;
  artist: string;
  currentTime: string;
  totalTime: string;
  progressPercent: number;
};

export function MiniPlayer({
  nowPlaying,
  artist,
  currentTime,
  totalTime,
  progressPercent,
}: MiniPlayerProps) {
  return (
    <div className="fixed bottom-4 left-0 right-0 z-20 px-4 sm:px-8">
      <div className="mx-auto flex w-full max-w-5xl flex-col gap-4 rounded-2xl border border-white/10 bg-zinc-950/90 px-4 py-3 backdrop-blur sm:flex-row sm:items-center sm:justify-between sm:px-5">
        <div className="min-w-0">
          <p className="truncate text-sm font-medium text-white">Now playing: {nowPlaying}</p>
          <p className="truncate text-xs text-zinc-400">{artist}</p>
        </div>

        <div className="flex items-center gap-3">
          <button
            className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-white/15 bg-white/5 text-zinc-100 transition hover:border-white/30 hover:bg-white/10"
            type="button"
            aria-label="Toggle playback"
          >
            II
          </button>
        </div>

        <div className="w-full sm:max-w-xs">
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-white/10">
            <div
              className="h-full rounded-full bg-violet-300/80"
              style={{ width: `${Math.max(0, Math.min(progressPercent, 100))}%` }}
            />
          </div>
          <div className="mt-1 flex justify-between text-[11px] text-zinc-500">
            <span>{currentTime}</span>
            <span>{totalTime}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
