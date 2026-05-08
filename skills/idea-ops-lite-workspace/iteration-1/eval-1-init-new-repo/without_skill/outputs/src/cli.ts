#!/usr/bin/env node

import { Command } from "commander";
import { addCommand } from "./commands/add.js";
import { searchCommand } from "./commands/search.js";
import { listCommand } from "./commands/list.js";
import { viewCommand } from "./commands/view.js";
import { editCommand } from "./commands/edit.js";
import { tagCommand } from "./commands/tag.js";
import { initCommand } from "./commands/init.js";

const program = new Command();

program
  .name("devnotes")
  .description(
    "A local-first personal knowledge base for developers. Manage markdown notes with full-text search and tags from your terminal."
  )
  .version("0.1.0");

program.addCommand(initCommand);
program.addCommand(addCommand);
program.addCommand(searchCommand);
program.addCommand(listCommand);
program.addCommand(viewCommand);
program.addCommand(editCommand);
program.addCommand(tagCommand);

program.parse();
