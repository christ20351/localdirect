import Link from "next/link";

export default function Header() {
  return (
    <header className="sticky top-0 z-40 border-b border-brand-border bg-white/90 backdrop-blur-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
        <Link href="/" className="flex shrink-0 items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-primary text-base font-bold text-white">
            L
          </span>
          <span className="text-lg font-bold tracking-tight text-foreground">
            LocaDirect <span className="text-brand-gold">CM</span>
          </span>
        </Link>
        <nav className="flex items-center gap-4 text-sm font-medium text-brand-muted sm:gap-6">
          <Link href="/" className="hidden hover:text-brand-primary sm:inline">
            Accueil
          </Link>
          <Link href="/#comment-ca-marche" className="hidden hover:text-brand-primary lg:inline">
            Comment ça marche
          </Link>
          <Link href="/#pourquoi" className="hidden hover:text-brand-primary lg:inline">
            Pourquoi LocaDirect
          </Link>
          <Link href="/recherche" className="hidden hover:text-brand-primary sm:inline">
            Rechercher
          </Link>
          <Link
            href="/recherche"
            className="rounded-lg bg-brand-gold px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-gold-dark"
          >
            Trouver un logement
          </Link>
        </nav>
      </div>
    </header>
  );
}
