import { Command } from "commander";
import chalk from "chalk";
import { getSearchEngine, truncate } from "../utils/helpers.js";

export const searchCommand = new Command("search")
  .description("Full-text search across all notes")
  .argument("<query>", "Search query")
  .option("-l, --limit <n>", "Maximum number of results", "10")
  .action((query, options) => {
    const engine = getSearchEngine();
    const results = engine.search(query);
    const limit = parseInt(options.limit, 10);

    if (results.length === 0) {
      console.log(chalk.yellow(`No results found for "${query}"`));
      return;
    }

    console.log(
      chalk.bold(`Found ${results.length} result(s) for "${query}":\n`)
    );

    for (const result of results.slice(0, limit)) {
      const { note, score, matches } = result;
      console.log(
        chalk.green(`  ${note.metadata.title}`) +
          chalk.dim(` [${note.metadata.id}] score: ${score.toFixed(2)}`)
      );
      if (note.metadata.tags.length > 0) {
        console.log(
          chalk.cyan(`    tags: ${note.metadata.tags.join(", ")}`)
        );
      }
      for (const match of matches.slice(0, 3)) {
        console.log(chalk.dim(`    > ${truncate(match, 100)}`));
      }
      console.log();
    }
  });
