# 🧠 Prison Brainrot

**Roll for Brainrots, make money, and unlock the prison!**

A colorful, goofy Roblox collection game. You're a prisoner in a ridiculous Brainrot prison: roll machines
for silly Brainrot characters, they earn you coins every second, and coins buy better rolls, upgrades
and new prison blocks. Everything (map, characters, UI, effects) is built from plain parts and code, so
there are no assets to upload. The project is synced into Roblox Studio with [Rojo](https://rojo.space).

## What's in the game

- **Brainrot rolling** at a Brainrot Roller machine in each of the 6 prison blocks, paid only with earned
  coins (no Robux, no real-money gambling). Rolling is a case-opening reel of Brainrot cards that slows
  onto your result (rare results stay hidden until they land), then a 3D reveal card with effects that
  get bigger with rarity. The machine itself pulls its lever, goes rainbow and flashes the rarity color
  for everyone nearby. Mythic finds and above are announced to the server; the Secret Brainrot flashes a
  rainbow across everyone's screen.
- **32 Italian Brainrot characters** across 8 rarities (Common → Uncommon → Rare → Epic → Legendary →
  Mythic → Divine → Secret): Tim Cheese, Lirilì Larilà, Boneca Ambalabu, Brr Brr Patapim, Chimpanzini
  Bananini, Cappuccino Assassino, Ballerina Cappuccina, Tung Tung Tung Sahur, Bombardiro Crocodilo,
  Tralalero Tralala, La Vaca Saturno Saturnita and more. They are original 3D interpretations of the meme
  characters, sculpted from smooth lofted shapes (no ripped assets), with idle animation. Rarity shows in
  the model itself: rarer Brainrots are bigger, more detailed and use richer materials, with only light
  sparkles and auras on top.
- **Luck** (upgrades, rebirths, achievements, Golden/Diamond discoveries, a free timed boost, events),
  capped so rare stays rare. **Pity** ("LUCKY ROLLS"): 2x Legendary+ after 50 rolls, 4x after 100,
  guaranteed at 150.
- **Golden (2x) and Diamond (5x) variants**, rolled randomly or made by combining 3 duplicates.
- **Income**: your best Brainrots, up to your capacity, earn coins every second.
- **Brainrot Book** with completion per rarity, owned counts and combine buttons.
- **Shop**: upgrades (income, luck, roll discount, capacity, speed), block unlocks and cell cosmetics.
- **Player cells**: furnished cells (bunk, steel toilet, locker, window) in a two-tier cell block,
  showing your name, your best 3 Brainrots and your decorations. Some decorations upgrade the furniture
  (the Comfy Bed replaces the bunk, the Golden Toilet replaces the steel one).
- **Rebirth** for permanent luck, **daily free roll**, **free luck boost**, **achievements**.
- **Random server events**: Double Income, Lucky Hour, Crazy Rolls, the Prison King (free 3x lucky roll)
  and Escaped Brainrots (catch giant Brainrots for coins).
- **Leaderboards**: leaderstats plus four physical boards (rebirths, Brainrots found, total coins, luck).
- **Saving** with DataStores: session locking, retries, autosave and safe shutdown. The server controls
  every roll, coin and purchase; clients only send requests, which are validated and rate limited.
- A skippable **tutorial**, sound effects, and a HUD that scales down for phones.

## The prison

- **Main hall (Cell Block 1)**: the intake with the front doors, benches, vending machines, the
  founder's golden statue and the leaderboards; a security checkpoint with metal detectors, an X-ray belt
  and the guard desk under the big title sign; the first roll machine on a stage under a skylight.
- **Stations** are real objects: the commissary window (Shop), the workshop bench (Upgrades), the
  Brainrot Book on its lectern, the parole board door (Rebirth), the Luck-O-Mat (free luck) and the
  mailroom care package (daily roll).
- **Cell Block A**: the player cells in two rows with catwalks and an upper tier.
- **Mess hall**: serving line, kitchen, tables with trays, a menu nobody trusts.
- **The yard**: basketball court, outdoor gym, potato garden, watch towers. The Prison King event holds
  court here and escaped Brainrots roam the lawn.
- **The blocks** you unlock each have their own look: Cell Block 2 (blue, two-tier cells), Maximum
  Security (plating, solitary, a caged machine, alarms), Death Row (flickering lights, the Electric
  Throne), the Alien Block (crashed UFO, specimen tanks) and the Secret Block (starfield floor, portal).
- **Lighting** uses Future lighting with atmosphere, bloom and color correction; the mood blends as you
  walk from room to room.

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
4. **Turn on Future lighting** if you use live sync: in the Explorer select Lighting and set
   **Technology** to **Future**. Rojo sets every other lighting property for you, but its live sync
   can't change this one (a `rojo build` place file already has it).
5. **Optional: your own sounds.** The game uses sounds built into every Roblox client, pitched per
   rarity. To use uploaded sounds, paste their asset ids into `src/shared/Modules/SoundData.luau`.

## How to play

- **Roll**: the big red 🎰 ROLL button (◀ ▶ picks the block), the **R** key, or **E** at any roll machine.
- **Stations** around the main hall: 🛒 the commissary, ⬆️ the workshop, 🧠 the Brainrot Book, 🔄 the
  parole board, 🍀 the Luck-O-Mat and 🎁 the mailroom. The HUD tiles open the same screens from anywhere.
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
  BrainrotModel          builds a Brainrot from its design, adds rarity and variant effects
  Brainrots/             the character designs: Kit (shapes, smooth lofts, faces, teeth), Parts
                         (sneakers, tubes, fins, cups, rings, props), one module per rarity, and
                         Effects (light rarity FX)
  MapLayout              where every room is, and the lighting mood of each zone
  Events, Format, Net, Signal, Types
src/server             -> ServerScriptService
  Main.server.luau       starts every service
  Services/              DataService, RollService, EconomyService, UpgradeService, RebirthService,
                         EventService, LeaderboardService, MapService, CellService, ShopService, ...
  ServerModules/         part-building helpers, request guard, rate limiter, cell cosmetics
    Map/                 the prison: Palette, Shapes, Structure, Props (set dressing), Themes
                         (per-block colors), RollMachine, Stations, Hall, CellWing, MessHall, Yard,
                         Blocks, Boards
src/client             -> StarterPlayer.StarterPlayerScripts.Client
  UI/                    MainUI (HUD), RollUI, CollectionUI, ShopUI, RebirthUI, TutorialUI, AnnouncementUI
  Controllers/           player state, remote calls, sounds, prompts, gates, Animator (Brainrot idle
                         animation), Machines (machine lights and world props), Ambience (lighting)
tests/                 Lune tests that run the real scripts outside Studio (not part of the game)
```

The UI is built in code, so the ScreenGuis appear in each player's PlayerGui (not StarterGui) at runtime.
The map is built by `MapService` into `Workspace.Lobby`, `Prison`, `CellBlocks`, `RollMachines` and
`Leaderboards`.

## Changing the look

- **A block's colors and machine paint**: `ServerModules/Map/Themes.luau`. The shared palette is
  `Map/Palette.luau`; environments stay neutral so interactables, rewards and signs stand out.
- **Lighting per room**: `Moods` in `Modules/MapLayout.luau` (the base effects are in
  `default.project.json` under Lighting).
- **A Brainrot's design**: its function in `Modules/Brainrots/<Rarity>.luau`. Designs face -Z with
  their feet on y = 0 and tag parts with a rig group (Body, ArmL/ArmR, WingL/WingR, Orbit, Legs) so the
  client animates them. `Kit.loft` builds smooth tapered bodies, tails and fins from a list of sections.
  Brainrot ids that were renamed are listed in `BrainrotData.LegacyIds`, and old saves are migrated on
  load.
- **Swapping in a real 3D model**: put a Model named after the Brainrot's id (e.g. `TralaleroTralala`)
  in a Folder called `BrainrotAssets` in ReplicatedStorage. It replaces the built-in design everywhere
  (cells, machines, roll cards); face it towards -Z and name its main part `Body`. Only use models you
  made or have the rights to use (for example Creator Store assets whose license allows it).

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
