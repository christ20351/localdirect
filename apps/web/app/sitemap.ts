import type { MetadataRoute } from "next";
import { getQuartiers, getVilles, searchAnnonces } from "@/lib/api";
import { SITE_URL } from "@/lib/site";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const entries: MetadataRoute.Sitemap = [
    { url: SITE_URL, changeFrequency: "daily", priority: 1 },
    { url: `${SITE_URL}/recherche`, changeFrequency: "hourly", priority: 0.8 },
  ];

  try {
    const villes = await getVilles("OUVERTE");
    for (const ville of villes) {
      entries.push({
        url: `${SITE_URL}/${ville.slug}`,
        lastModified: ville.updatedAt,
        changeFrequency: "daily",
        priority: 0.8,
      });

      try {
        const quartiers = await getQuartiers(ville.slug);
        for (const quartier of quartiers) {
          entries.push({
            url: `${SITE_URL}/${ville.slug}/${quartier.slug}`,
            changeFrequency: "daily",
            priority: 0.9,
          });
        }
      } catch {
        // Skip this city's quartiers if the API hiccups; the rest of the
        // sitemap still gets built.
      }
    }
  } catch {
    // API unreachable — return the static entries rather than failing the
    // whole sitemap route.
  }

  try {
    // Cap at 200 listings: cheap at today's inventory size, and a sane
    // ceiling once the catalogue grows (individual listings are still
    // reachable via internal links even when not sitemapped).
    const result = await searchAnnonces({ limit: "200" }, 300);
    for (const annonce of result.data) {
      entries.push({
        url: `${SITE_URL}/annonces/${annonce.id}`,
        lastModified: annonce.createdAt,
        changeFrequency: "weekly",
        priority: 0.6,
      });
    }
  } catch {
    // Ignore — listing URLs remain reachable via internal links.
  }

  return entries;
}
