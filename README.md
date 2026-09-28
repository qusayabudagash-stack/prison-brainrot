# prison-brainrot

A Roblox game, synced into Roblox Studio with [Rojo](https://rojo.space).

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), the toolchain manager.
2. From the repo root, install the pinned tools (Rojo, Selene, StyLua) from `rokit.toml`:

   ```sh
   rokit install
   ```

3. Install the Rojo plugin in Roblox Studio, either with `rojo plugin install` or by searching for Rojo in the
   Creator Store.

## Development

Start the Rojo server, then open a place in Studio and click **Connect** in the Rojo plugin:

```sh
rojo serve
```

Edits under `src/` now sync into Studio live.

To build a place file without Studio:

```sh
rojo build -o prison-brainrot.rbxl
```

## Project layout

`default.project.json` maps folders on disk to instances in the game:

| Folder        | Instance in Studio                                | Runs on           |
| ------------- | ------------------------------------------------- | ----------------- |
| `src/shared`  | `ReplicatedStorage.Shared`                        | Server and client |
| `src/server`  | `ServerScriptService.Server`                      | Server            |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`       | Client            |

File names decide what each file becomes:

- `*.server.luau`: `Script`
- `*.client.luau`: `LocalScript`
- `*.luau`: `ModuleScript`
- `init.*.luau`: turns its folder into that script, with the folder's other files as its children

The project file also creates a baseplate and a spawn location in `Workspace`, so a built place is playable straight away.

## Linting and formatting

```sh
stylua src        # format
selene src        # lint
```

`.luaurc` puts every script in Luau strict type-checking mode.

## Editor

VS Code offers to install the recommended extensions (Rojo, Luau LSP, StyLua, Selene) from `.vscode/extensions.json`.
Luau LSP resolves instance paths like `ReplicatedStorage.Shared` from a sourcemap, which you can generate with:

```sh
rojo sourcemap default.project.json -o sourcemap.json
```
