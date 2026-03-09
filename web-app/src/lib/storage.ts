"use client";

import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { MediaAttachment, MediaType } from "@/lib/types";

export async function uploadSessionFile(
  sessionId: string,
  file: File,
  type: MediaType = "photo",
) {
  const supabase = getSupabaseBrowserClient();
  const fileName = `${Date.now()}-${file.name.replace(/\s+/g, "-")}`;
  const storagePath = `${sessionId}/${fileName}`;

  const { error: uploadError } = await supabase.storage
    .from("media-attachments")
    .upload(storagePath, file, {
      contentType: file.type,
      upsert: false,
    });

  if (uploadError) {
    throw new Error(uploadError.message);
  }

  const { data, error } = await supabase
    .from("media_attachments")
    .insert({
      session_id: sessionId,
      type,
      storage_path: storagePath,
      mime_type: file.type || null,
      file_size_bytes: file.size,
      metadata: {
        originalName: file.name,
      },
    })
    .select("*")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as MediaAttachment;
}

export async function createSignedFileUrl(storagePath: string) {
  const supabase = getSupabaseBrowserClient();
  const { data, error } = await supabase.storage
    .from("media-attachments")
    .createSignedUrl(storagePath, 60 * 30);

  if (error) {
    throw new Error(error.message);
  }

  return data.signedUrl;
}
