---
name: irukadark
description: Generate images, videos, music and voice with IrukaDark using the user's account and credits. Use when the user asks to create or edit an image, a video clip, a music track or a voice-over, or mentions IrukaDark.
---

# IrukaDark CLI

The `irukadark` command generates images, videos, music and voice with the user's IrukaDark account.
Generations use the user's credits. This skill was written for irukadark 0.1.2.

## Before you start

- Check that you are signed in: `irukadark whoami`. If not, ask the user to run `irukadark auth login`
  (it opens a browser and asks the user to type a code; you cannot do it for them).
- Add `--json` to any command to get machine-readable output on stdout. Progress goes to stderr.

## Choose a model

1. `irukadark models list` lists the models by family (`--kind image|video|music|voice` narrows it).
2. `irukadark models get <model_id>` shows what the model is good at, its parameters and allowed values,
   which files it accepts, and its rules. Read it before you generate with a model you have not used.

## Check the price first

Videos can be expensive. Before generating a video (or many images), run `irukadark quote` with the same
arguments as `generate` and tell the user the price in credits. `irukadark credits` shows the balance.

## Generate

```sh
irukadark generate <model_id> "<prompt>" [parameters] [files] [--count N] [--wait] [--out <dir>]
```

- Parameters come from the model: `--aspect-ratio 16:9`, `--resolution 720p`, `--duration-seconds 8`,
  `--audio-on false`. A parameter the CLI does not know yet can be sent with `--param name=value`.
- Files: `--start-image` and `--end-image` are frames; `--image`, `--video` and `--audio` are references
  (for LTX 2.5, `--audio` makes the video from the audio track). Repeat a flag for several files:
  `--image a.png --image b.png`. A flag takes a local path, a file ID, or an asset ID.
  Attach files from one group only (frames, references or audio); without files the prompt alone is used.
- Name a file with `--image cat=./cat.png` and refer to it in the prompt as `@cat`. Unnamed files are
  `@image_1`, `@video_1`, `@audio_1` in the order you attach them. `@name` also finds the user's assets
  (`irukadark assets list`, `--official` for the official ones).
- `~name` in the prompt adds a direction (a saved style text): `irukadark directions list`. `--direction <id>` also adds one.
- Voice: `--voice <voice_id>` and `--style "<how to read it>"`.
- If the CLI stops before sending (for example `--resolution must be 480p or 720p when reference images are attached`),
  fix the arguments as the message says. Nothing was charged.

## Waiting for long generations

`generate` prints the run ID as soon as the run is accepted. `--wait` keeps reading the run every 3 seconds
for up to 10 minutes and then saves the files to `--out` (default: the current folder). Existing files are
never overwritten.

Shell tools often stop a command before 10 minutes. If the command is stopped, the generation keeps running
on the server: run `irukadark runs wait <run_id> --out <dir>` to wait again and save the files. Without
`--wait`, check later with `irukadark runs get <run_id>`.

- Claude Code stops a command after 2 minutes by default. Set the Bash tool's timeout up to 10 minutes for
  `--wait`, or run the command in the background and read its output when it finishes.
- Codex also stops long commands. Start the run without `--wait`, note the run ID, then run
  `irukadark runs wait <run_id> --out <dir>` as a separate command. If it ends with exit code 5 (still
  running), run the same command again.

## Exit codes

0 success · 1 failure · 2 canceled · 3 not enough credits · 4 sign-in required · 5 still running after the wait.
On 3, tell the user to add credits. On 4, ask the user to run `irukadark auth login`.
Failed outputs do not use credits.

## Save a style for later

`irukadark directions add --name "<name>" --text "<style text>" [--sample image.png]` saves a direction the
user can reuse as `~name`. `irukadark assets add <path> --name <name>` saves a file as an asset (`@name`).
