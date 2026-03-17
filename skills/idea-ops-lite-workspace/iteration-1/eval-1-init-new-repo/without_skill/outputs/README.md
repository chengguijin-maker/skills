# DevNotes

A local-first personal knowledge base for developers. Manage markdown notes with full-text search and tag management, all from your terminal.

## Features

- **Local-first**: All data stored as plain Markdown files on your filesystem
- **Full-text search**: Fast search powered by lunr.js
- **Tag management**: Organize notes with tags, rename/delete tags across all notes
- **Terminal-native**: Designed for developers who live in the terminal
- **Open format**: Standard Markdown with YAML frontmatter - no vendor lock-in

## Quick Start

```bash
# Install
npm install -g devnotes

# Initialize a knowledge base
devnotes init

# Create your first note
devnotes add "Git Cheatsheet" -t "git,reference" -c "## Common Commands..."

# Search across notes
devnotes search "git rebase"

# List all notes
devnotes list

# View a specific note
devnotes view <note-id>

# Edit in your $EDITOR
devnotes edit <note-id>
```

## Commands

| Command | Description |
|---------|-------------|
| `devnotes init` | Initialize a new knowledge base |
| `devnotes add <title>` | Create a new note |
| `devnotes list` | List all notes |
| `devnotes view <id>` | View a note |
| `devnotes edit <id>` | Edit a note in your editor |
| `devnotes search <query>` | Full-text search |
| `devnotes tag list` | List all tags |
| `devnotes tag add <id> <tag>` | Add a tag to a note |
| `devnotes tag remove <id> <tag>` | Remove a tag |
| `devnotes tag rename <old> <new>` | Rename a tag everywhere |

## Configuration

Set `DEVNOTES_ROOT` to change the storage location (default: `~/.devnotes`).

Set `EDITOR` to configure which editor opens with `devnotes edit`.

## License

MIT
