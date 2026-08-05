import type { TypeBien } from "./types";

// Mirrors apps/mobile/lib/core/utils/currency_formatter.dart (CurrencyFormatter.formatXAF):
// integer XAF amounts only (the FCFA has no subdivision — decision D10 of the project),
// grouped by thousands with a plain space, symbol "FCFA" after the amount.
// Dart's NumberFormat.currency(locale: 'fr_CM', symbol: 'FCFA', decimalDigits: 0) inserts a
// non-breaking space between groups and strips it back to a regular space before display —
// we do the same here so numbers read identically across the mobile app and this site.
const groupFormatter = new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 });

export function formatXAF(amount: number): string {
  const rounded = Math.round(amount);
  const grouped = groupFormatter.format(rounded).replace(/[\u00a0\u202f]/g, " ");
  return `${grouped} FCFA`;
}

// Labels French, one entry per apps/api Prisma `TypeBien` enum value
// (apps/api/prisma/schema.prisma). Kept 1:1 and distinct — unlike the mobile
// bailleur form, which groups a few of these together for its own add-listing UX.
export const TYPE_BIEN_LABELS: Record<TypeBien, string> = {
  CHAMBRE_SIMPLE: "Chambre simple",
  CHAMBRE_MODERNE: "Chambre moderne",
  STUDIO: "Studio",
  APPARTEMENT: "Appartement",
  DUPLEX: "Duplex",
  MAISON: "Maison",
  VILLA: "Villa",
  BOUTIQUE: "Boutique",
  BUREAU: "Bureau",
  TERRAIN: "Terrain",
};

export const TYPE_BIEN_OPTIONS: { value: TypeBien; label: string }[] = (
  Object.keys(TYPE_BIEN_LABELS) as TypeBien[]
).map((value) => ({ value, label: TYPE_BIEN_LABELS[value] }));

export function typeLabel(type: string): string {
  return TYPE_BIEN_LABELS[type as TypeBien] ?? humanize(type);
}

// Fallback for equipment codes (e.g. "EAU_COURANTE" -> "Eau courante") and any
// unrecognised enum value — same simple underscore-to-space convention the
// mobile app uses for equipment chips (see ajouter_bien_screen.dart).
export function humanize(code: string): string {
  const words = code.toLowerCase().split("_").filter(Boolean);
  if (words.length === 0) return code;
  return words
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export function formatDate(iso: string): string {
  try {
    return new Intl.DateTimeFormat("fr-FR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

// Best-effort slugify for free-text quartier input (accents stripped, spaces to
// hyphens). The API filters quartiers by exact slug match, so this is only a
// heuristic fallback for the homepage's free-text field — real navigation
// should go through generated slugs (quartier picker, landing page links).
export function slugify(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
