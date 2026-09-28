# 🧠 Prison Brainrot

**Roll for Brainrots, make money, and unlock the prison!**

A colorful, goofy Roblox collection game. You're a prisoner in a ridiculous Brainrot prison: roll machines
for silly Brainrot characters, they earn you coins every second, and coins buy better rolls, upgrades
and new prison blocks. Everything (map, characters, UI, effects) is built from plain parts and code, so
there are no assets to upload. The project is synced into Roblox Studio with [Rojo](https://rojo.space).

## What's in the game

- **Brainrot rolling** at a big machine in each of the 6 prison blocks, paid only with earned coins
  (no Robux, no real-money gambling). The roll animation cycles 3D Brainrots, slows down and reveals the
  result with effects that get bigger with rarity. Mythic finds and above are announced to the server;
  the Secret Brainrot flashes a rainbow across everyone's screen.
- **32 original Brainrots** across 8 rarities (Common → Uncommon → Rare → Epic → Legendary → Mythic →
  Divine → Secret), each built from parts with its own face, hat and extras.
- **Luck** (upgrades, rebirths, achievements, Golden/Diamond discoveries, a free timed boost, events),
  capped so rare stays rare. **Pity** ("LUCKY ROLLS"): 2x Legendary+ after 50 rolls, 4x after 100,
  guaranteed at 150.
- **Golden (2x) and Diamond (5x) variants**, rolled randomly or made by combining 3 duplicates.
- **Income**: your best Brainrots, up to your capacity, earn coins every second.
- **Brainrot Book** with completion per rarity, owned counts and combine buttons.
- **Shop**: upgrades (income, luck, roll discount, capacity, speed), block unlocks and cell cosmetics.
- **Player cells** showing your name, your best 3 Brainrots and any decorations you bought.
- **Rebirth** for permanent luck, **daily free roll**, **free luck boost**, **achievements**.
- **Random server events**: Double Income, Lucky Hour, Crazy Rolls, the Prison King (free 3x lucky roll)
  and Escaped Brainrots (catch giant Brainrots for coins).
- **Leaderboards**: leaderstats plus four physical boards (rebirths, Brainrots found, total coins, luck).
- **Saving** with DataStores: session locking, retries, autosave and safe shutdown. The server controls
  every roll, coin and purchase; clients only send requests, which are validated and rate limited.
- A skippable **tutorial**, sound effects, and a HUD that scales down for phones.

## Get it running in Roblox Studio

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then install the tools from the repo root:

   ```sh
   rokit install
   ```

2. Install the Rojo plugin in Studio: `rojo plugin install` (or search for Rojo in the Creator Store).
3. Start syncing:

   ```sh
   rojo serve
   ```

4. In Studio, create a new **Baseplate** place (or open your existing one), then click **Connect** in
   the Rojo plugin.
5. Press **Play**. The prison, UI and characters build themselves when the game starts, so in edit mode
   you'll only see the grass and the spawn pad.

To make a place file without live sync instead: `rojo build -o prison-brainrot.rbxl`, then open it in Studio.

### Steps only you can do in Studio

These need your Roblox account, so they can't be done from code:

1. **Publish the place** (File > Publish to Roblox). DataStores (saving and global leaderboards) only
   work in a published game.
2. **Enable saving while testing in Studio**: Game Settings > Security > turn on **Enable Studio Access
   to API Services**. Without it the game still runs in Studio on temporary data and prints a warning
   that progress won't be saved. Live servers always save.
3. **Set the server size to 10** (Game Settings > Places or the place's settings on the Creator
   Dashboard). There are 10 player cells; extra players can still play but won't get a cell.
4. **Optional: your own sounds.** The game uses sounds built into every Roblox client, pitched per
   rarity. To use uploaded sounds, paste their asset ids into `src/shared/Modules/SoundData.luau`.

## How to play

- **Roll**: the big red 🎰 ROLL button (◀ ▶ picks the block), the **R** key, or **E** at any roll machine.
- **Stations** around Cell Block 1: 🛒 Shop, ⬆️ Upgrades, 🧠 Brainrot Book, 🔄 Rebirth, 🍀 Free Luck and
  🎁 Daily Roll.
- **Unlock blocks** at their gates or in the Shop. Each block's machine has better odds.

In Studio, these chat commands help with testing (they never load in a live game): `/coins 1000000`,
`/event LuckyHour`, `/give PrisonKing Golden`, `/pity 149` and `/resetdaily`.

## Project layout

`default.project.json` maps the folders below into the game:

```
src/shared/Modules     -> ReplicatedStorage.Modules       shared data and logic
  GameConfig             every tuning number (luck cap, pity, events, rebirth, saving...)
  BrainrotData           rarities, base odds and all 32 Brainrots
  AreaData               prison blocks: unlock cost, roll cost, luck, minimum rarity
  UpgradeData            upgrades and their costs
  CosmeticData           cell decorations
  AchievementData        achievements and their luck rewards
  SoundData              sound ids
  RollSystem             odds, luck, pity and rolling math
  Formulas               income, capacity, luck and costs
  BrainrotModel          builds a Brainrot out of parts
  Events, Format, Net, Signal, Types
src/server             -> ServerScriptService
  Main.server.luau       starts every service
  Services/              DataService, RollService, EconomyService, UpgradeService, RebirthService,
                         EventService, LeaderboardService, MapService, CellService, ShopService, ...
  ServerModules/         part-building helpers, request guard, rate limiter
src/client             -> StarterPlayer.StarterPlayerScripts.Client
  UI/                    MainUI (HUD), RollUI, CollectionUI, ShopUI, RebirthUI, TutorialUI, AnnouncementUI
  Controllers/           player state, remote calls, sounds, prompts, gates
tests/                 Lune tests that run the real scripts outside Studio (not part of the game)
```

The UI is built in code, so the ScreenGuis appear in each player's PlayerGui (not StarterGui) at runtime.
The map is built by `MapService` into `Workspace.Lobby`, `Prison`, `CellBlocks`, `RollMachines` and
`Leaderboards`.

## Tuning

- **Odds**: `chance` on each rarity in `BrainrotData` (percentages adding up to 100), and `luckPower`
  (how much luck boosts it).
- **Prices and pacing**: `AreaData`, `UpgradeData`, `CosmeticData`, and `REBIRTH` in `GameConfig`.
- **Events, pity, free boost, daily roll, luck cap**: `GameConfig`.

With the current numbers, a player who keeps rolling reaches Cell Block 2 in about a minute, Death Row in
10 to 20 minutes, the Alien Block in under an hour and the Secret Block after 2 to 3 hours. Check pacing
after changing numbers with `lune run tests/balance.luau build/test.rbxl`.

## Linting, formatting and tests

```sh
stylua src tests        # format
selene src              # lint
tests/run-all.sh        # build the place and run every test
```

The tests use [Lune](https://lune-org.github.io/docs) to load the built place and run the real server and
client scripts with a small stand-in for the engine (`tests/engine.luau`). They play through rolling,
pity, odds (a million simulated rolls), combining, upgrades, blocks, cosmetics, events, rebirth, the whole
UI, saving and reloading, session locking and DataStore outages.

`.luaurc` puts every script in Luau strict type-checking mode. VS Code offers the recommended extensions
(Rojo, Luau LSP, StyLua, Selene) from `.vscode/extensions.json`. Luau LSP resolves paths like
`ReplicatedStorage.Modules` from a sourcemap: `rojo sourcemap default.project.json -o sourcemap.json`.

Rojo only syncs one way, from files into Studio. Edit scripts in your code editor, not in Studio's script
editor, because Rojo overwrites Studio-side edits to the scripts it manages.
