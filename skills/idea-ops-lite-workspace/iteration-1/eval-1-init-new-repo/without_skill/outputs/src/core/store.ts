import * as fs from "node:fs";
import * as path from "node:path";
import matter from "gray-matter";
import { randomUUID } from "node:crypto";
import type { Note, NoteMetadata, DevNotesConfig } from "./types.js";

const DEFAULT_CONFIG: DevNotesConfig = {
  notesDir: "notes",
  editor: process.env.EDITOR || "vim",
  defaultTags: [],
  extension: ".md",
};

/**
 * NoteStore manages the filesystem-based note storage.
 * Notes are stored as markdown files with YAML frontmatter.
 */
export class NoteStore {
  private rootDir: string;
  private config: DevNotesConfig;

  constructor(rootDir: string, config?: Partial<DevNotesConfig>) {
    this.rootDir = rootDir;
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /** Get the full path to the notes directory */
  get notesPath(): string {
    return path.join(this.rootDir, this.config.notesDir);
  }

  /** Get the config file path */
  get configPath(): string {
    return path.join(this.rootDir, ".devnotes.json");
  }

  /** Initialize a new DevNotes repository */
  init(): void {
    if (!fs.existsSync(this.rootDir)) {
      fs.mkdirSync(this.rootDir, { recursive: true });
    }
    if (!fs.existsSync(this.notesPath)) {
      fs.mkdirSync(this.notesPath, { recursive: true });
    }
    fs.writeFileSync(
      this.configPath,
      JSON.stringify(this.config, null, 2),
      "utf-8"
    );
  }

  /** Load config from disk */
  loadConfig(): DevNotesConfig {
    if (fs.existsSync(this.configPath)) {
      const raw = fs.readFileSync(this.configPath, "utf-8");
      this.config = { ...DEFAULT_CONFIG, ...JSON.parse(raw) };
    }
    return this.config;
  }

  /** Create a new note and return it */
  create(title: string, content: string, tags: string[] = []): Note {
    const id = randomUUID().slice(0, 8);
    const now = new Date().toISOString();
    const metadata: NoteMetadata = {
      title,
      tags: [...this.config.defaultTags, ...tags],
      created: now,
      modified: now,
      id,
    };

    const fileName = this.slugify(title) + this.config.extension;
    const filePath = path.join(this.notesPath, fileName);

    const fileContent = matter.stringify(content, metadata);
    fs.writeFileSync(filePath, fileContent, "utf-8");

    return { metadata, content, filePath };
  }

  /** Read a note by its file name or ID */
  read(identifier: string): Note | null {
    const notes = this.listAll();
    return (
      notes.find(
        (n) =>
          n.metadata.id === identifier ||
          path.basename(n.filePath) === identifier ||
          path.basename(n.filePath, this.config.extension) === identifier
      ) || null
    );
  }

  /** Update a note's content and/or tags */
  update(
    id: string,
    updates: { content?: string; tags?: string[]; title?: string }
  ): Note | null {
    const note = this.read(id);
    if (!note) return null;

    if (updates.title !== undefined) note.metadata.title = updates.title;
    if (updates.tags !== undefined) note.metadata.tags = updates.tags;
    if (updates.content !== undefined) note.content = updates.content;
    note.metadata.modified = new Date().toISOString();

    const fileContent = matter.stringify(note.content, note.metadata);
    fs.writeFileSync(note.filePath, fileContent, "utf-8");

    return note;
  }

  /** Delete a note by ID */
  delete(id: string): boolean {
    const note = this.read(id);
    if (!note) return false;
    fs.unlinkSync(note.filePath);
    return true;
  }

  /** List all notes */
  listAll(): Note[] {
    if (!fs.existsSync(this.notesPath)) return [];

    const files = fs
      .readdirSync(this.notesPath)
      .filter((f) => f.endsWith(this.config.extension));

    return files.map((file) => {
      const filePath = path.join(this.notesPath, file);
      const raw = fs.readFileSync(filePath, "utf-8");
      const parsed = matter(raw);
      return {
        metadata: parsed.data as NoteMetadata,
        content: parsed.content,
        filePath,
      };
    });
  }

  /** List notes filtered by tag */
  listByTag(tag: string): Note[] {
    return this.listAll().filter((n) =>
      n.metadata.tags.map((t) => t.toLowerCase()).includes(tag.toLowerCase())
    );
  }

  /** Generate a URL-safe slug from a title */
  private slugify(text: string): string {
    return text
      .toLowerCase()
      .replace(/[^\w\s-]/g, "")
      .replace(/[\s_]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80);
  }
}
