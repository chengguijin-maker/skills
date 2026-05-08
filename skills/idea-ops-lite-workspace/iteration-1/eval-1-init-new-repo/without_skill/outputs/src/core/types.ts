/**
 * Core type definitions for DevNotes
 */

/** Frontmatter metadata for a note */
export interface NoteMetadata {
  title: string;
  tags: string[];
  created: string;
  modified: string;
  id: string;
}

/** A complete note with content and metadata */
export interface Note {
  metadata: NoteMetadata;
  content: string;
  filePath: string;
}

/** Configuration for a DevNotes repository */
export interface DevNotesConfig {
  /** Root directory for notes storage */
  notesDir: string;
  /** Default editor command (falls back to $EDITOR) */
  editor: string;
  /** Default tags applied to new notes */
  defaultTags: string[];
  /** File extension for notes */
  extension: string;
}

/** Search result with relevance score */
export interface SearchResult {
  note: Note;
  score: number;
  /** Matched snippets for context display */
  matches: string[];
}

/** Tag with usage statistics */
export interface TagInfo {
  name: string;
  count: number;
  noteIds: string[];
}
