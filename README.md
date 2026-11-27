# IrukaDark CLI

Generate images, videos, music and voice with your [IrukaDark](https://irukadark.com) account, from your terminal or from coding agents such as Claude Code and Codex. Generations use your IrukaDark credits.

> **Preview.** The IrukaDark CLI is in preview. Commands, options and output may change before 1.0.

## Install

macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/co-r-e/irukadark-cli/main/install.sh | sh
```

The script downloads the file for your computer from the latest release, checks it against `SHA256SUMS` and puts it in `~/.local/bin`.

Windows 11 (PowerShell or Windows Terminal, no administrator rights needed):

```powershell
irm https://raw.githubusercontent.com/co-r-e/irukadark-cli/main/install.ps1 | iex
```

The script puts `irukadark.exe` in `%LOCALAPPDATA%\Programs\irukadark-cli` and adds that folder to your user `PATH`, so apps you start afterwards (Claude Code, Codex, VS Code) find it. Inside WSL, the Linux version works for image, video, music and voice; use the Windows `irukadark.exe` for the IrukaDark Desktop tools (3D and Timeline).

Or install it with npm (Node.js 18 or later):

```sh
npm install -g irukadark
```

The npm package contains the same files as the releases.

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

In other MCP hosts, register the installed command:

```json
{
  "mcpServers": {
    "irukadark": { "command": "irukadark", "args": ["mcp"] }
  }
}
```

If the host cannot find `irukadark`, use the full path that `which irukadark` (`where irukadark` on Windows) shows.

You can also run it with `npx` without installing the CLI (sign in once first with `npx -y irukadark@latest auth login`). Keep `@latest`: without it, npx runs an `irukadark` found in the folder the agent works in before the one on npm.

```json
{
  "mcpServers": {
    "irukadark": { "command": "npx", "args": ["-y", "irukadark@latest", "mcp"] }
  }
}
```

The MCP server reads and saves files only inside the folder the agent works in. Open the agent in a project folder: your home folder and the top of a disk cannot be that folder.

## Update

```sh
irukadark update
```

If you installed it with npm, run `npm install -g irukadark@latest` instead. irukadark checks for a new version once a day and tells you when one is available. It never updates itself in the background.

On Windows, `irukadark update` and `npm install -g irukadark@latest` also work while an agent is running `irukadark mcp`. npm may warn that it failed to remove some directories: the old files are still in use, and npm removes them the next time it installs irukadark. Restart the agent to use the new version.

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

`irukadark auth login` opens your browser. Approve the request there and the browser returns to irukadark. On a machine without a browser, run `irukadark auth login --device`, open the page it shows on any device, and enter the code.

The sign-in can only create media and read what irukadark uses (models, runs, assets, directions, uploads, credits and your files). It is kept in the system keychain (Windows Credential Manager on Windows; on macOS and Linux, in a file under `~/.irukadark/` when no keychain is available) and renews itself while you use it. `irukadark auth logout` signs out and removes it. You can also sign it out from Sign-in & security on irukadark.com.

## License

irukadark is proprietary software of CORe, Inc. See [LICENSE](https://github.com/co-r-e/irukadark-cli/blob/main/LICENSE). It includes third-party software under its own licenses, listed in [THIRD-PARTY-NOTICES.txt](https://github.com/co-r-e/irukadark-cli/blob/main/THIRD-PARTY-NOTICES.txt).
