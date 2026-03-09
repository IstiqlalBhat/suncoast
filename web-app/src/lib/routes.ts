export const appNavigation = [
  { href: "/dashboard", label: "Operations" },
  { href: "/history", label: "History" },
  { href: "/settings", label: "Settings" },
] as const;

export function routeForActivityType(type: "passive" | "twoway" | "media") {
  switch (type) {
    case "passive":
      return "passive";
    case "twoway":
      return "chat";
    case "media":
      return "media";
  }
}
