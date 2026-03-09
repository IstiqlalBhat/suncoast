export const env = {
  supabaseUrl:
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://placeholder.supabase.co",
  supabaseAnonKey:
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "placeholder-anon-key",
  firebaseFunctionsUrl: (
    process.env.NEXT_PUBLIC_FIREBASE_FUNCTIONS_URL ??
    "https://us-central1-placeholder.cloudfunctions.net"
  ).replace(/\/$/, ""),
};
