import { Command } from "commander";
import chalk from "chalk";
import { execSync } from "node:child_process";
import { getStore } from "../utils/helpers.js";

export const editCommand = new Command("edit")
  .description("Open a note in your editor")
  .argument("<identifier>", "Note ID or filename")
  .option("-e, --editor <editor>", "Editor to use (default: $EDITOR or vim)")
  .action((identifier, options) => {
    const store = getStore();
    const note = store.read(identifier);

    if (!note) {
      console.error(chalk.red(`Note not found: ${identifier}`));
      process.exit(1);
    }

    const editor = options.editor || process.env.EDITOR || "vim";

    console.log(
      chalk.dim(`Opening ${note.metadata.title} in ${editor}...`)
    );

    try {
      execSync(`${editor} "${note.filePath}"`, { stdio: "inherit" });
      console.log(chalk.green("Note saved."));
    } catch (err) {
      console.error(chalk.red(`Failed to open editor: ${err}`));
      process.exit(1);
    }
  });
