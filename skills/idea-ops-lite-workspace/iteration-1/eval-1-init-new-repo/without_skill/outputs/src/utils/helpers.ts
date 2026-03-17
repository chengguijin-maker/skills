import * as path from "node:path";
import * as os from "node:os";
import { NoteStore } from "../core/store.js";
import { SearchEngine } from "../core/search.js";
import { TagManager } from "../core/tags.js";
import type { DevNotesConfig } from "../core/types.js";

/** Default root directory for DevNotes */
const DEFAULT_ROOT = path.join(os.homedir(), ".devnotes");

/** Resolve the root directory from env or default */
export function resolveRoot(): string {
  return process.env.DEVNOTES_ROOT || DEFAULT_ROOT;
}

/** Create and return a configured NoteStore */
export function getStore(root?: string): NoteStore {
  const rootDir = root || resolveRoot();
  const store = new NoteStore(rootDir);
  store.loadConfig();
  return store;
}

/** Create and return a SearchEngine */
export function getSearchEngine(store?: NoteStore): SearchEngine {
  return new SearchEngine(store || getStore());
}

/** Create and return a TagManager */
export function getTagManager(store?: NoteStore): TagManager {
  return new TagManager(store || getStore());
}

/** Format a date string for display */
export function formatDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Truncate a string to a max length */
export function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 3) + "...";
}
