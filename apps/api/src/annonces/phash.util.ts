import { Jimp } from 'jimp';
import { Logger } from '@nestjs/common';

const logger = new Logger('PerceptualHash');

/// 🖼️ Hachage perceptuel (pHash, DCT 32x32 → 8x8) via Jimp (pur JS, aucune dépendance
/// native — préféré à `sharp` pour un déploiement VPS aux ressources incertaines).
/// Retourne une chaîne hex de 16 caractères (64 bits), ou `null` si le fichier est
/// illisible (ne doit jamais faire échouer l'upload).
export async function computePerceptualHash(filePath: string): Promise<string | null> {
  try {
    const image = await Jimp.read(filePath);
    const binaryHash = image.pHash(); // chaîne binaire de 64 caractères ('0'/'1')
    return binHashToHex(binaryHash);
  } catch (err) {
    logger.warn(`Impossible de calculer le pHash de ${filePath} : ${(err as Error).message}`);
    return null;
  }
}

function binHashToHex(bin: string): string {
  let hex = '';
  for (let i = 0; i < bin.length; i += 4) {
    hex += parseInt(bin.slice(i, i + 4).padEnd(4, '0'), 2).toString(16);
  }
  return hex;
}

function hexToBinHash(hex: string): string {
  let bin = '';
  for (const ch of hex) {
    bin += parseInt(ch, 16).toString(2).padStart(4, '0');
  }
  return bin;
}

/// 📏 Distance de Hamming entre deux pHash hex (0 = identiques, 64 = totalement opposés).
export function hammingDistanceHex(hexA: string, hexB: string): number {
  const a = hexToBinHash(hexA);
  const b = hexToBinHash(hexB);
  const len = Math.min(a.length, b.length);
  let distance = Math.abs(a.length - b.length);
  for (let i = 0; i < len; i++) {
    if (a[i] !== b[i]) distance++;
  }
  return distance;
}

/// Seuil retenu pour considérer deux photos comme quasi-identiques (anti-fraude).
export const SEUIL_DOUBLON_PHASH = 5;
