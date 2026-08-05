import Link from "next/link";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="border-t border-brand-border bg-brand-surface">
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <div className="grid gap-8 sm:grid-cols-3">
          <div>
            <span className="text-base font-bold text-foreground">
              LocaDirect <span className="text-brand-gold">CM</span>
            </span>
            <p className="mt-2 max-w-xs text-sm text-brand-muted">
              La location immobilière au Cameroun, en contact direct entre
              locataires et bailleurs — sans démarcheur ni intermédiaire.
            </p>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-foreground">
              Rechercher
            </h3>
            <ul className="mt-2 space-y-1 text-sm text-brand-muted">
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
            <p className="mt-2 text-sm text-brand-muted">
              LocaDirect CM existe aussi en application mobile pour les
              bailleurs et les locataires, avec dossier locataire, favoris et
              alertes de recherche. Bientôt disponible sur le Play Store.
            </p>
          </div>
        </div>
        <div className="mt-8 border-t border-brand-border pt-6 text-xs text-brand-muted">
          © {year} LocaDirect CM. Tous les loyers affichés sont en Francs CFA
          (XAF).
        </div>
      </div>
    </footer>
  );
}
