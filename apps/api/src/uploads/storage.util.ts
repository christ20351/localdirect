import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import * as fs from 'fs';

export const UPLOADS_ROOT = join(process.cwd(), 'uploads');
export const DOCUMENTS_DIR = join(UPLOADS_ROOT, 'documents');
export const MEDIAS_DIR = join(UPLOADS_ROOT, 'medias');
export const BAUX_DIR = join(UPLOADS_ROOT, 'baux');

/// Crée les dossiers de stockage local au démarrage (multer ne les crée pas lui-même).
export function assurerDossiersUploads() {
  fs.mkdirSync(DOCUMENTS_DIR, { recursive: true });
  fs.mkdirSync(MEDIAS_DIR, { recursive: true });
  fs.mkdirSync(BAUX_DIR, { recursive: true });
}

export function multerStorage(dir: string) {
  return diskStorage({
    destination: dir,
    filename: (_req, file, cb) => {
      cb(null, `${randomUUID()}${extname(file.originalname || '')}`);
    },
  });
}
