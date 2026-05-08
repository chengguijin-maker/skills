import { describe, it, expect, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { NoteStore } from "../src/core/store.js";

describe("NoteStore", () => {
  let tmpDir: string;
  let store: NoteStore;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "devnotes-test-"));
    store = new NoteStore(tmpDir);
    store.init();
  });

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it("should initialize a repository", () => {
    expect(fs.existsSync(store.notesPath)).toBe(true);
    expect(fs.existsSync(store.configPath)).toBe(true);
  });

  it("should create a note", () => {
    const note = store.create("Test Note", "Hello world", ["test"]);
    expect(note.metadata.title).toBe("Test Note");
    expect(note.metadata.tags).toContain("test");
    expect(note.content).toContain("Hello world");
    expect(fs.existsSync(note.filePath)).toBe(true);
  });

  it("should read a note by ID", () => {
    const created = store.create("Read Test", "Content here");
    const found = store.read(created.metadata.id);
    expect(found).not.toBeNull();
    expect(found!.metadata.title).toBe("Read Test");
  });

  it("should list all notes", () => {
    store.create("Note 1", "First");
    store.create("Note 2", "Second");
    const notes = store.listAll();
    expect(notes).toHaveLength(2);
  });

  it("should update a note", () => {
    const created = store.create("Update Test", "Original");
    const updated = store.update(created.metadata.id, {
      content: "Updated content",
      tags: ["updated"],
    });
    expect(updated).not.toBeNull();
    expect(updated!.content).toContain("Updated content");
    expect(updated!.metadata.tags).toContain("updated");
  });

  it("should delete a note", () => {
    const created = store.create("Delete Test", "To be deleted");
    const result = store.delete(created.metadata.id);
    expect(result).toBe(true);
    expect(store.listAll()).toHaveLength(0);
  });

  it("should filter notes by tag", () => {
    store.create("Tagged", "Content", ["javascript"]);
    store.create("Untagged", "Content");
    const filtered = store.listByTag("javascript");
    expect(filtered).toHaveLength(1);
    expect(filtered[0].metadata.title).toBe("Tagged");
  });

  it("should return null for non-existent note", () => {
    const result = store.read("nonexistent");
    expect(result).toBeNull();
  });
});
