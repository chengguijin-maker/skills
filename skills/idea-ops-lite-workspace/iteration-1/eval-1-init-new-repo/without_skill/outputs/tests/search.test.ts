import { describe, it, expect, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { NoteStore } from "../src/core/store.js";
import { SearchEngine } from "../src/core/search.js";

describe("SearchEngine", () => {
  let tmpDir: string;
  let store: NoteStore;
  let engine: SearchEngine;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "devnotes-search-test-"));
    store = new NoteStore(tmpDir);
    store.init();
    engine = new SearchEngine(store);
  });

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it("should return empty results for empty store", () => {
    const results = engine.search("anything");
    expect(results).toHaveLength(0);
  });

  it("should find notes by title", () => {
    store.create("JavaScript Guide", "Learn JS basics");
    store.create("Python Tutorial", "Learn Python basics");

    const results = engine.search("javascript");
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].note.metadata.title).toBe("JavaScript Guide");
  });

  it("should find notes by content", () => {
    store.create("Note A", "This note discusses TypeScript generics");
    store.create("Note B", "This note is about cooking recipes");

    const results = engine.search("generics");
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].note.metadata.title).toBe("Note A");
  });

  it("should find notes by tags", () => {
    store.create("Tagged Note", "Some content", ["react", "frontend"]);
    store.create("Other Note", "Other content", ["backend"]);

    const results = engine.search("react");
    expect(results.length).toBeGreaterThan(0);
  });

  it("should rank title matches higher", () => {
    store.create("React Hooks Guide", "A guide about hooks");
    store.create("General Notes", "React is mentioned here in passing");

    const results = engine.search("react");
    expect(results.length).toBeGreaterThanOrEqual(2);
    // Title match should score higher
    expect(results[0].note.metadata.title).toBe("React Hooks Guide");
  });
});
