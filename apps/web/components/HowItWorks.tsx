const STEPS = [
  {
    title: "Recherchez par quartier",
    text: "Filtrez par ville, quartier, budget et type de bien. Le loyer, l'avance et la caution sont toujours affichés en clair, sans surprise.",
    icon: (
      <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-4.35-4.35M11 19a8 8 0 100-16 8 8 0 000 16z" />
    ),
  },
  {
    title: "Contactez le bailleur, directement",
    text: "Chaque annonce affiche le numéro WhatsApp et le contact téléphonique du propriétaire. Pas de démarcheur entre vous deux.",
    icon: (
      <path strokeLinecap="round" strokeLinejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-6l-4 4v-4z" />
    ),
  },
  {
    title: "Visitez et emménagez",
    text: "Organisez la visite avec le bailleur, vérifiez que tout correspond, puis déposez votre dossier pour signer le bail.",
    icon: (
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
    ),
  },
];

export default function HowItWorks() {
  return (
    <section className="border-b border-brand-border bg-white">
      <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
        <div className="max-w-xl">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-brand-gold">
            Comment ça marche
          </h2>
          <p className="mt-2 text-2xl font-bold text-foreground sm:text-3xl">
            Trois étapes, zéro intermédiaire.
          </p>
        </div>

        <div className="mt-10 grid gap-8 sm:grid-cols-3">
          {STEPS.map((step, i) => (
            <div key={step.title} className="relative">
              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-primary/10 text-brand-primary">
                <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.8}>
                  {step.icon}
                </svg>
              </div>
              <span className="mt-4 block text-xs font-bold text-brand-gold">
                Étape {i + 1}
              </span>
              <h3 className="mt-1 text-base font-semibold text-foreground">
                {step.title}
              </h3>
              <p className="mt-2 text-sm text-brand-muted">{step.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
