# Prebuilts manifest (ARM64 host bring-up)

Metadata only. **No binaries are stored in this repo.** These ARM64 prebuilts
were placed manually in the AOSP tree to explore the critical path. They are
**temporary / exploration** and are not a definitive solution (the definitive
path is to build them from source in-tree, not copy them).

| Item | Version / content | Origin | Destination in AOSP tree | Size | Status |
|---|---|---|---|---|---|
| Go toolchain | `go1.18.10 linux/arm64` | modern AOSP `prebuilts/go/linux-arm64` (copied) | `prebuilts/go/linux-arm64/` | 338M | temporary / exploration |
| build-tools (ARM64) | `bin/` (37 host tools: aidl, ckati, aconfig, bison, bloaty, brotli, bzip2, acp, bash, …) + `lib64/` | modern AOSP `prebuilts/build-tools/linux-arm64` (copied) | `prebuilts/build-tools/linux-arm64/` | 202M | temporary / exploration |
| build-tools PATH interposer | 85 symlinks (awk, cat, chmod, bc, cmp, …) | modern AOSP `prebuilts/build-tools/path/linux-arm64` (copied) | `prebuilts/build-tools/path/linux-arm64/` | 4K | temporary / exploration |

## Still absent (intentionally not introduced)

- **JDK8 host ARM64** — `prebuilts/jdk/jdk8/linux-arm64` — current bring-up stop.
- **Clang host ARM64** — `prebuilts/clang/host/*` is `linux-x86` only.

## Notes

- `prebuilts/go` is not a git project in this tree; `linux-arm64/` is a loose
  manually-added directory. `prebuilts/build-tools/linux-arm64` and
  `path/linux-arm64` are untracked in that project.
- These are **not** fetched automatically yet (no `fetch-prebuilts.sh`).
- Patches in this repo do **not** touch prebuilts.
