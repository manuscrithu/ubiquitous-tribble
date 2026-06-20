"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { clearToken, isLoggedIn } from "@/lib/auth";
import { CreateLinkForm } from "@/components/links/CreateLinkForm";
import { LinkTable, type LinkRow } from "@/components/links/LinkTable";

interface Analytics {
  total_clicks: number;
  by_country: { country: string; count: number }[];
  by_device: { device_type: string; count: number }[];
  by_referrer: { referrer: string; count: number }[];
  daily: { date: string; count: number }[];
}

export default function DashboardPage() {
  const router = useRouter();
  const [links, setLinks] = useState<LinkRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);

  const fetchLinks = useCallback(async () => {
    try {
      const data = await api.get<LinkRow[]>("/links/");
      setLinks(data);
    } catch {
      clearToken();
      router.push("/login");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    if (!isLoggedIn()) {
      router.push("/login");
      return;
    }
    fetchLinks();
  }, [fetchLinks, router]);

  async function viewAnalytics(id: number) {
    const data = await api.get<Analytics>(`/links/${id}/analytics`);
    setAnalytics(data);
  }

  function logout() {
    clearToken();
    router.push("/login");
  }

  if (loading) {
    return (
      <main className="min-h-screen p-8">
        <p className="text-gray-400 text-sm">Loading…</p>
      </main>
    );
  }

  return (
    <main className="min-h-screen p-8 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-semibold">Your links</h1>
        <button
          onClick={logout}
          className="text-sm text-gray-500 hover:text-gray-800"
        >
          Log out
        </button>
      </div>

      <div className="mb-10">
        <CreateLinkForm onCreated={fetchLinks} />
      </div>

      <LinkTable
        links={links}
        onRefresh={fetchLinks}
        onViewAnalytics={viewAnalytics}
      />

      {/* Analytics modal */}
      {analytics && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setAnalytics(null)}
        >
          <div
            className="bg-white rounded-xl p-8 w-full max-w-lg max-h-[80vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-semibold">Analytics</h2>
              <button
                onClick={() => setAnalytics(null)}
                className="text-gray-400 hover:text-gray-600 text-lg"
              >
                ✕
              </button>
            </div>

            <p className="text-5xl font-bold mb-1">{analytics.total_clicks}</p>
            <p className="text-gray-500 text-sm mb-8">total clicks</p>

            {analytics.by_country.length > 0 && (
              <Section title="By Country">
                {analytics.by_country.map((r) => (
                  <Row key={r.country} label={r.country} value={r.count} />
                ))}
              </Section>
            )}

            {analytics.by_device.length > 0 && (
              <Section title="By Device">
                {analytics.by_device.map((r) => (
                  <Row
                    key={r.device_type}
                    label={
                      r.device_type.charAt(0).toUpperCase() +
                      r.device_type.slice(1)
                    }
                    value={r.count}
                  />
                ))}
              </Section>
            )}

            {analytics.by_referrer.length > 0 && (
              <Section title="Top Referrers">
                {analytics.by_referrer.map((r) => (
                  <Row key={r.referrer} label={r.referrer} value={r.count} />
                ))}
              </Section>
            )}

            {analytics.daily.length > 0 && (
              <Section title="Daily Clicks">
                {analytics.daily.map((r) => (
                  <Row key={r.date} label={r.date} value={r.count} />
                ))}
              </Section>
            )}

            {analytics.total_clicks === 0 && (
              <p className="text-gray-400 text-sm">No clicks recorded yet.</p>
            )}
          </div>
        </div>
      )}
    </main>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-6">
      <h3 className="font-medium text-gray-700 mb-2">{title}</h3>
      <div className="space-y-1">{children}</div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex justify-between text-sm py-1 border-b border-gray-100">
      <span className="text-gray-600 truncate max-w-xs">{label}</span>
      <span className="font-medium tabular-nums ml-4">{value}</span>
    </div>
  );
}
