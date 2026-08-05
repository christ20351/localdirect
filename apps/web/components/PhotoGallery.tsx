import { isDisplayablePhoto } from "@/lib/api";

export default function PhotoGallery({
  photos,
  titre,
}: {
  photos: string[];
  titre: string;
}) {
  const displayable = photos.filter(isDisplayablePhoto);

  if (displayable.length === 0) {
    return (
      <div className="flex aspect-video w-full items-center justify-center rounded-xl bg-brand-surface text-brand-muted">
        Aucune photo disponible pour cette annonce
      </div>
    );
  }

  const [main, ...rest] = displayable;

  return (
    <div className="flex flex-col gap-2">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={main}
        alt={titre}
        className="aspect-video w-full rounded-xl object-cover"
      />
      {rest.length > 0 && (
        <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
          {rest.map((src, i) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              key={src + i}
              src={src}
              alt={`${titre} — photo ${i + 2}`}
              loading="lazy"
              className="aspect-square w-full rounded-lg object-cover"
            />
          ))}
        </div>
      )}
    </div>
  );
}
