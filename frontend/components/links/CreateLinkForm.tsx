"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";

interface Props {
  onCreated: () => void;
}

export function CreateLinkForm({ onCreated }: Props) {
  const [url, setUrl] = useState("");
  const [slug, setSlug] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await api.post("/links/", {
        original_url: url,
        slug: slug.trim() || undefined,
      });
      setUrl("");
      setSlug("");
      onCreated();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to create link");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-wrap gap-3 items-end">
      <Input
        label="Long URL"
        type="url"
        value={url}
        onChange={(e) => setUrl(e.target.value)}
        required
        placeholder="https://example.com/very/long/url"
        className="min-w-72"
      />
      <Input
        label="Custom slug (optional)"
        value={slug}
        onChange={(e) => setSlug(e.target.value)}
        placeholder="my-link"
        className="w-40"
      />
      <Button type="submit" loading={loading}>
        Shorten
      </Button>
      {error && <p className="text-red-500 text-sm w-full">{error}</p>}
    </form>
  );
}
