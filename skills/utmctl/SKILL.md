---
name: utmctl
description: Operate UTM virtual machines on macOS with the bundled utmctl CLI. Use for VM lifecycle, guest commands and files, USB devices, IP lookup, or snapshots; check the installed UTM version before applying version-specific behavior.
---

# UTM command line

Use UTM's bundled CLI at `/Applications/UTM.app/Contents/MacOS/utmctl`. It is a wrapper around UTM's scripting interface and needs a logged-in macOS graphical session. The binary may not be on `PATH`; call the full path or use an existing link. Identify a VM by its complete name or UUID. Quote names with spaces and prefer UUIDs in repeatable scripts.

Before acting, run `utmctl version` and `utmctl help <command>` for the installed release. This skill's [command reference](references/commands.md) was checked against UTM 5.0.8 on macOS 26.6.2. Treat local help as authoritative when versions differ. The [official scripting guide](https://docs.getutm.app/scripting/scripting/) and [v5.0.8 source](https://github.com/utmapp/UTM/blob/v5.0.8/utmctl/UTMCtl.swift) provide further detail.

For routine VM work:

1. Use `list` and `status` to resolve the exact VM and its current state.
2. Check the relevant backend and host requirements before guest-agent, USB, disposable, or snapshot actions. Read the matching section in [commands.md](references/commands.md).
3. Run the requested command and inspect the resulting `status`, `list`, or snapshot listing. A start request can be asynchronous; verify the observed state before retrying.

`delete` permanently removes a VM without an in-app confirmation. `snapshot restore` replaces current VM state, `snapshot overwrite` replaces saved state, and `discard-state` discards a resume state. Verify the exact target and effect; follow the active approval policy. For shutdown, `stop --request` asks the guest to shut down cleanly; the default `stop` is a force power-off, and `--kill` is a last resort.

`utmctl exec` requires `--cmd` in UTM 5.0.8. Do not substitute the older `-- <command>` examples found in some third-party skills. The QEMU guest agent is required for `exec` and `file`. UTM 5 can query IP addresses of Apple-backend VMs. On macOS 26, Apple-backend snapshots and USB passthrough are unavailable; those features require macOS 27. First-boot macOS guest provisioning also requires macOS 27 on both host and guest.

If `utmctl` exits 134 without output from a restricted command runner, check whether the same read-only command works with the runner's approved unsandboxed execution. Do not infer that UTM itself is broken from the restricted-runner result. This environment produced exit 134 in the sandbox, while approved `version` and `help` succeeded outside it.

UTM's CLI does not create VMs or edit their configuration. Use the UTM UI or its [AppleScript scripting interface](https://docs.getutm.app/scripting/scripting/) when the user's task needs those capabilities.
