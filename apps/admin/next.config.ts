import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Serveur autonome : Next ne conserve que les modules réellement importés.
  // Sans cette option, l'image de production devrait embarquer node_modules
  // en entier (plusieurs centaines de Mo).
  output: "standalone",
};

export default nextConfig;
