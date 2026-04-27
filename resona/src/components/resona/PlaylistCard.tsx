export type PlaylistCardProps = {
  title: string;
  subtitle: string;
  description: string;
  trackCount: string;
  isActive?: boolean;
  onClick?: () => void;
};

export function PlaylistCard({
  title,
  subtitle,
  description,
  trackCount,
  isActive,
  onClick,
}: PlaylistCardProps) {
  const className = `w-full rounded-2xl border bg-black/20 p-5 text-left backdrop-blur transition ${isActive ? "border-violet-300/40" : "border-white/10 hover:border-white/20"}`.trim();

  if (onClick) {
    return (
      <button
        className={className}
        type="button"
        onClick={onClick}
        aria-pressed={isActive}
        aria-label={`${title} playlist`}
      >
        <p className="text-xs uppercase tracking-[0.14em] text-zinc-400">{subtitle}</p>
        <h3 className="mt-2 text-lg font-medium text-white">{title}</h3>
        {isActive ? <p className="sr-only">Selected playlist</p> : null}
        <p className="mt-2 text-sm leading-6 text-zinc-300">{description}</p>
        <p className="mt-4 text-xs text-zinc-400">{trackCount}</p>
      </button>
    );
  }

  return (
    <article className={className}>
      <p className="text-xs uppercase tracking-[0.14em] text-zinc-400">{subtitle}</p>
      <h3 className="mt-2 text-lg font-medium text-white">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-zinc-300">{description}</p>
      <p className="mt-4 text-xs text-zinc-400">{trackCount}</p>
    </article>
  );
}
