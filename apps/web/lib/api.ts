import "server-only";
import type {
  Annonce,
  AnnonceSearchFilters,
  AnnoncesSearchResult,
  Quartier,
  Ville,
} from "./types";

// This site never calls authenticated routes — read-only against the public
// catalogue (GET /villes, /villes/:slug/quartiers, /annonces, /annonces/:id).
const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:3000/api/v1";

const DEFAULT_TIMEOUT_MS = 8000;

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

/**
 * Thin fetch wrapper around the public API.
 *
 * The API is being actively developed by another agent tonight and restarts
 * intermittently, so every call here is time-bounded (AbortController) and
 * every caller in app/ is expected to catch ApiError / network failures and
 * render a friendly fallback rather than let the route hard-crash.
 */
async function apiFetch<T>(
  path: string,
  { revalidate }: { revalidate: number | false },
): Promise<T> {
  const url = `${API_BASE_URL}${path}`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      next: { revalidate },
    });
    if (!res.ok) {
      throw new ApiError(`API ${res.status} on ${path}`, res.status);
    }
    return (await res.json()) as T;
  } finally {
    clearTimeout(timeout);
  }
}

function buildQuery(params: Record<string, string | undefined>): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== "") search.set(key, value);
  }
  const qs = search.toString();
  return qs ? `?${qs}` : "";
}

// Villes list rarely changes — cache for an hour.
export async function getVilles(
  statut?: string,
  revalidate = 3600,
): Promise<Ville[]> {
  return apiFetch<Ville[]>(`/villes${buildQuery({ statut })}`, { revalidate });
}

export async function getVilleBySlug(
  slug: string,
  revalidate = 3600,
): Promise<Ville | null> {
  const villes = await getVilles("OUVERTE", revalidate);
  return villes.find((v) => v.slug === slug) ?? null;
}

// Quartiers per ville — also stable, cache for an hour.
export async function getQuartiers(
  villeSlug: string,
  revalidate = 3600,
): Promise<Quartier[]> {
  return apiFetch<Quartier[]>(`/villes/${encodeURIComponent(villeSlug)}/quartiers`, {
    revalidate,
  });
}

export async function getQuartierBySlug(
  villeSlug: string,
  quartierSlug: string,
  revalidate = 3600,
): Promise<Quartier | null> {
  const quartiers = await getQuartiers(villeSlug, revalidate);
  return quartiers.find((q) => q.slug === quartierSlug) ?? null;
}

// Listings change often enough that a short revalidate window matters; callers
// pick the value (search results want fresher data than SEO landing pages).
export async function searchAnnonces(
  filters: AnnonceSearchFilters,
  revalidate = 300,
): Promise<AnnoncesSearchResult> {
  const query = buildQuery({
    ville: filters.ville,
    quartier: filters.quartier,
    type: filters.type,
    loyerMin: filters.loyerMin,
    loyerMax: filters.loyerMax,
    avanceMax: filters.avanceMax,
    meuble: filters.meuble,
    nbPieces: filters.nbPieces,
    page: filters.page,
    limit: filters.limit,
  });
  return apiFetch<AnnoncesSearchResult>(`/annonces${query}`, { revalidate });
}

export async function getAnnonceById(
  id: string,
  revalidate = 300,
): Promise<Annonce | null> {
  try {
    return await apiFetch<Annonce>(`/annonces/${encodeURIComponent(id)}`, {
      revalidate,
    });
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) return null;
    throw err;
  }
}

// A real uploaded photo is served by the API itself as an absolute URL
// (see apps/api/src/annonces/annonces.service.ts#ajouterMedias, which stores
// `${baseUrl}/uploads/medias/<file>`). Seed/demo data sometimes contains raw
// on-device cache paths (e.g. "/data/user/0/.../scaled_x.jpg") left over from
// the mobile client — those aren't reachable from a browser, so we filter
// anything that isn't an absolute http(s) URL before rendering an <img>.
export function isDisplayablePhoto(url: string): boolean {
  return /^https?:\/\//i.test(url);
}
