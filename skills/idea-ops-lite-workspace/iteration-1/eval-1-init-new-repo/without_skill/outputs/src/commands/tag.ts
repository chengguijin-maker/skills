import { Command } from "commander";
import chalk from "chalk";
import { getStore, getTagManager } from "../utils/helpers.js";

export const tagCommand = new Command("tag")
  .description("Manage tags across notes");

tagCommand
  .command("list")
  .alias("ls")
  .description("List all tags with usage counts")
  .action(() => {
    const tagManager = getTagManager();
    const tags = tagManager.listAll();

    if (tags.length === 0) {
      console.log(chalk.yellow("No tags found."));
      return;
    }

    console.log(chalk.bold(`Tags (${tags.length}):\n`));
    for (const tag of tags) {
      const bar = "█".repeat(Math.min(tag.count, 30));
      console.log(
        chalk.cyan(`  ${tag.name.padEnd(20)}`) +
          chalk.dim(` ${tag.count.toString().padStart(3)} `) +
          chalk.green(bar)
      );
    }
  });

tagCommand
  .command("add")
  .description("Add a tag to a note")
  .argument("<noteId>", "Note ID")
  .argument("<tag>", "Tag to add")
  .action((noteId, tag) => {
    const tagManager = getTagManager();
    const success = tagManager.addTag(noteId, tag);

    if (success) {
      console.log(chalk.green(`Added tag "${tag}" to note ${noteId}`));
    } else {
      console.error(chalk.red(`Note not found: ${noteId}`));
      process.exit(1);
    }
  });

tagCommand
  .command("remove")
  .alias("rm")
  .description("Remove a tag from a note")
  .argument("<noteId>", "Note ID")
  .argument("<tag>", "Tag to remove")
  .action((noteId, tag) => {
    const tagManager = getTagManager();
    const success = tagManager.removeTag(noteId, tag);

    if (success) {
      console.log(chalk.green(`Removed tag "${tag}" from note ${noteId}`));
    } else {
      console.error(chalk.red(`Tag "${tag}" not found on note ${noteId}`));
      process.exit(1);
    }
  });

tagCommand
  .command("rename")
  .description("Rename a tag across all notes")
  .argument("<oldTag>", "Current tag name")
  .argument("<newTag>", "New tag name")
  .action((oldTag, newTag) => {
    const tagManager = getTagManager();
    const count = tagManager.renameTag(oldTag, newTag);
    console.log(
      chalk.green(
        `Renamed tag "${oldTag}" to "${newTag}" across ${count} note(s)`
      )
    );
  });
