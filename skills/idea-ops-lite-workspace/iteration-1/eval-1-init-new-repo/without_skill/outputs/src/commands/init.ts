import { Command } from "commander";
import chalk from "chalk";
import { NoteStore } from "../core/store.js";
import { resolveRoot } from "../utils/helpers.js";

export const initCommand = new Command("init")
  .description("Initialize a new DevNotes repository")
  .option("-d, --dir <path>", "Root directory for the repository")
  .action((options) => {
    const root = options.dir || resolveRoot();
    const store = new NoteStore(root);
    store.init();
    console.log(chalk.green(`Initialized DevNotes repository at ${root}`));
    console.log(chalk.dim(`Notes will be stored in ${store.notesPath}`));
    console.log(
      chalk.dim(`Config saved to ${store.configPath}`)
    );
  });
