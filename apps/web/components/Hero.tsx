import Link from "next/link";
import Image from "next/image";

type Props = {
  villesCount: number;
  annoncesCount: number;
};

export default function Hero({ villesCount, annoncesCount }: Props) {
  return (
    <section className="bg-white">
      <div className="mx-auto grid max-w-6xl gap-14 px-4 pt-14 pb-24 sm:px-6 sm:pt-20 lg:grid-cols-2 lg:items-center lg:gap-16 lg:pb-32">
        {/* Texte */}
        <div>
          <span className="inline-flex items-center gap-2 rounded-full border border-brand-border bg-brand-surface px-3 py-1 text-xs font-semibold text-brand-primary">
            <span className="h-1.5 w-1.5 rounded-full bg-brand-gold" />
            Sans démarcheur, sans intermédiaire
          </span>

          <h1 className="mt-5 text-3xl font-bold tracking-tight text-foreground sm:text-5xl">
            Trouvez votre prochain logement au Cameroun, en contact direct
            avec le bailleur.
          </h1>
          <p className="mt-4 max-w-lg text-base text-brand-muted sm:text-lg">
            Studios, chambres modernes et appartements à Douala, Yaoundé et
            ailleurs. Loyer, avance et caution affichés dès la recherche —
            vous appelez ou écrivez directement au propriétaire sur WhatsApp.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Link
              href="/recherche"
              className="rounded-lg bg-brand-gold px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-gold-dark"
            >
              Rechercher un logement
            </Link>
           
          </div>

          <dl className="mt-10 flex flex-wrap gap-x-8 gap-y-3">
            <div>
              <dt className="text-xs uppercase tracking-wide text-brand-muted">Villes couvertes</dt>
              <dd className="text-xl font-bold text-foreground">{villesCount || "—"}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-brand-muted">Annonces vérifiées</dt>
              <dd className="text-xl font-bold text-foreground">{annoncesCount || "—"}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-brand-muted">Frais de démarchage</dt>
              <dd className="text-xl font-bold text-foreground">0 FCFA</dd>
            </div>
          </dl>
        </div>

        {/* Deux photos superposées */}
        <div className="relative mx-auto w-full max-w-sm lg:max-w-none">
          <div className="relative aspect-[4/5] w-full overflow-hidden rounded-3xl shadow-xl shadow-slate-900/10">
            <Image
              src="/house.jpg"
              alt="Maison en vente"
              fill
              priority
              sizes="(min-width: 1024px) 40vw, 80vw"
              className="object-cover"
            />
          </div>
          <div className="absolute -bottom-10 -left-6 aspect-[4/3] w-2/3 overflow-hidden rounded-2xl border-4 border-white shadow-xl shadow-slate-900/15 sm:-left-10">
            <Image
              src="/pexels-zvolskiy-2062426.jpg"
              alt="Intérieur chaleureux d'un logement disponible sur LocaDirect CM"
              fill
              sizes="(min-width: 1024px) 25vw, 50vw"
              className="object-cover"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
