import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as bcrypt from 'bcrypt';

const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:hexapy666@localhost:5432/locadirect_db?schema=public';
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = 'admin@gmail.com';
  const motDePasse = 'admin123';
  const motDePasseHash = await bcrypt.hash(motDePasse, 10);
  const telephone = '+237699999999';

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
  console.log(`- Mot de passe : ${motDePasse}`);
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
