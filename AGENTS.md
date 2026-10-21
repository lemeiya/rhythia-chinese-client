# AGENTS.md

## Scope

These instructions apply to the entire repository. Keep changes focused on the requested behavior and preserve the existing Godot/GDScript style in the files you touch.

The public open-source distribution is client-only. The local `server/` directory is a private deployment workspace and must not be included in public commits, release archives, or client source distributions.

## Project Overview

Sound Space Plus (shown in-app as Rhythia) is a Godot 4.3 rhythm game written primarily in GDScript.

- Main project file: `project.godot`
- Main scene: `res://scenes/init.tscn`
- Gameplay scene: `res://scenes/song.tscn`
- Current menu scene: `res://scenes/menu/menu2.tscn`
- Windows export presets: `Windows x86_64` and `Windows ARM64`
- Autoloads: `Globals`, `Online`, `Rhythia`, `RQueue`, `Dance`, `SFXManager`, and `Discord`

The repository contains legacy code and compatibility layers carried forward from older Godot versions. Do not perform broad modernization or formatting while implementing an unrelated fix.

## Repository Map

- `scripts/game/`: gameplay, note spawning, scoring, HUD, camera, cursor, and modifiers
- `scripts/content/`: song, replay, registry, audio, image, and custom-content loading
- `scripts/ui/`: menu, settings, content manager, prompts, and avatar editor logic
- `scripts/loaders/`: transitions into the menu, gameplay, and content manager
- `scripts/compat/`: Godot 3-style `File` and `Directory` wrappers used throughout the project
- `scripts/cursordance/`: cursor movement modes
- `scenes/`: main scenes, menus, loaders, errors, and test scenes
- `prefabs/`: reusable scene components
- `assets/`: bundled songs, worlds, meshes, effects, images, fonts, shaders, and audio
- `localization/localization.csv`: source of truth for translated UI strings
- `addons/`: vendored Discord, OpenVR, and native-dialog integrations
- `.tools/`: repository-local Godot binaries and focused verification scenes/scripts
- `build/`, `dist/`, `.godot/`, `.import/`: generated output; do not edit or commit generated contents

## Development Setup

Use Godot `4.3.stable`. A matching Windows console executable is included at:

```powershell
.\.tools\godot\4.3\Godot_v4.3-stable_win64_console.exe
```

The README documents the external Discord Game SDK files required for a fresh checkout. Do not replace or upgrade vendored addons unless the task explicitly requires it.

This project uses a custom `user://` directory named `SoundSpacePlus`. Automated checks must not read from or write to a developer's real game profile. In restricted or automated environments, redirect Godot's data directories before running it:

```powershell
$env:APPDATA = "$PWD\.godot\agent-appdata"
$env:LOCALAPPDATA = "$PWD\.godot\agent-localappdata"
```

## Implementation Rules

- Follow the local GDScript style. Most project scripts use tabs, compact type annotations such as `value:Type`, and a mixture of typed and untyped legacy code.
- Prefer a minimal behavioral change over a repository-wide cleanup. Do not reformat whole `.gd` or `.tscn` files.
- Preserve public signals, `class_name` values, autoload names, input action names, node names, and serialized resource paths unless the requested change explicitly includes a migration.
- Treat node paths such as `$Spawn/Music` and `get_node("...")` as scene contracts. When changing a scene tree, search for every path reference first.
- Keep gameplay timing in milliseconds where the surrounding code does so. Be careful around approach rate, hit windows, replay data, song offsets, queue offsets, and speed multipliers.
- Keep file-format changes backward compatible. Song (`.sspm`), replay (`.sspre`), settings, cache, and PB data are user-owned persistent data.
- Reuse the existing `File` and `Directory` compatibility wrappers in code that already uses them. Do not partially migrate a subsystem to `FileAccess`/`DirAccess` without a specific reason and targeted tests.
- Use `Globals.p(...)` when the surrounding subsystem uses it for `user://` paths, especially for Android behavior.
- Do not introduce blocking work in `_process`, `_physics_process`, or note-spawn loops. Existing resource loading may yield a frame deliberately to keep the UI responsive.
- Network code must handle request failure and malformed remote data without corrupting an existing map/cache file.

