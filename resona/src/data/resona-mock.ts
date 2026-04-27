export type Track = {
  id: string;
  name: string;
  artist: string;
  duration: string;
};

export type Playlist = {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  tracks: Track[];
};

export const discoverPlaylists: Playlist[] = [
  {
    id: "midnight-circuit",
    title: "Midnight Circuit",
    subtitle: "Synthwave focus",
    description: "Neon textures and late-night rhythm for deep, uninterrupted focus.",
    tracks: [
      { id: "glass-horizon", name: "Glass Horizon", artist: "Aria Vale", duration: "3:42" },
      { id: "soft-signals", name: "Soft Signals", artist: "Nova Thread", duration: "4:08" },
      { id: "neon-lowline", name: "Neon Lowline", artist: "Echo Drift", duration: "3:25" },
      { id: "static-bloom", name: "Static Bloom", artist: "Mira Sol", duration: "2:59" },
    ],
  },
  {
    id: "lo-fi-current",
    title: "Lo-Fi Current",
    subtitle: "Calm productivity",
    description: "Warm beats and gentle melodies for coding, reading, and flow states.",
    tracks: [
      { id: "quiet-canvas", name: "Quiet Canvas", artist: "Kei Bloom", duration: "3:14" },
      { id: "paper-planets", name: "Paper Planets", artist: "Kei Bloom", duration: "3:51" },
      { id: "window-light", name: "Window Light", artist: "Sora Lane", duration: "2:48" },
      { id: "blue-frequency", name: "Blue Frequency", artist: "Niko Raye", duration: "4:02" },
    ],
  },
  {
    id: "open-air-mornings",
    title: "Open Air Mornings",
    subtitle: "Acoustic discovery",
    description: "Bright acoustic picks and independent artists to start your day clean.",
    tracks: [
      { id: "open-rooms", name: "Open Rooms", artist: "Aster Lane", duration: "2:58" },
      { id: "low-tide-echo", name: "Low Tide Echo", artist: "Mira Sol", duration: "3:27" },
      { id: "afterlight", name: "Afterlight", artist: "Rumi Vale", duration: "3:08" },
      { id: "northbound", name: "Northbound", artist: "Sola Frames", duration: "3:16" },
    ],
  },
];

export const librarySavedPlaylists: Playlist[] = [
  {
    id: "deep-focus-vault",
    title: "Deep Focus Vault",
    subtitle: "Productivity",
    description: "Steady, low-distraction tracks for long creative and coding blocks.",
    tracks: [
      { id: "quiet-canvas", name: "Quiet Canvas", artist: "Kei Bloom", duration: "3:14" },
      { id: "soft-signals", name: "Soft Signals", artist: "Nova Thread", duration: "4:08" },
      { id: "window-light", name: "Window Light", artist: "Sora Lane", duration: "2:48" },
      { id: "glass-horizon", name: "Glass Horizon", artist: "Aria Vale", duration: "3:42" },
    ],
  },
  {
    id: "night-drive-archive",
    title: "Night Drive Archive",
    subtitle: "Electronic",
    description: "Moody synths and pulsing drums for late-night momentum.",
    tracks: [
      { id: "neon-lowline", name: "Neon Lowline", artist: "Echo Drift", duration: "3:25" },
      { id: "parallel-hearts", name: "Parallel Hearts", artist: "Vera Sun", duration: "4:11" },
      { id: "afterlight", name: "Afterlight", artist: "Rumi Vale", duration: "3:08" },
      { id: "slow-orbit", name: "Slow Orbit", artist: "Caden Sky", duration: "3:29" },
    ],
  },
  {
    id: "acoustic-keep",
    title: "Acoustic Keep",
    subtitle: "Indie folk",
    description: "Warm strings, intimate vocals, and calm textures for quiet sessions.",
    tracks: [
      { id: "open-rooms", name: "Open Rooms", artist: "Aster Lane", duration: "2:58" },
      { id: "northbound", name: "Northbound", artist: "Sola Frames", duration: "3:16" },
      { id: "low-tide-echo", name: "Low Tide Echo", artist: "Mira Sol", duration: "3:27" },
      { id: "quiet-city-lights", name: "Quiet City Lights", artist: "Mina Cove", duration: "3:37" },
    ],
  },
];

export const libraryRecentlyPlayed: Track[] = [
  { id: "northbound", name: "Northbound", artist: "Sola Frames", duration: "3:16" },
  { id: "blue-frequency", name: "Blue Frequency", artist: "Niko Raye", duration: "4:02" },
  { id: "quiet-city-lights", name: "Quiet City Lights", artist: "Mina Cove", duration: "3:37" },
  { id: "open-rooms", name: "Open Rooms", artist: "Aster Lane", duration: "2:58" },
];

export const libraryFavoriteTracks: Track[] = [
  { id: "signal-bloom", name: "Signal Bloom", artist: "Iris North", duration: "3:44" },
  { id: "slow-orbit", name: "Slow Orbit", artist: "Caden Sky", duration: "3:29" },
  { id: "parallel-hearts", name: "Parallel Hearts", artist: "Vera Sun", duration: "4:11" },
  { id: "afterlight", name: "Afterlight", artist: "Rumi Vale", duration: "3:08" },
];
