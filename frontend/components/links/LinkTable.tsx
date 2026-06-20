"use client";

import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";

export interface LinkRow {
  id: number;
  slug: string;
  original_url: string;
  is_active: boolean;
  created_at: string;
  expires_at: string | null;
  click_count: number;
}

interface Props {
  links: LinkRow[];
  onRefresh: () => void;
  onViewAnalytics: (id: number) => void;
}

const SHORT_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export function LinkTable({ links, onRefresh, onViewAnalytics }: Props) {
  async function toggleActive(link: LinkRow) {
    try {
      await api.patch(`/links/${link.id}`, { is_active: !link.is_active });
      onRefresh();
    } catch {
      // silently ignore; parent will still refresh
    }
  }

  async function deleteLink(id: number) {
    if (!confirm("Delete this link? This cannot be undone.")) return;
    await api.delete(`/links/${id}`);
    onRefresh();
  }

  if (links.length === 0) {
    return (
      <p className="text-gray-400 text-sm py-6">
        No links yet. Shorten your first URL above.
      </p>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm border-collapse">
        <thead>
          <tr className="border-b border-gray-200">
            {["Short URL", "Original URL", "Clicks", "Status", "Actions"].map(
              (h) => (
                <th
                  key={h}
                  className="text-left py-3 pr-6 font-medium text-gray-500 whitespace-nowrap"
                >
                  {h}
                </th>
              )
            )}
          </tr>
        </thead>
        <tbody>
          {links.map((link) => (
            <tr
              key={link.id}
              className="border-b border-gray-100 hover:bg-gray-50"
            >
              <td className="py-3 pr-6 whitespace-nowrap">
                <a
                  href={`${SHORT_BASE}/${link.slug}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline font-mono"
                >
                  /{link.slug}
                </a>
              </td>
              <td
                className="py-3 pr-6 max-w-xs truncate text-gray-600"
                title={link.original_url}
              >
                {link.original_url}
              </td>
              <td className="py-3 pr-6 tabular-nums">{link.click_count}</td>
              <td className="py-3 pr-6">
                <span
                  className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                    link.is_active
                      ? "bg-green-100 text-green-700"
                      : "bg-gray-100 text-gray-500"
                  }`}
                >
                  {link.is_active ? "Active" : "Inactive"}
                </span>
              </td>
              <td className="py-3">
                <div className="flex gap-2">
                  <Button
                    variant="secondary"
                    className="text-xs py-1 px-2"
                    onClick={() => onViewAnalytics(link.id)}
                  >
                    Analytics
                  </Button>
                  <Button
                    variant="secondary"
                    className="text-xs py-1 px-2"
                    onClick={() => toggleActive(link)}
                  >
                    {link.is_active ? "Deactivate" : "Activate"}
                  </Button>
                  <Button
                    variant="danger"
                    className="text-xs py-1 px-2"
                    onClick={() => deleteLink(link.id)}
                  >
                    Delete
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
