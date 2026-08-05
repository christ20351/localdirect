import Link from "next/link";

type Props = {
  page: number;
  pagesTotal: number;
  // base search params (without "page") to preserve filters across pages
  searchParams: Record<string, string | undefined>;
  basePath: string;
};

function hrefFor(basePath: string, params: Record<string, string | undefined>, page: number) {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value) search.set(key, value);
  }
  if (page > 1) search.set("page", String(page));
  const qs = search.toString();
  return qs ? `${basePath}?${qs}` : basePath;
}

export default function Pagination({
  page,
  pagesTotal,
  searchParams,
  basePath,
}: Props) {
  if (pagesTotal <= 1) return null;

  const prev = page > 1 ? page - 1 : null;
  const next = page < pagesTotal ? page + 1 : null;

  return (
    <nav
      className="flex items-center justify-center gap-4 pt-6"
      aria-label="Pagination"
    >
      {prev ? (
        <Link
          href={hrefFor(basePath, searchParams, prev)}
          className="rounded-lg border border-brand-border px-4 py-2 text-sm font-medium text-foreground hover:border-brand-primary hover:text-brand-primary"
        >
          Précédent
        </Link>
      ) : (
        <span className="rounded-lg border border-brand-border px-4 py-2 text-sm font-medium text-brand-muted opacity-50">
          Précédent
        </span>
      )}
      <span className="text-sm text-brand-muted">
        Page {page} / {pagesTotal}
      </span>
      {next ? (
        <Link
          href={hrefFor(basePath, searchParams, next)}
          className="rounded-lg border border-brand-border px-4 py-2 text-sm font-medium text-foreground hover:border-brand-primary hover:text-brand-primary"
        >
          Suivant
        </Link>
      ) : (
        <span className="rounded-lg border border-brand-border px-4 py-2 text-sm font-medium text-brand-muted opacity-50">
          Suivant
        </span>
      )}
    </nav>
  );
}
