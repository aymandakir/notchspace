export type TrackRowProps = {
  name: string;
  artist: string;
  duration: string;
  isActive?: boolean;
  onClick?: () => void;
};

export function TrackRow({ name, artist, duration, isActive, onClick }: TrackRowProps) {
  const className = `grid w-full grid-cols-[1fr_auto] items-center border-b border-white/5 px-4 py-3 text-left text-sm text-zinc-200 transition last:border-b-0 sm:grid-cols-[1.2fr_1fr_auto] ${isActive ? "bg-violet-300/10" : "hover:bg-white/[0.03]"}`.trim();

  if (onClick) {
    return (
      <li>
        <button
          className={className}
          type="button"
          onClick={onClick}
          aria-pressed={isActive}
          aria-label={`Play ${name} by ${artist}`}
        >
          <div>
            <p className="font-medium text-white">{name}</p>
            {isActive ? <p className="sr-only">Selected track</p> : null}
            <p className="mt-1 text-xs text-zinc-400 sm:hidden">{artist}</p>
          </div>
          <p className="hidden text-zinc-300 sm:block">{artist}</p>
          <p className="text-zinc-400">{duration}</p>
        </button>
      </li>
    );
  }

  return (
    <li className={className}>
      <div>
        <p className="font-medium text-white">{name}</p>
        <p className="mt-1 text-xs text-zinc-400 sm:hidden">{artist}</p>
      </div>
      <p className="hidden text-zinc-300 sm:block">{artist}</p>
      <p className="text-zinc-400">{duration}</p>
    </li>
  );
}
