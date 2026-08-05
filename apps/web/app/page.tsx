import Link from "next/link";
import Hero from "@/components/Hero";
import SearchForm from "@/components/SearchForm";
import HowItWorks from "@/components/HowItWorks";
import ValueProps from "@/components/ValueProps";
import CtaBanner from "@/components/CtaBanner";
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
  let annoncesCount = 0;
  try {
    const result = await searchAnnonces({ limit: "6" }, 300);
    recentes = result.data;
    annoncesCount = result.meta.total;
  } catch {
    recentes = [];
  }

  return { villes, quartiersParVille, recentes, annoncesCount };
}

export default async function HomePage() {
  const { villes, quartiersParVille, recentes, annoncesCount } = await loadHomeData();

  return (
    <div>
      <Hero villesCount={villes.length} annoncesCount={annoncesCount} />

      <section className="border-y border-brand-border bg-brand-surface">
        <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
          <SearchForm villes={villes} />
        </div>
      </section>

      <div id="comment-ca-marche">
        <HowItWorks />
      </div>

      {quartiersParVille.length > 0 && (
        <section className="border-b border-brand-border bg-white">
          <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
            <h2 className="text-xs font-semibold uppercase tracking-widest text-brand-gold">
              Où chercher
            </h2>
            <p className="mt-2 text-2xl font-bold text-foreground sm:text-3xl">
              Quartiers populaires
            </p>
            <div className="mt-8 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
              {quartiersParVille.map(({ ville, quartiers }) => (
                <div key={ville.id}>
                  <Link
                    href={`/${ville.slug}`}
                    className="text-sm font-semibold text-brand-primary hover:underline"
                  >
                    Louer à {ville.nom}
                  </Link>
                  <ul className="mt-3 flex flex-wrap gap-2">
                    {quartiers.map((q) => (
                      <li key={q.id}>
                        <Link
                          href={`/${ville.slug}/${q.slug}`}
                          className="inline-block rounded-full border border-brand-border bg-white px-3 py-1 text-sm text-foreground transition-colors hover:border-brand-primary hover:text-brand-primary"
                        >
                          {q.nom}
                        </Link>
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      <div id="pourquoi">
        <ValueProps />
      </div>

      {recentes.length > 0 && (
        <section className="bg-white">
          <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
            <div className="flex items-end justify-between">
              <div>
                <h2 className="text-xs font-semibold uppercase tracking-widest text-brand-gold">
                  Fraîchement publiées
                </h2>
                <p className="mt-2 text-2xl font-bold text-foreground sm:text-3xl">
                  Annonces récentes
                </p>
              </div>
              <Link
                href="/recherche"
                className="hidden text-sm font-semibold text-brand-primary hover:underline sm:inline"
              >
                Voir toutes les annonces →
              </Link>
            </div>
            <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {recentes.map((annonce) => (
                <AnnonceCard key={annonce.id} annonce={annonce} />
              ))}
            </div>
            <Link
              href="/recherche"
              className="mt-8 block text-center text-sm font-semibold text-brand-primary hover:underline sm:hidden"
            >
              Voir toutes les annonces →
            </Link>
          </div>
        </section>
      )}

      <CtaBanner />
    </div>
  );
}
