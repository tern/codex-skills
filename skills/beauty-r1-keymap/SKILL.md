---
name: beauty-r1-keymap
description: Reconfigure a Beauty-R1 (DY10) Bluetooth remote on macOS with Karabiner-Elements. Use for Beauty-R1 button mapping, Ghostty or Codex CLI controls, and diagnosing which HID events its buttons send.
---

# Beauty-R1 keymap

Use [the verified Ghostty rule](assets/ghostty-codex.json) as a starting point. Treat its device identifiers and button events as observations from one Beauty-R1 on one Mac; recheck them when the remote, firmware, or Mac changes.

## Verified event map

| Physical action | EventViewer input | Current Ghostty output |
| --- | --- | --- |
| Long press up | `consumer_key_code: volume_increment` | `up_arrow` |
| Long press down | `consumer_key_code: volume_decrement` | `down_arrow` |
| Short press up, down, left, right, or center heart | `pointing_button: button1` | `return_or_enter` |

The five short presses are indistinguishable to Karabiner. Do not promise a separate mapping for one of them based on button identity alone. Long presses of up and down can repeat, so they may move several choices.

The observed device has vendor ID `1452`, product ID `556`, and `is_pointing_device: true`. Ghostty's bundle identifier is `com.mitchellh.ghostty`.

## Change or restore a mapping

1. Read the current `~/.config/karabiner/karabiner.json` and back it up. Identify the selected profile and any existing Beauty-R1 rule. Preserve every unrelated setting and rule.
2. Use Karabiner-EventViewer to capture each requested physical action separately. Record the exact input event and whether it differs from other buttons. For a new device, verify its identifiers in EventViewer's Devices page.
3. Edit the named Beauty-R1 rule in the selected profile. Keep `device_if` scoped to the observed remote and `frontmost_application_if` scoped to the requested app. Set the remote's **Modify events** device option on; in `karabiner.json`, its device entry has `ignore: false`.
4. Validate a standalone rule file with `karabiner_cli --lint-complex-modifications <rule.json>`. Apply the change and confirm Karabiner reloads the configuration without errors.
5. Test in a disposable Ghostty tab running `/bin/cat -v`, so an Enter mapping cannot confirm a live Codex CLI prompt. Up and down appear as `^[[A` and `^[[B`. To test Enter, type `TEST` without pressing Return, then press the mapped remote button; `TEST` should be echoed on a new line. Exit with Control-C.

If a button does not generate a distinct event, explain the hardware limitation and test another physical action or input mode before changing the rule. If the user wants the original behavior back, restore the saved configuration or remove only the Beauty-R1 rule and its device override.
