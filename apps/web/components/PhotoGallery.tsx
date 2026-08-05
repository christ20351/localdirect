import { isDisplayablePhoto } from "@/lib/api";
import PhotoCarousel from "./PhotoCarousel";

export default function PhotoGallery({
  photos,
  titre,
}: {
  photos: string[];
  titre: string;
}) {
  const displayable = photos.filter(isDisplayablePhoto);

  return (
    <div className="overflow-hidden rounded-xl">
      <PhotoCarousel photos={displayable} alt={titre} aspect="aspect-video" />
    </div>
  );
}
