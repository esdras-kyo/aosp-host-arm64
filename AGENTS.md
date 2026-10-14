# AGENTS.md

## Project goal

Enable native AOSP builds on Linux ARM64 hosts without relying on x86/x86_64 emulation.

## Current focus

- AOSP Android 13
- Linux ARM64 host
- `gsi_arm64-userdebug`

## Rules

- Do not use Box64, QEMU user-mode, or x86 emulation as a solution.
- Do not commit AOSP source trees or build outputs.
- Prefer reproducible fixes over manual local workarounds.
- Keep changes focused and documented.
- Do not modify unrelated parts of the project.
