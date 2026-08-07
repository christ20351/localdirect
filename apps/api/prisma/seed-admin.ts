import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as bcrypt from 'bcrypt';

const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:hexapy666@localhost:5432/locadirect_db?schema=public';
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  // Paramétrable par l'environnement : en production, `admin123` ne doit
  // jamais être écrit en base. Les valeurs par défaut ne servent qu'au
  // développement local.
  const email = process.env.ADMIN_EMAIL || 'admin@gmail.com';
  const motDePasse = process.env.ADMIN_PASSWORD || 'admin123';
  const telephone = process.env.ADMIN_TELEPHONE || '+237699999999';

  if (process.env.NODE_ENV === 'production' && !process.env.ADMIN_PASSWORD) {
    throw new Error(
      'ADMIN_PASSWORD est obligatoire en production : refus de créer un compte administrateur avec le mot de passe par défaut.',
    );
  }

  const motDePasseHash = await bcrypt.hash(motDePasse, 10);

  const existing = await prisma.utilisateur.findFirst({
    where: { OR: [{ email }, { telephone }, { email: 'admin@locadirect.cm' }] },
  });

  let admin;
  if (existing) {
    admin = await prisma.utilisateur.update({
      where: { id: existing.id },
      data: {
        email,
        telephone,
        motDePasseHash,
        roles: ['ADMIN', 'STAFF'],
        telephoneVerifie: true,
        bloque: false,
      },
    });
  } else {
    admin = await prisma.utilisateur.create({
      data: {
        email,
        telephone,
        telephoneVerifie: true,
        nomComplet: 'Administrateur Système',
        motDePasseHash,
        roles: ['ADMIN', 'STAFF'],
      },
    });
  }

  console.log('✅ Compte Administrateur mis à jour avec succès :');
  console.log(`- Email : ${admin.email}`);
  // Le mot de passe n'est affiché qu'en développement : en production il
  // finirait dans les journaux Docker, lisibles par quiconque a accès au démon.
  console.log(
    process.env.NODE_ENV === 'production'
      ? '- Mot de passe : (celui fourni via ADMIN_PASSWORD)'
      : `- Mot de passe : ${motDePasse}`,
  );
  console.log(`- Rôles : ${admin.roles.join(', ')}`);
}

main()
  .catch((e) => {
    console.error('❌ Erreur lors de la création de l\'admin :', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
