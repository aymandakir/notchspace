"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export type NavbarLink = {
  label: string;
  href: string;
  external?: boolean;
};

type NavbarProps = {
  links: NavbarLink[];
  className?: string;
};

export function Navbar({ links, className }: NavbarProps) {
  const pathname = usePathname();

  return (
    <header
      className={`mb-8 flex items-center justify-between rounded-full border border-white/10 bg-white/5 px-4 py-2 backdrop-blur sm:px-6 ${className ?? ""}`.trim()}
    >
      <Link className="text-sm font-semibold tracking-[0.18em] text-white" href="/">
        RESONA
      </Link>

      <nav className="flex items-center gap-5 text-xs text-zinc-300 sm:text-sm">
        {links.map((link) => {
          const isActive = !link.external && pathname === link.href;
          const commonClassName = `transition-colors hover:text-white ${isActive ? "text-white" : ""}`.trim();
          if (link.external) {
            return (
              <a
                key={link.label}
                className={commonClassName}
                href={link.href}
                target="_blank"
                rel="noreferrer"
              >
                {link.label}
              </a>
            );
          }

          return (
            <Link key={link.label} className={commonClassName} href={link.href}>
              {link.label}
            </Link>
          );
        })}
      </nav>
    </header>
  );
}
