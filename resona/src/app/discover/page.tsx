import type { Metadata } from "next";

import DiscoverPageClient from "./DiscoverPageClient";

export const metadata: Metadata = {
  title: "Discover",
  description:
    "Explore Resona's curated playlists and trending tracks with instant search, smart filtering, and privacy-first music discovery.",
  alternates: {
    canonical: "/discover",
  },
};

export default function DiscoverPage() {
  return <DiscoverPageClient />;
}
