import { Command } from "commander";
import chalk from "chalk";
import { getStore } from "../utils/helpers.js";

export const addCommand = new Command("add")
  .description("Create a new note")
  .argument("<title>", "Title for the new note")
  .option("-t, --tags <tags>", "Comma-separated tags", "")
  .option("-c, --content <content>", "Note content (or pipe from stdin)", "")
  .action((title, options) => {
    const store = getStore();
    const tags = options.tags
      ? options.tags.split(",").map((t: string) => t.trim())
      : [];
    const note = store.create(title, options.content, tags);

    console.log(chalk.green(`Created note: ${note.metadata.title}`));
    console.log(chalk.dim(`  ID:   ${note.metadata.id}`));
    console.log(chalk.dim(`  File: ${note.filePath}`));
    if (note.metadata.tags.length > 0) {
      console.log(
        chalk.dim(`  Tags: ${note.metadata.tags.join(", ")}`)
      );
    }
  });
