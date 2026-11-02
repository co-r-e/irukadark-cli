# IrukaDark CLI

Generate images, videos, music and voice with your [IrukaDark](https://irukadark.com) account, from your terminal or from coding agents such as Claude Code and Codex. Generations use your IrukaDark credits.

> **Preview.** The IrukaDark CLI is in preview. Commands, options and output may change before 1.0.

## Install

macOS and Linux (on Windows, use WSL):

```sh
curl -fsSL https://raw.githubusercontent.com/co-r-e/irukadark-cli/main/install.sh | sh
```

The script downloads the file for your computer from the latest release, checks it against `SHA256SUMS` and puts it in `~/.local/bin`.

## Get started

```sh
irukadark auth login          # sign in with your browser
irukadark models list         # see the models
irukadark models get <model>  # see a model's parameters, media and rules
irukadark quote <model> "a cat on a sofa"
irukadark generate <model> "a cat on a sofa" --wait
```

Attach files with `--start-image`, `--end-image`, `--image`, `--video` and `--audio`. Repeat a flag to attach more files. Name a file with `--image cat=./cat.png` and use `@cat` in the prompt. Use your directions with `~name`.

`--wait` waits up to 10 minutes and saves the files in the current folder (or `--out <dir>`). Existing files are never overwritten. If it takes longer, the run continues on the server: `irukadark runs wait <run_id>`.

Every command takes `--json`.

## Use with Claude Code and Codex

Install the skill, which teaches the agents how to use the CLI:

```sh
irukadark skills install
```

Or add the skill from this repository:

```sh
npx skills add co-r-e/irukadark-cli
```

You can also connect the MCP server:

```sh
claude mcp add --scope user irukadark -- irukadark mcp
codex mcp add irukadark -- irukadark mcp
```

The MCP server reads and saves files only inside the folder the agent works in.

## Update

```sh
irukadark update
```

irukadark checks for a new version once a day and tells you when one is available. It never updates itself in the background.

## Exit codes

| Code | Meaning                                         |
| ---- | ----------------------------------------------- |
| 0    | Done                                            |
| 1    | Failed                                          |
| 2    | Canceled                                        |
| 3    | Not enough credits                              |
| 4    | Sign-in required                                |
| 5    | Still running after `--wait`; the run continues |

## Sign-in and tokens

The token is kept in the system keychain (or `~/.config/irukadark/credentials.json` when no keychain is available). `IRUKADARK_TOKEN` overrides it. `irukadark auth logout` signs out and removes the token.

Do not put the token in an MCP configuration: it would be saved in plain text.
