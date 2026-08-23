import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  async rewrites() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8080/api/v1";
    if (apiUrl.startsWith("http")) {
      const target = apiUrl.replace(/\/$/, "");
      return [
        {
          source: "/api/v1/:path*",
          destination: `${target}/:path*`,
        },
      ];
    }
    return [];
  },
};

export default nextConfig;
