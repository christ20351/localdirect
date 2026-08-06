import Image from "next/image";

const PROPS = [
  {
    title: "Contact direct, zéro démarcheur",
    text: "Le numéro du bailleur — appel et WhatsApp — est visible directement sur l'annonce. Personne ne prélève de frais entre vous deux.",
  },
  {
    title: "Transparence financière totale",
    text: "Loyer, avance (en mois) et caution sont détaillés dès la fiche de recherche : vous savez ce qu'il faut réunir avant de visiter.",
  },
  {
    title: "Biens vérifiés avant publication",
    text: "Chaque annonce est contrôlée par notre équipe (photos, cohérence du prix, preuve de propriété) avant d'apparaître dans le catalogue.",
  },
];

export default function ValueProps() {
  return (
    <section className="bg-brand-surface">
      <div className="mx-auto grid max-w-6xl gap-10 px-4 py-16 sm:px-6 lg:grid-cols-2 lg:items-center lg:gap-16">
        <div className="relative order-2 aspect-[3/4] overflow-hidden rounded-2xl lg:order-1">
          <Image
            src="/pexels-pavel-danilyuk-7937368.jpg"
            alt="Vérification d'un bien avant publication sur LocaDirect CM"
            fill
            sizes="(min-width: 1024px) 40vw, 100vw"
            className="object-cover object-[50%_68%]"
          />
        </div>

        <div className="order-1 lg:order-2">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-brand-gold">
            Pourquoi LocaDirect CM
          </h2>
          <p className="mt-2 text-2xl font-bold text-foreground sm:text-3xl">
            Le confort d&apos;une plateforme, la simplicité du contact direct.
          </p>

          <ul className="mt-8 space-y-6">
            {PROPS.map((p) => (
              <li key={p.title} className="flex gap-3">
                <svg
                  className="mt-0.5 h-5 w-5 shrink-0 text-brand-primary"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  strokeWidth={2}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
                <div>
                  <h3 className="text-sm font-semibold text-foreground">{p.title}</h3>
                  <p className="mt-1 text-sm text-brand-muted">{p.text}</p>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
