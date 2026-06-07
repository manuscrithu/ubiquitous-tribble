import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-6">
      <h1 className="text-4xl font-semibold tracking-tight">URL Shortener</h1>
      <p className="text-gray-500">Shorten links. Track clicks.</p>
      <div className="flex gap-4">
        <Link
          href="/login"
          className="px-4 py-2 rounded-md border border-gray-300 hover:bg-gray-50 transition-colors"
        >
          Log in
        </Link>
        <Link
          href="/register"
          className="px-4 py-2 rounded-md bg-black text-white hover:bg-gray-800 transition-colors"
        >
          Get started
        </Link>
      </div>
    </main>
  );
}