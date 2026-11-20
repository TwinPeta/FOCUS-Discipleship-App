import type { MetadataRoute } from "next";

/** Installable web app: the same name, colours and icon as the mobile app. */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "FCU Student Community",
    short_name: "FCU",
    description: "Connect with students on your campus, learn together and grow with mentors.",
    start_url: "/dashboard",
    display: "standalone",
    background_color: "#FFFAF2",
    theme_color: "#FFFAF2",
    icons: [
      { src: "/icon.png", sizes: "512x512", type: "image/png" },
      { src: "/apple-icon.png", sizes: "180x180", type: "image/png" },
    ],
  };
}
