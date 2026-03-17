import lunr from "lunr";
import type { Note, SearchResult } from "./types.js";
import { NoteStore } from "./store.js";

/**
 * SearchEngine provides full-text search over notes using lunr.js.
 * The index is built in-memory on each search for simplicity.
 * Future optimization: persist the index and rebuild incrementally.
 */
export class SearchEngine {
  private store: NoteStore;

  constructor(store: NoteStore) {
    this.store = store;
  }

  /** Build a lunr index from all notes */
  private buildIndex(notes: Note[]): lunr.Index {
    return lunr(function () {
      this.ref("id");
      this.field("title", { boost: 10 });
      this.field("tags", { boost: 5 });
      this.field("content");

      for (const note of notes) {
        this.add({
          id: note.metadata.id,
          title: note.metadata.title,
          tags: note.metadata.tags.join(" "),
          content: note.content,
        });
      }
    });
  }

  /** Search notes by query string. Returns results sorted by relevance. */
  search(query: string): SearchResult[] {
    const notes = this.store.listAll();
    if (notes.length === 0) return [];

    const index = this.buildIndex(notes);
    const results = index.search(query);

    const noteMap = new Map(notes.map((n) => [n.metadata.id, n]));

    return results
      .map((result) => {
        const note = noteMap.get(result.ref);
        if (!note) return null;

        // Extract matching snippets
        const matches = this.extractMatches(note, query);

        return {
          note,
          score: result.score,
          matches,
        };
      })
      .filter((r): r is SearchResult => r !== null);
  }

  /** Extract context snippets around matched terms */
  private extractMatches(note: Note, query: string): string[] {
    const terms = query.toLowerCase().split(/\s+/);
    const lines = note.content.split("\n");
    const matches: string[] = [];

    for (const line of lines) {
      const lower = line.toLowerCase();
      if (terms.some((term) => lower.includes(term))) {
        const trimmed = line.trim();
        if (trimmed.length > 0) {
          matches.push(
            trimmed.length > 120 ? trimmed.slice(0, 120) + "..." : trimmed
          );
        }
      }
    }

    return matches.slice(0, 5); // Limit to 5 snippets
  }
}
