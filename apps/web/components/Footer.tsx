import Link from "next/link";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="border-t border-brand-border bg-brand-surface">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div className="lg:col-span-2">
            <Link href="/" className="flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-primary text-sm font-bold text-white">
                L
              </span>
              <span className="text-base font-bold text-foreground">
                LocaDirect <span className="text-brand-gold">CM</span>
              </span>
            </Link>
            <p className="mt-3 max-w-xs text-sm text-brand-muted">
              La location immobilière au Cameroun, en contact direct entre
              locataires et bailleurs — sans démarcheur ni intermédiaire.
            </p>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-foreground">Rechercher</h3>
            <ul className="mt-3 space-y-2 text-sm text-brand-muted">
              <li>
                <Link href="/douala" className="hover:text-brand-primary">
                  Louer à Douala
                </Link>
              </li>
              <li>
                <Link href="/yaounde" className="hover:text-brand-primary">
                  Louer à Yaoundé
                </Link>
              </li>
              <li>
                <Link href="/recherche" className="hover:text-brand-primary">
                  Toutes les annonces
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-foreground">
              L&apos;application mobile
            </h3>
            <p className="mt-3 text-sm text-brand-muted">
              LocaDirect CM existe aussi en application mobile pour les
              bailleurs et les locataires, avec dossier locataire, favoris et
              alertes de recherche. Bientôt disponible sur le Play Store.
            </p>
          </div>
        </div>

        <div className="mt-10 flex flex-col gap-4 border-t border-brand-border pt-6 text-xs text-brand-muted sm:flex-row sm:items-center sm:justify-between">
          <p>© {year} LocaDirect CM. Tous les loyers affichés sont en Francs CFA (XAF).</p>
          <p>Douala · Yaoundé · Cameroun</p>
        </div>
      </div>
    </footer>
  );
}
