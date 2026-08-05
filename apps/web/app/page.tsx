import Link from "next/link";
import SearchForm from "@/components/SearchForm";
import AnnonceCard from "@/components/AnnonceCard";
import { getQuartiers, getVilles, searchAnnonces } from "@/lib/api";
import type { Annonce, Quartier, Ville } from "@/lib/types";

async function loadHomeData() {
  let villes: Ville[] = [];
  try {
    villes = await getVilles("OUVERTE");
  } catch {
    // API unreachable — degrade to an empty city list, the search form still
    // works with "Toutes les villes" and free navigation via /recherche.
    villes = [];
  }

  const quartiersParVille: { ville: Ville; quartiers: Quartier[] }[] = [];
  for (const ville of villes.slice(0, 3)) {
    try {
      const quartiers = await getQuartiers(ville.slug);
      quartiersParVille.push({ ville, quartiers: quartiers.slice(0, 6) });
    } catch {
      // Skip this city's quartier links rather than failing the whole page.
    }
  }

  let recentes: Annonce[] = [];
  try {
    const result = await searchAnnonces({ limit: "6" }, 300);
    recentes = result.data;
  } catch {
    recentes = [];
  }

  return { villes, quartiersParVille, recentes };
}

export default async function HomePage() {
  const { villes, quartiersParVille, recentes } = await loadHomeData();

  return (
    <div>
      <section className="border-b border-brand-border bg-gradient-to-b from-brand-surface to-white">
        <div className="mx-auto max-w-6xl px-4 py-14 sm:px-6">
          <h1 className="max-w-2xl text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            Trouvez votre prochain logement au Cameroun, en contact direct
            avec le bailleur.
          </h1>
          <p className="mt-3 max-w-xl text-brand-muted">
            Studios, chambres et appartements à Douala, Yaoundé et ailleurs.
            Pas de démarcheur, pas d&apos;intermédiaire : vous appelez ou
            écrivez directement au propriétaire.
          </p>
          <div className="mt-8">
            <SearchForm villes={villes} />
          </div>
        </div>
      </section>

      {quartiersParVille.length > 0 && (
        <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
          <h2 className="text-xl font-bold text-foreground">
            Quartiers populaires
          </h2>
          <div className="mt-6 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {quartiersParVille.map(({ ville, quartiers }) => (
              <div key={ville.id}>
                <Link
                  href={`/${ville.slug}`}
                  className="text-sm font-semibold text-brand-primary hover:underline"
                >
                  Louer à {ville.nom}
                </Link>
                <ul className="mt-2 flex flex-wrap gap-2">
                  {quartiers.map((q) => (
                    <li key={q.id}>
                      <Link
                        href={`/${ville.slug}/${q.slug}`}
                        className="inline-block rounded-full border border-brand-border bg-white px-3 py-1 text-sm text-foreground hover:border-brand-primary hover:text-brand-primary"
                      >
                        {q.nom}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>
      )}

      {recentes.length > 0 && (
        <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-foreground">
              Annonces récentes
            </h2>
            <Link
              href="/recherche"
              className="text-sm font-semibold text-brand-primary hover:underline"
            >
              Voir toutes les annonces
            </Link>
          </div>
          <div className="mt-6 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {recentes.map((annonce) => (
              <AnnonceCard key={annonce.id} annonce={annonce} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
