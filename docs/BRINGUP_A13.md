# Bring-up: AOSP 13 native Linux ARM64 host

Technical history of making Soong/Make run natively on a Linux ARM64 host
(no x86/x86_64 emulation, no Box64/QEMU). Frozen before tackling the JDK/Clang
prebuilts frontier.

## Baseline

- AOSP tag: **android-13.0.0_r68**
- Lunch target: `aosp_arm64-userdebug`

## Goal

Make `m nothing` pass natively on Linux ARM64. `m nothing` exercises the full
critical path — Go bootstrap → Soong self-tests → Soong analysis (`build.ninja`)
→ Kati — without compiling modules. Getting it green proves host-arch plumbing
is correct before real module builds.

## Environment

- Host (build machine): Linux ARM64, Ubuntu, kernel `6.8.0-147-generic`, `aarch64`.
- Driven over SSH (`aosp-arm64`); tree at `/home/esdras/android/aosp-13`.
- Go: `go1.18.10 linux/arm64` (temporary prebuilt, see below).
- Client: macOS (patches/repo live here).

## Blockers cleared, in order

1. `panic: unsupported Arch: arm64` — `determineBuildOS` had no `arm64` → `BuildArch`.
2. `PrebuiltOS()` hardcoded `linux-x86` vs arch-aware `pathForInstall` → host paths disagreed.
3. `pathForInstall` forced host Common/X86_64 → `"x86"` on any host.
4. `ui/build` `PrebuiltOS()` hardcoded → bootstrap stuck at `out/host/linux-x86`.
5. Soong self-test tail assumed an x86 host → made fixtures model a fixed x86_64 glibc host.
6. `field "target.linux_glibc_arm64" does not exist` → first (reverted) attempt added arm64 to `linux_glibc`.
7. `Toolchain not found for linux_glibc arch "arm64"` → **pivot to the upstream design: arm64 Linux host = musl**.
8. `Toolchain not found for linux_musl arch "arm64"` → new toolchain file missing from `cc/config/Android.bp` srcs.
9. Go duplicate type `toolchainLinuxArm64` → renamed the bionic one to `toolchainLinuxBionicArm64`.
10. `Unknown os+arch: linux_musl_arm64` (bp2build) → extended the os/arch platform map.
11. **STOP** → missing `prebuilts/jdk/jdk8/linux-arm64` (real prebuilt).

Verified at stop: `Toolchain not found` = 0, `Unknown os+arch` = 0.

## Changes by area (→ patches)

Each area is one patch under `patches/`; order is `patches/series`.

| Area | Patch | Files | What |
|---|---|---|---|
| A — host arch naming | soong `0001` | `android/paths.go`, `ui/build/config.go`, `ui/build/path.go` | host dir / tag / PATH resolve to `linux-arm64` |
| B — arch/OS registration | soong `0002` | `android/arch.go` | `linux_musl += Arm64, Arm`; `determineBuildOS` → `Arm64` + musl on arm64 host |
| C — musl ARM64 toolchain | soong `0003` | `cc/config/arm_linux_host.go` (new), `Android.bp`, `arm64_linux_host.go` | musl arm/arm64 host toolchain + srcs + rename |
| D — bp2build os/arch | soong `0004` | `bazel/configurability.go` | `linux_musl_arm[64]` consts/map + arch list |
| E — test fixture pinning | soong `0005` | `android/config.go` | `PrebuiltOS()`→`BuildArch`; fixtures pin x86_64 glibc host |
| F — Go bootstrap | soong `0006` | `scripts/microfactory.bash` | `aarch64` → `prebuilts/go/linux-arm64` |
| Make host arm64 | make `0001` | `core/envsetup.mk` | `HOST_ARCH/HOST_PREBUILT_ARCH = arm64` |
| Make combo | make `0002` | `core/combo/HOST_linux-arm64.mk` (new) | host combo include |

## Upstream backports vs local adaptations

**Direct upstream backports** (exist in AOSP master; core of the musl host design):
- `linux_musl += Arm64, Arm` (arch.go).
- `determineBuildOS` `BuildArch` `arm64` case (arch.go).
- `cc/config/arm_linux_host.go` — verbatim upstream (ClangTriple `aarch64-linux-musl`).
- `cc/config/Android.bp` srcs entry.
- `arm64_linux_host.go` rename `toolchainLinuxArm64` → `toolchainLinuxBionicArm64`.
- `bazel/configurability.go` `linux_musl_arm[64]` entries.

**Local adaptations** (bring-up specific; upstream only cross-compiles `linux_musl_arm64` from an x86 host, it does not build *on* an arm64 host):
- `determineBuildOS`: `|| runtime.GOARCH == "arm64"` to auto-select musl (upstream relies on the `HostMusl` product var).
- `android/config.go`: `PrebuiltOS()` keyed on `BuildArch`; fixtures pin `BuildOS=Linux, BuildArch=X86_64` for deterministic self-tests.
- `android/paths.go`: host dir arm64 branch.
- `ui/build/config.go` (`PrebuiltOS`/`HostPrebuiltTag`), `ui/build/path.go`, `scripts/microfactory.bash`.
- `build/make`: `envsetup.mk` host arch, `combo/HOST_linux-arm64.mk`.

## Temporary ARM64 prebuilts used

Exploration-only. **Not committed to this repo, not promoted to a definitive
solution, not fetched automatically yet.**

| Path (in AOSP tree) | Size | Content |
|---|---|---|
| `prebuilts/go/linux-arm64/` | 338M | Go `go1.18.10 linux/arm64` |
| `prebuilts/build-tools/linux-arm64/` | 202M | `bin/` (37 host tools: aidl, ckati, aconfig…) + `lib64/` |
| `prebuilts/build-tools/path/linux-arm64/` | 4K | 85 interposer symlinks |

Clang host ARM64 and JDK8 ARM64 were **deliberately not** introduced.

## Current state (exact)

Soong reaches **analysis** (generating `out/soong/build.ninja`). The musl ARM64
host toolchain resolves, so cc host-arm64 variants no longer panic. Analysis then
stops at the first **real prebuilt** gap:

```
error: dalvik/dx/Android.bp: module "dx" variant "linux_musl_common":
  source path "prebuilts/jdk/jdk8/linux-arm64/jre/lib/rt.jar" does not exist
```

Java host modules (`linux_musl_common` variant) require a host JDK8 for arm64,
which is absent. The musl toolchain so far is **analysis-only** — nothing is
compiled; its flags would only be exercised when a host arm64 C++ module builds.

Also open (mechanical, not structural, and blocked behind the JDK gap anyway):
4 bp2build conversion self-tests whose golden output now needs the
`linux_musl_arm64` select key.

**`m nothing` does not pass yet.**

## Predicted next blockers

1. **JDK8 host ARM64** — `prebuilts/jdk/jdk8/linux-arm64` (current stop).
2. **Clang host ARM64** — `prebuilts/clang/host` is `linux-x86` only.
3. **`libc_musl` / build-tools** — musl libc built from source; remaining host
   build-tools for arm64.

These are all real-prebuilt / real-toolchain problems, intentionally deferred.
