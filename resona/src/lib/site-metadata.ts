import type { Metadata } from "next";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3000");

export const siteConfig = {
  name: "Resona",
  tagline: "Open music streaming, your way",
  description:
    "Resona is an open-source, privacy-first music streaming experience with smart discovery and elegant listening across every session.",
  url: siteUrl,
};

export const defaultMetadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: "Resona",
    template: "%s | Resona",
  },
  description: siteConfig.description,
  applicationName: "Resona",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    type: "website",
    siteName: "Resona",
    title: "Resona",
    description: siteConfig.description,
    url: "/",
    images: [
      {
        url: "/opengraph-image",
        width: 1200,
        height: 630,
        alt: "Resona - Open music streaming, your way",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Resona",
    description: siteConfig.description,
    images: ["/twitter-image"],
  },
};
