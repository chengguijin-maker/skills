import type { TagInfo } from "./types.js";
import { NoteStore } from "./store.js";

/**
 * TagManager provides tag-based organization for notes.
 * Tags are stored in each note's frontmatter and aggregated on demand.
 */
export class TagManager {
  private store: NoteStore;

  constructor(store: NoteStore) {
    this.store = store;
  }

  /** Get all tags with usage counts */
  listAll(): TagInfo[] {
    const notes = this.store.listAll();
    const tagMap = new Map<string, TagInfo>();

    for (const note of notes) {
      for (const tag of note.metadata.tags) {
        const normalized = tag.toLowerCase();
        const existing = tagMap.get(normalized);
        if (existing) {
          existing.count++;
          existing.noteIds.push(note.metadata.id);
        } else {
          tagMap.set(normalized, {
            name: normalized,
            count: 1,
            noteIds: [note.metadata.id],
          });
        }
      }
    }

    return Array.from(tagMap.values()).sort((a, b) => b.count - a.count);
  }

  /** Add a tag to a note */
  addTag(noteId: string, tag: string): boolean {
    const note = this.store.read(noteId);
    if (!note) return false;

    const normalized = tag.toLowerCase();
    if (note.metadata.tags.includes(normalized)) return true; // Already has tag

    const updatedTags = [...note.metadata.tags, normalized];
    this.store.update(noteId, { tags: updatedTags });
    return true;
  }

  /** Remove a tag from a note */
  removeTag(noteId: string, tag: string): boolean {
    const note = this.store.read(noteId);
    if (!note) return false;

    const normalized = tag.toLowerCase();
    const updatedTags = note.metadata.tags.filter((t) => t !== normalized);
    if (updatedTags.length === note.metadata.tags.length) return false; // Tag not found

    this.store.update(noteId, { tags: updatedTags });
    return true;
  }

  /** Rename a tag across all notes */
  renameTag(oldTag: string, newTag: string): number {
    const notes = this.store.listByTag(oldTag);
    let count = 0;

    for (const note of notes) {
      const updatedTags = note.metadata.tags.map((t) =>
        t.toLowerCase() === oldTag.toLowerCase() ? newTag.toLowerCase() : t
      );
      this.store.update(note.metadata.id, { tags: updatedTags });
      count++;
    }

    return count;
  }

  /** Delete a tag from all notes */
  deleteTag(tag: string): number {
    const notes = this.store.listByTag(tag);
    let count = 0;

    for (const note of notes) {
      const updatedTags = note.metadata.tags.filter(
        (t) => t.toLowerCase() !== tag.toLowerCase()
      );
      this.store.update(note.metadata.id, { tags: updatedTags });
      count++;
    }

    return count;
  }
}
