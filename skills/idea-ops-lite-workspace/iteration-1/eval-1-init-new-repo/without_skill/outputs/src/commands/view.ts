import { Command } from "commander";
import chalk from "chalk";
import { getStore, formatDate } from "../utils/helpers.js";

export const viewCommand = new Command("view")
  .description("View a note by ID or filename")
  .argument("<identifier>", "Note ID or filename")
  .option("-r, --raw", "Show raw markdown without rendering")
  .action((identifier, options) => {
    const store = getStore();
    const note = store.read(identifier);

    if (!note) {
      console.error(chalk.red(`Note not found: ${identifier}`));
      process.exit(1);
    }

    // Header
    console.log(chalk.bold.green(`\n  ${note.metadata.title}\n`));
    console.log(chalk.dim(`  ID:       ${note.metadata.id}`));
    console.log(
      chalk.dim(`  Created:  ${formatDate(note.metadata.created)}`)
    );
    console.log(
      chalk.dim(`  Modified: ${formatDate(note.metadata.modified)}`)
    );
    if (note.metadata.tags.length > 0) {
      console.log(
        chalk.cyan(`  Tags:     ${note.metadata.tags.join(", ")}`)
      );
    }
    console.log(chalk.dim("  " + "─".repeat(60)));
    console.log();

    // Content
    if (options.raw) {
      console.log(note.content);
    } else {
      // Simple rendering: display as-is for now
      // Future: use marked + marked-terminal for rich rendering
      console.log(note.content);
    }
  });
