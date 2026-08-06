import type { Quartier, Ville } from "@/lib/types";
import { TYPE_BIEN_OPTIONS } from "@/lib/format";

type Props = {
  villes: Ville[];
  quartiers: Quartier[];
  current: {
    ville?: string;
    quartier?: string;
    type?: string;
    meuble?: string;
    loyerMin?: string;
    loyerMax?: string;
  };
};

// Same no-JS GET form pattern as the homepage's SearchForm, plus a quartier
// select. The quartier list is fetched server-side for whichever ville is
// currently selected (see app/recherche/page.tsx), so refining by quartier
// still works without any client-side JavaScript — submitting just reloads
// /recherche with the new query string.
export default function FiltersBar({ villes, quartiers, current }: Props) {
  return (
    <form
      action="/recherche"
      method="get"
      className="grid grid-cols-2 gap-3 rounded-xl border border-brand-border bg-white p-4 sm:grid-cols-3 lg:grid-cols-6 lg:items-end"
    >
      <div className="flex flex-col gap-1">
        <label htmlFor="ville" className="text-xs font-semibold text-brand-muted">
          Ville
        </label>
        <select
          id="ville"
          name="ville"
          defaultValue={current.ville ?? ""}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground"
        >
          <option value="">Toutes</option>
          {villes.map((ville) => (
            <option key={ville.id} value={ville.slug}>
              {ville.nom}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="quartier" className="text-xs font-semibold text-brand-muted">
          Quartier
        </label>
        <select
          id="quartier"
          name="quartier"
          defaultValue={current.quartier ?? ""}
          disabled={quartiers.length === 0}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground disabled:opacity-50"
        >
          <option value="">
            {quartiers.length === 0 ? "Choisir une ville d'abord" : "Tous"}
          </option>
          {quartiers.map((q) => (
            <option key={q.id} value={q.slug}>
              {q.nom}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="type" className="text-xs font-semibold text-brand-muted">
          Type
        </label>
        <select
          id="type"
          name="type"
          defaultValue={current.type ?? ""}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground"
        >
          <option value="">Tous</option>
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
          defaultValue={current.meuble ?? ""}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground"
        >
          <option value="">Peu importe</option>
          <option value="true">Meublé</option>
          <option value="false">Non meublé</option>
        </select>
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="loyerMin" className="text-xs font-semibold text-brand-muted">
          Budget min
        </label>
        <input
          id="loyerMin"
          name="loyerMin"
          type="number"
          min={0}
          step={5000}
          defaultValue={current.loyerMin ?? ""}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground"
        />
      </div>

      <div className="flex flex-col gap-1">
        <label htmlFor="loyerMax" className="text-xs font-semibold text-brand-muted">
          Budget max
        </label>
        <input
          id="loyerMax"
          name="loyerMax"
          type="number"
          min={0}
          step={5000}
          defaultValue={current.loyerMax ?? ""}
          className="rounded-lg border border-brand-border px-2 py-2 text-sm text-foreground"
        />
      </div>

      <button
        type="submit"
        className="col-span-2 rounded-lg bg-brand-primary px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-primary-dark sm:col-span-3 lg:col-span-6"
      >
        Filtrer
      </button>
    </form>
  );
}
