import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto flex max-w-xl flex-col items-center px-4 py-24 text-center sm:px-6">
      <h1 className="text-3xl font-bold text-foreground">
        Page introuvable
      </h1>
      <p className="mt-3 text-brand-muted">
        Cette annonce ou cette page n&apos;existe pas, ou n&apos;est plus
        disponible.
      </p>
      <Link
        href="/recherche"
        className="mt-6 rounded-lg bg-brand-primary px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-primary-dark"
      >
        Rechercher un logement
      </Link>
    </div>
  );
}
