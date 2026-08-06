import type { Ville } from "@/lib/types";
import { TYPE_BIEN_OPTIONS } from "@/lib/format";

// Plain HTML GET form — no client JS required. Submitting navigates the
// browser to /recherche?ville=...&loyerMin=...&type=... etc, which the
// results page reads from its (server-rendered) searchParams. Works even
// with JavaScript disabled, which matters for the 3G / cheap-Android
// audience this whole site targets.
export default function SearchForm({ villes }: { villes: Ville[] }) {
  return (
    <form
      action="/recherche"
      method="get"
      className="grid grid-cols-1 gap-4 rounded-2xl border border-brand-border bg-white p-5 shadow-sm sm:grid-cols-2 lg:grid-cols-5 lg:items-end"
    >
      <div className="flex flex-col gap-1 lg:col-span-1">
        <label htmlFor="ville" className="text-xs font-semibold text-brand-muted">
          Ville
        </label>
        <select
          id="ville"
          name="ville"
          defaultValue=""
          className="rounded-lg border border-brand-border px-3 py-2 text-sm text-foreground"
        >
          <option value="">Toutes les villes</option>
          {villes.map((ville) => (
            <option key={ville.id} value={ville.slug}>
              {ville.nom}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="loyerMin" className="text-xs font-semibold text-brand-muted">
          Budget min (XAF)
        </label>
        <input
          id="loyerMin"
          name="loyerMin"
          type="number"
          min={0}
          step={5000}
          placeholder="0"
          className="rounded-lg border border-brand-border px-3 py-2 text-sm text-foreground"
        />
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="loyerMax" className="text-xs font-semibold text-brand-muted">
          Budget max (XAF)
        </label>
        <input
          id="loyerMax"
          name="loyerMax"
          type="number"
          min={0}
          step={5000}
          placeholder="Sans limite"
          className="rounded-lg border border-brand-border px-3 py-2 text-sm text-foreground"
        />
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="type" className="text-xs font-semibold text-brand-muted">
          Type de bien
        </label>
        <select
          id="type"
          name="type"
          defaultValue=""
          className="rounded-lg border border-brand-border px-3 py-2 text-sm text-foreground"
        >
          <option value="">Tous les types</option>
          {TYPE_BIEN_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="meuble" className="text-xs font-semibold text-brand-muted">
          Meublé
        </label>
        <select
          id="meuble"
          name="meuble"
          defaultValue=""
          className="rounded-lg border border-brand-border px-3 py-2 text-sm text-foreground"
        >
          <option value="">Peu importe</option>
          <option value="true">Meublé</option>
          <option value="false">Non meublé</option>
        </select>
      </div>

      <button
        type="submit"
        className="rounded-lg bg-brand-gold px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-brand-gold-dark lg:col-span-5"
      >
        Rechercher un logement
      </button>
    </form>
  );
}
