# Beauty-R1 → Ghostty / Codex CLI

This Codex skill records a working macOS mapping for a Beauty-R1 (DY10) Bluetooth remote. It also describes how to measure the remote's events and change the mapping later.

## Working controls

| Remote action | Ghostty action |
| --- | --- |
| Long press up | Up arrow |
| Long press down | Down arrow |
| Short press center heart | Enter |

Karabiner-EventViewer showed that short presses of **up, down, left, right, and center heart all send the same `button1` event**. Therefore, all five short presses produce Enter while Ghostty is focused. They cannot be assigned five distinct actions through this rule. Long up/down send separate volume events and may repeat while held.

The rule applies only to a pointing device with vendor ID `1452` and product ID `556`, and only while Ghostty (`com.mitchellh.ghostty`) is frontmost. It does not contain the remote's serial number.

## Install or revise

1. Install Karabiner-Elements and grant the permissions required by its Setup page.
2. Connect Beauty-R1. In **Karabiner-Elements → Devices**, enable **Modify events** for this remote.
3. Copy [`assets/ghostty-codex.json`](assets/ghostty-codex.json) into `~/.config/karabiner/assets/complex_modifications/`. In **Complex Modifications → Add predefined rule**, enable its rule. Confirm the device identifiers with Karabiner-EventViewer before using the rule on another remote. On a Mac where this rule is already enabled, edit the existing rule instead of adding a duplicate.
4. Test in a new Ghostty tab with `/bin/cat -v`. The arrows should show `^[[A` and `^[[B`. Type `TEST`, then short press the center heart; Enter makes `TEST` appear again on a new line. Press Control-C to exit.

To change the target keys, edit the `to` entries in the JSON rule, lint it with `karabiner_cli --lint-complex-modifications`, then replace the enabled rule. The [skill instructions](SKILL.md) cover event capture, safe editing, and rollback.

The mapping was verified on macOS with Karabiner-Elements 16.3.0 and Ghostty. Other firmware or device revisions should be measured again before applying it.
