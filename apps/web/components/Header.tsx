import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b border-brand-border bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
        <Link href="/" className="flex items-center gap-2 shrink-0">
          <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-primary text-base font-bold text-white">
            L
          </span>
          <span className="text-lg font-bold tracking-tight text-foreground">
            LocaDirect <span className="text-brand-gold">CM</span>
          </span>
        </Link>
        <nav className="flex items-center gap-4 text-sm font-medium text-brand-muted sm:gap-6">
          <Link href="/" className="hover:text-brand-primary">
            Accueil
          </Link>
          <Link href="/recherche" className="hover:text-brand-primary">
            Rechercher
          </Link>
        </nav>
      </div>
    </header>
  );
}
