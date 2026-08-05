import type { Metadata } from "next";
import AnnonceCard from "@/components/AnnonceCard";
import FiltersBar from "@/components/FiltersBar";
import Pagination from "@/components/Pagination";
import { getQuartiers, getVilles, searchAnnonces } from "@/lib/api";
import type { AnnoncesSearchResult, Quartier, Ville } from "@/lib/types";
import { SITE_NAME } from "@/lib/site";

type SearchParams = Record<string, string | string[] | undefined>;

function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function loadVilles(): Promise<Ville[]> {
  try {
    return await getVilles("OUVERTE");
  } catch {
    return [];
  }
}

async function loadQuartiers(villeSlug?: string): Promise<Quartier[]> {
  if (!villeSlug) return [];
  try {
    return await getQuartiers(villeSlug);
  } catch {
    return [];
  }
}

export async function generateMetadata({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}): Promise<Metadata> {
  const params = await searchParams;
  const ville = first(params.ville);
  const quartier = first(params.quartier);
  const label = [quartier, ville].filter(Boolean).join(", ");
  const title = label
    ? `Annonces à louer à ${label}`
    : "Rechercher un logement à louer";
  return {
    title,
    description: label
      ? `Studios, chambres et appartements à louer à ${label} — contact direct avec le bailleur sur ${SITE_NAME}.`
      : `Recherchez un studio, une chambre ou un appartement à louer au Cameroun sur ${SITE_NAME}, avec contact direct au bailleur.`,
  };
}

export default async function RecherchePage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const ville = first(params.ville);
  const quartier = first(params.quartier);
  const type = first(params.type);
  const meuble = first(params.meuble);
  const loyerMin = first(params.loyerMin);
  const loyerMax = first(params.loyerMax);
  const page = first(params.page) ?? "1";

  const [villes, quartiers] = await Promise.all([
    loadVilles(),
    loadQuartiers(ville),
  ]);

  let result: AnnoncesSearchResult | null = null;
  let loadError = false;
  try {
    result = await searchAnnonces(
      {
        ville,
        quartier,
        type: type as AnnoncesSearchResult["data"][number]["bien"]["type"] | undefined,
        meuble: meuble === "true" || meuble === "false" ? meuble : undefined,
        loyerMin,
        loyerMax,
        page,
        limit: "12",
      },
      120,
    );
  } catch {
    loadError = true;
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-bold text-foreground">
        {quartier || ville
          ? `Annonces à ${[quartier, ville].filter(Boolean).join(", ")}`
          : "Toutes les annonces"}
      </h1>

      <div className="mt-6">
        <FiltersBar
          villes={villes}
          quartiers={quartiers}
          current={{ ville, quartier, type, meuble, loyerMin, loyerMax }}
        />
      </div>

      <div className="mt-8">
        {loadError && (
          <p className="rounded-lg border border-brand-border bg-brand-surface px-4 py-6 text-center text-brand-muted">
            Le service de recherche est momentanément indisponible. Merci de
            réessayer dans un instant.
          </p>
        )}

        {!loadError && result && result.data.length === 0 && (
          <p className="rounded-lg border border-brand-border bg-brand-surface px-4 py-6 text-center text-brand-muted">
            Aucune annonce ne correspond à ces critères pour le moment.
            Essayez d&apos;élargir votre budget ou de choisir une autre
            ville.
          </p>
        )}

        {!loadError && result && result.data.length > 0 && (
          <>
            <p className="mb-4 text-sm text-brand-muted">
              {result.meta.total} annonce{result.meta.total > 1 ? "s" : ""}{" "}
              trouvée{result.meta.total > 1 ? "s" : ""}
            </p>
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {result.data.map((annonce) => (
                <AnnonceCard key={annonce.id} annonce={annonce} />
              ))}
            </div>
            <Pagination
              page={result.meta.page}
              pagesTotal={result.meta.pagesTotal}
              basePath="/recherche"
              searchParams={{ ville, quartier, type, meuble, loyerMin, loyerMax }}
            />
          </>
        )}
      </div>
    </div>
  );
}
