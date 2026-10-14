# Project

## Goal

Enable AOSP and, later, LineageOS to build natively on Linux ARM64 hosts without requiring x86/x86_64 host emulation.

The first practical target is Android 13.

## Initial target

Host:
- Linux ARM64

Android:
- AOSP Android 13
- `gsi_arm64-userdebug`

Initial success condition:
- build the Android 13 GSI natively on Linux ARM64
- do not execute x86/x86_64 host binaries

## Problem

AOSP supports ARM64 as a target architecture, but parts of the build system still assume a Linux x86_64 host.

Typical problem areas include:

- `linux-x86` prebuilts
- host architecture assumptions
- Soong bootstrap
- Clang/LLVM
- Go
- Rust
- JDK
- auxiliary host tools

This project exists to progressively remove or isolate those assumptions.

## Scope

This project may contain:

- compatibility patches for AOSP/LineageOS
- reproducible ARM64 host-tool recipes
- bootstrap and build scripts
- auditing and verification tools
- documentation about blockers and decisions

## Out of scope

For now, this project is not about:

- porting Android to a specific device
- kernel development for Android devices
- creating a custom ROM
- building AOSP directly on macOS
- using x86 emulation as the final solution

Apple Silicon is relevant only as a practical ARM64 machine running Linux.

## Current phase

The current phase is investigation and bring-up for Android 13 on Linux ARM64.
