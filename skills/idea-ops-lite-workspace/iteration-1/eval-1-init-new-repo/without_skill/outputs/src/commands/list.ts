import { Command } from "commander";
import chalk from "chalk";
import { getStore, formatDate, truncate } from "../utils/helpers.js";

export const listCommand = new Command("list")
  .description("List all notes")
  .alias("ls")
  .option("-t, --tag <tag>", "Filter by tag")
  .option("-s, --sort <field>", "Sort by: created, modified, title", "modified")
  .action((options) => {
    const store = getStore();
    let notes = options.tag ? store.listByTag(options.tag) : store.listAll();

    if (notes.length === 0) {
      console.log(chalk.yellow("No notes found."));
      if (options.tag) {
        console.log(chalk.dim(`  (filtered by tag: ${options.tag})`));
      }
      return;
    }

    // Sort
    notes.sort((a, b) => {
      switch (options.sort) {
        case "created":
          return (
            new Date(b.metadata.created).getTime() -
            new Date(a.metadata.created).getTime()
          );
        case "title":
          return a.metadata.title.localeCompare(b.metadata.title);
        case "modified":
        default:
          return (
            new Date(b.metadata.modified).getTime() -
            new Date(a.metadata.modified).getTime()
          );
      }
    });

    console.log(chalk.bold(`Notes (${notes.length}):\n`));

    for (const note of notes) {
      const preview = truncate(note.content.trim().split("\n")[0] || "", 60);
      console.log(
        chalk.green(`  ${note.metadata.title}`) +
          chalk.dim(` [${note.metadata.id}]`)
      );
      console.log(
        chalk.dim(`    modified: ${formatDate(note.metadata.modified)}`)
      );
      if (note.metadata.tags.length > 0) {
        console.log(
          chalk.cyan(`    tags: ${note.metadata.tags.join(", ")}`)
        );
      }
      if (preview) {
        console.log(chalk.dim(`    ${preview}`));
      }
      console.log();
    }
  });
