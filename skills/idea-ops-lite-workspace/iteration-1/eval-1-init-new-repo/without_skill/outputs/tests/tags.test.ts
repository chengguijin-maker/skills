import { describe, it, expect, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { NoteStore } from "../src/core/store.js";
import { TagManager } from "../src/core/tags.js";

describe("TagManager", () => {
  let tmpDir: string;
  let store: NoteStore;
  let tagManager: TagManager;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "devnotes-tags-test-"));
    store = new NoteStore(tmpDir);
    store.init();
    tagManager = new TagManager(store);
  });

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it("should list all tags with counts", () => {
    store.create("Note 1", "Content", ["javascript", "react"]);
    store.create("Note 2", "Content", ["javascript", "node"]);
    store.create("Note 3", "Content", ["python"]);

    const tags = tagManager.listAll();
    expect(tags).toHaveLength(4);

    const jsTag = tags.find((t) => t.name === "javascript");
    expect(jsTag).toBeDefined();
    expect(jsTag!.count).toBe(2);
  });

  it("should add a tag to a note", () => {
    const note = store.create("Test", "Content", ["existing"]);
    const result = tagManager.addTag(note.metadata.id, "new-tag");
    expect(result).toBe(true);

    const updated = store.read(note.metadata.id);
    expect(updated!.metadata.tags).toContain("new-tag");
  });

  it("should remove a tag from a note", () => {
    const note = store.create("Test", "Content", ["remove-me", "keep"]);
    const result = tagManager.removeTag(note.metadata.id, "remove-me");
    expect(result).toBe(true);

    const updated = store.read(note.metadata.id);
    expect(updated!.metadata.tags).not.toContain("remove-me");
    expect(updated!.metadata.tags).toContain("keep");
  });

  it("should rename a tag across all notes", () => {
    store.create("Note 1", "Content", ["old-name"]);
    store.create("Note 2", "Content", ["old-name"]);
    store.create("Note 3", "Content", ["other"]);

    const count = tagManager.renameTag("old-name", "new-name");
    expect(count).toBe(2);

    const tags = tagManager.listAll();
    expect(tags.find((t) => t.name === "old-name")).toBeUndefined();
    expect(tags.find((t) => t.name === "new-name")).toBeDefined();
  });

  it("should delete a tag from all notes", () => {
    store.create("Note 1", "Content", ["delete-me", "keep"]);
    store.create("Note 2", "Content", ["delete-me"]);

    const count = tagManager.deleteTag("delete-me");
    expect(count).toBe(2);

    const tags = tagManager.listAll();
    expect(tags.find((t) => t.name === "delete-me")).toBeUndefined();
  });

  it("should return false for non-existent note", () => {
    const result = tagManager.addTag("fake-id", "tag");
    expect(result).toBe(false);
  });
});
