"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { apiRequest, getAuthToken, setAuthToken, removeAuthToken } from "@/lib/api";
import { useRouter, usePathname } from "next/navigation";

interface UserProfile {
  id: string;
  telephone: string;
  nomComplet: string | null;
  email: string | null;
  roles: string[];
  villeId: string | null;
}

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  loading: boolean;
  login: (telephoneOrEmail: string, motDePasse: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [token, setTokenState] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const router = useRouter();
  const pathname = usePathname();

  const refreshUser = async () => {
    const storedToken = getAuthToken();
    if (!storedToken) {
      setUser(null);
      setTokenState(null);
      setLoading(false);
      return;
    }

    try {
      setTokenState(storedToken);
      const profile = await apiRequest<UserProfile>("/auth/moi");
      
      // Seuls les rôles STAFF ou ADMIN ont accès au Backoffice
      const isStaffOrAdmin = profile.roles.some((r) => r === "STAFF" || r === "ADMIN");
      if (!isStaffOrAdmin) {
        removeAuthToken();
        setUser(null);
        setTokenState(null);
        throw new Error("Accès refusé : ce compte ne dispose pas des privilèges Staff/Admin.");
      }

      setUser(profile);
    } catch (err) {
      removeAuthToken();
      setUser(null);
      setTokenState(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshUser();
  }, []);

  useEffect(() => {
    if (!loading) {
      if (!user && pathname !== "/login") {
        router.push("/login");
      } else if (user && pathname === "/login") {
        router.push("/");
      }
    }
  }, [user, loading, pathname, router]);

  const login = async (telephoneOrEmail: string, motDePasse: string) => {
    setLoading(true);
    try {
      const data = await apiRequest<{ access_token?: string; accessToken?: string; utilisateur?: UserProfile; user?: UserProfile }>("/auth/connexion", {
        method: "POST",
        body: JSON.stringify({ identifiant: telephoneOrEmail, motDePasse }),
      });

      const token = data.access_token || data.accessToken;
      const userObj = data.utilisateur || data.user;

      if (!token || !userObj) {
        throw new Error("Réponse d'authentification invalide.");
      }

      const isStaffOrAdmin = userObj.roles?.some((r) => r === "STAFF" || r === "ADMIN");
      if (!isStaffOrAdmin) {
        throw new Error("Accès refusé : Ce compte n'a pas les droits STAFF ou ADMIN.");
      }

      setAuthToken(token);
      setTokenState(token);
      setUser(userObj);
      router.push("/");
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    removeAuthToken();
    setUser(null);
    setTokenState(null);
    router.push("/login");
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth doit être utilisé à l'intérieur d'un AuthProvider");
  }
  return context;
}
