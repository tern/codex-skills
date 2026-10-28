# `utmctl` 5.0.8 commands

The examples use `utmctl` for readability. Here its executable is `/Applications/UTM.app/Contents/MacOS/utmctl`. Obtain exact flags with `utmctl help <command>` or `utmctl help <group> <command>`. `-d/--debug` and `--hide` are common options; `--hide` closes the main UTM window. Commands target a complete VM name or UUID, written below as `<vm>`.

| Command | Purpose and key syntax |
| --- | --- |
| `version` | Print UTM version. |
| `list` | Print registered VM UUID, status, and name. |
| `status <vm>` | Print one VM's status. |
| `start <vm>` | Start or resume. `--disposable` discards disk changes; `--recovery` boots recovery. `--attach` currently only prints a not-implemented warning. |
| `suspend <vm> [--save-state]` | Pause, optionally saving resume state to disk. |
| `stop <vm> [--request\|--force\|--kill]` | Request guest shutdown, force power off (default), or kill the VM process. |
| `clone <vm> [--name <new-name>]` | Clone an existing VM. Check disk space and give the clone a unique name. |
| `delete <vm>` | Permanently delete a VM; no built-in confirmation. |
| `discard-state <vm>` | Remove the VM's saved resume state. |
| `attach <vm> [--index <n>]` | Print a serial PTTY or TCP endpoint; terminal connection is not yet implemented. |
| `file pull <vm> <guest-path>` | Write guest file bytes to host stdout. Requires QEMU guest agent. |
| `file push <vm> <guest-path>` | Read host stdin and write to guest path. Requires QEMU guest agent. |
| `exec <vm> --cmd <program> [args...]` | Run a guest program via QEMU guest agent. `--input` forwards stdin; repeat `--env NAME=VALUE` for environment variables. |
| `ip-address <vm>` | Print guest IPs, IPv4 first. UTM 5 also supports Apple-backend VM IP queries. |
| `usb list` | List USB devices and their `VID:PID` or location identifiers. |
| `usb connect <vm> <device>` | Connect USB device to VM. Apple-backend USB requires macOS 27. |
| `usb disconnect <device>` | Disconnect device; no VM identifier argument. |

## Snapshots

| Command | Effect |
| --- | --- |
| `snapshot list <vm> [--json]` | List snapshots, newest first. `--scan` additionally scans disk images and may update snapshot records. |
| `snapshot create <vm> [--name <name>]` | Save current state as a new snapshot. |
| `snapshot restore <vm> --snapshot <name-or-id>` | Replace current state with a snapshot. |
| `snapshot overwrite <vm> --snapshot <name-or-id>` | Replace saved snapshot contents with current state. |
| `snapshot rename <vm> --snapshot <name-or-id> --to <new-name>` | Rename a snapshot. |
| `snapshot delete <vm> --snapshot <name-or-id>` | Delete a snapshot. |
| `snapshot scan <vm>` | Scan disk images for externally made or missing snapshots and update records. |

Snapshots work with QEMU VMs on macOS. Apple-backend snapshot support requires macOS 27, and those VMs must be stopped or suspended for create, restore, or overwrite. Snapshots are unavailable in disposable mode and do not include removable or external drives. See [UTM 5 release notes](https://docs.getutm.app/updates/v5.0/) and the [snapshot guide](https://docs.getutm.app/advanced/snapshots/).

## Examples

```sh
utmctl list
utmctl status "Ubuntu"
utmctl start "Ubuntu"
utmctl stop "Ubuntu" --request
utmctl exec "Ubuntu" --cmd /usr/bin/uname -a
utmctl file pull "Ubuntu" /var/log/syslog > ./syslog.txt
utmctl file push "Ubuntu" /tmp/setup.sh < ./setup.sh
utmctl snapshot create "Ubuntu" --name "Before update"
utmctl snapshot list "Ubuntu" --json
```

The `exec` target is a program, not an implicit shell. Invoke a guest shell explicitly when shell syntax is needed, and review its quoting. Read the guest-agent setup in the [official scripting guide](https://docs.getutm.app/scripting/scripting/) and check the VM's backend before attempting guest-agent commands.

UTM 5.0.8 exposes optional macOS guest provisioning on `start`: `--provision-username`, `--provision-full-name`, `--provision-password-stdin`, `--provision-auto-login`, and `--provision-ssh`. It works only at first boot after installation with macOS 27 or later on host and guest. Prefer the stdin password option; do not put a password in the command line. See the [official example](https://docs.getutm.app/scripting/scripting/#macos-27-setting-up-a-macos-guest).
