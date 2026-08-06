import Link from "next/link";
import Image from "next/image";

export default function CtaBanner() {
  return (
    <section className="relative overflow-hidden bg-slate-900">
      <Image
        src="/pexels-gustavo-fring-7489096.jpg"
        alt=""
        fill
        sizes="100vw"
        className="object-cover object-[50%_20%] opacity-50"
      />
      <div className="absolute inset-0 bg-gradient-to-r from-slate-950/95 via-slate-950/60 to-slate-950/20" />

      <div className="relative mx-auto max-w-6xl px-4 py-16 sm:px-6">
        <div className="max-w-lg">
          <h2 className="text-2xl font-bold text-white sm:text-3xl">
            Prêt à trouver votre prochain chez-vous ?
          </h2>
          <p className="mt-3 text-slate-300">
            Parcourez les annonces vérifiées à Douala, Yaoundé et dans les
            autres villes couvertes — et contactez directement le bailleur
            dès que vous avez trouvé le bien qui vous correspond.
          </p>
          <Link
            href="/recherche"
            className="mt-6 inline-flex items-center gap-2 rounded-lg bg-brand-gold px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-gold-dark"
          >
            Rechercher un logement
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </Link>
        </div>
      </div>
    </section>
  );
}