## Scenes and Resources

- Prefer editing scenes and resources through Godot when a structural change is needed.
- If a text edit to `.tscn` or `.tres` is necessary, keep it small and preserve resource IDs, node ownership, connection records, and subresource references.
- Never hand-edit `.godot/`, `.import/`, or `*.import` metadata to fix an asset problem. Change the source asset/import settings and let Godot regenerate metadata.
- Do not modify files under `addons/` as part of application work unless the issue is proven to be in that integration.

## Localization

- User-facing strings should use Godot translation lookup (`tr(...)`) or translatable scene text where appropriate.
- Edit `localization/localization.csv`, not generated `*.translation` files. The latter are ignored and regenerated by Godot.
- Preserve formatting placeholders such as `%s`, `%d`, and `%.0f` exactly across translations.
- If adding a key, provide at least a valid English source value and keep the CSV column/row structure intact.
- `.tools/merge-zh-localization.ps1` is a one-purpose migration helper with fixed row-count assumptions; do not use it for routine localization edits.

## Validation

### Server Incremental Updates

- After every incremental update to `server/`, run the PHP database synchronization command before restarting the web service:

```powershell
Set-Location server
php scripts/init_db.php
```

- `scripts/init_db.php` must initialize missing schema objects and automatically apply pending PHP migrations from `server/src/SchemaManager.php`.
- Do not implement incremental schema updates by adding or executing `.sql` migration files; use PHP/PDO schema methods instead.
- Database migrations must be repeat-safe: record each successfully applied migration in `schema_migrations`, never rerun a completed migration, and never drop or overwrite user data during deployment.
- If the PHP command fails, stop the deployment and report the database error; do not claim the server update is complete.

Run the smallest relevant checks first, then the project-level checks below.

Parse/import the project without opening the editor UI:

```powershell
& .\.tools\godot\4.3\Godot_v4.3-stable_win64_console.exe --headless --path . --editor --quit
```

Run the current runtime smoke test:

```powershell
& .\.tools\godot\4.3\Godot_v4.3-stable_win64_console.exe --headless --path . .tools\verify_runtime.tscn
```

The smoke test must print `VERIFY_RUNTIME_OK`. The current baseline may also emit root-certificate errors in sandboxed Windows environments and deprecation/rendering warnings from `scenes/Intro.tscn`; do not claim those warnings were introduced by a change unless the touched files caused them.

For SSPM loading/import changes, use a real fixture path outside the repository's generated directories:

```powershell
& .\.tools\godot\4.3\Godot_v4.3-stable_win64_console.exe --headless --path . .tools\test_sspm_import.tscn -- "C:\path\to\map.sspm" read
```

Additional manual/visual harnesses live in `.tools/visual_content_test.tscn`, `.tools/visual_game_test.tscn`, and `.tools/visual_language_test.tscn`. Use the one matching the changed area and inspect the result in a rendered window when visual behavior is involved.

For gameplay changes, manually verify at least:

- song load and start
- hit/miss scoring and combo behavior
- pause/give-up/end transitions
- replay behavior if timing or input changed
- queue continuation if song-ending logic changed

For UI changes, check both 1280x720 and a smaller window, plus keyboard/mouse and controller focus where applicable.

## Completion Checklist

- The project parses under the bundled Godot 4.3 executable.
- The runtime smoke test passes, or any environment-only limitation is reported precisely.
- Relevant focused or manual checks were performed.
- No real `SoundSpacePlus` user profile data was modified.
- Generated directories, exports, caches, and unrelated vendored files were left untouched.
- Any persistent-data or scene-contract migration is documented in the final handoff.
