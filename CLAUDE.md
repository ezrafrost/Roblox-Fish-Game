# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Roblox fishing/aquarium-tycoon game (repo/Rojo project name "Roblox fish game"; internal Wally
package `ezrafrost/aquarium-tycoon`). Built with [Rojo](https://rojo.space) 7.7.0, which syncs the
`src/` tree into the Roblox DataModel and back into Studio. Tools are pinned via Aftman
(`aftman.toml`): `rojo` 7.7.0 and `wally` 0.3.2.

Development comments throughout the code reference an external design doc by phase/section/step
("the doc", "§12", "Phase 6", "Step 4.3") — that doc is **not in this repo**. `Debug*` remotes and
functions marked `TEMP` are scaffolding to be removed in the "Phase 6 lockdown" before publish.

## Commands

```bash
aftman install                              # install pinned rojo + wally
wally install                               # fetch ProfileStore into ServerPackages/ (git-ignored, required for a server build)
rojo build -o "Roblox fish game.rbxlx"      # build the place file from source
rojo serve                                  # live-sync server; connect from the Rojo Studio plugin
rojo sourcemap -o sourcemap.json            # regenerate sourcemap for LSP / type-checking
```

There is no lint, format, or test tooling (no selene/stylua/test runner). Verification = Studio
Script Analysis + play-testing. On every server start, [src/server/init.server.luau](src/server/init.server.luau)
prints a 50k-sample rarity distribution for the Wooden and Golden rods — intentional tuning
instrumentation, not a test.

## DataModel mapping

[default.project.json](default.project.json) is the source of truth. Notable points:

- `ReplicatedStorage.Config` ← `src/shared/Config`, `ReplicatedStorage.Shared` ← `src/shared/Shared`
  (two separate `$path` mounts, both under `src/shared/`).
- `ReplicatedStorage.Remotes` is declared as an **empty Folder** and populated at runtime (see below).
- `ServerScriptService.Server` ← `src/server`; `ServerScriptService.ServerPackages` ← `ServerPackages/` (Wally output).
- `StarterPlayer.StarterPlayerScripts.Client` ← `src/client`.
- `Workspace.Plots` (Plot1–4) and `Workspace.Zones` (Pond, Lake, River, Ocean, AbyssalTrench) are
  declared here as `Part`s. The **plot pool** and **zone bounds** are both read from these instances
  at runtime — add/rename world objects here, not in code, so they survive a full `rojo build`.

Per Rojo convention, `init.server.luau` / `init.client.luau` make their folder a script instance;
sibling files become its children (e.g. `script.Services.DataService`, `script.Bootstrap.RemotesSetup`).

## Architecture

### Server: ordered service init

[src/server/init.server.luau](src/server/init.server.luau) `require`s each service and calls
`.Init()` in a **fixed order that matters**: `RemotesSetup` first (creates the remote instances every
other service `WaitForChild`s), then `DataService` (registers `PlayerAdded` before services that
iterate existing players / catch up profiles), then the rest.

Every service is a module returning a table with an `.Init()` function. Services depend on each other
by direct `require(script.Parent.OtherService)` — there is no DI container or service locator.

### Remotes

[src/shared/Shared/RemoteNames.luau](src/shared/Shared/RemoteNames.luau) is the single source of
truth for remote names — client and server never hardcode strings.
[RemotesSetup](src/server/Bootstrap/RemotesSetup.luau) creates one instance per name: a
`RemoteFunction` by default (most calls need a value back immediately), a `RemoteEvent` only for
names in its `EVENT_NAMES` set (currently just `RareCatchAnnouncement`). Each service binds its
`OnServerInvoke` handlers inside `.Init()`.

There is **no server→client push** except `RareCatchAnnouncement`. Clients poll `RemoteFunction`s on
`task.wait` intervals ([FishingUI](src/client/UI/FishingUI.client.luau) every 3s,
[FishRenderer](src/client/FishRenderer.client.luau) every 2s) to pick up server-side state changes
(e.g. `ProcessReceipt` grants) that have no client-side trigger.

### Data persistence

[DataService](src/server/Services/DataService.luau) wraps ProfileStore (`PlayerData_v1` store).
The live session object **never leaves the module** — `GetProfile` returns only `profile.Data`
(shape = [ProfileTemplate](src/shared/Config/ProfileTemplate.luau); `:Reconcile()` backfills new
fields). Other services mutate that `Data` table in place and the changes persist automatically on
save/session-end. `GetProfile` yields up to ~10s if called before the profile finishes loading.
`GetPlotDisplay` returns a deliberately narrowed view (tanks + placed fish only) for cross-player
rendering.

### Anti-exploit model (pervasive)

All randomness and all value math happen server-side, always. Clients send only IDs
(`fishId`, `tankId`, `rodId`, …) — never positions, values, or roll results. The server re-resolves
ownership, capacity, and inventory membership on every call, and derives the fishing zone from the
player's **own server-tracked character position** ([FishingService.OnCastLine](src/server/Services/FishingService.luau)),
not any client input. `EconomyService.OnSellFish` recomputes value from the stored fish record and
ignores anything the client sends.

### Config-driven tuning

`src/shared/Config/` holds all balance data as plain Luau tables: `FishConfig`, `RarityConfig`
(tier weights/multipliers/`LuckScale`), `ZoneConfig` (per-zone weight overrides, unlock cost,
species pools by rarity), `RodConfig`, `BaitConfig`, `MutationConfig`, `BoostConfig`,
`ProductConfig`, `TankConfig`. `src/shared/Shared/` holds the shared math that consumes them:
[OddsCalculator](src/shared/Shared/OddsCalculator.luau) (weight→odds, with a largest-remainder
rounding routine so disclosed percentages sum to exactly 100) and
[FishValue](src/shared/Shared/FishValue.luau) (`BaseValue × rarity × weight-variance × Πmutations ×
growth`). Both server rolls and client odds displays call the same functions so they can never
disagree.

### Key runtime loops

- **Fishing**: `CastLine` → cooldown + zone-unlock check → `FishingService.GenerateFish`
  (rarity → species → mutations → weight) → insert to `inventory`, fire `IndexService.RecordCatch`
  + `AnnounceService.MaybeAnnounce` (Legendary+ → `FireAllClients`).
- **Growth / passive income**: [GrowthService](src/server/Services/GrowthService.luau) sweeps all
  loaded profiles every 30s and catches up each profile on join; only tank-placed fish grow/earn;
  elapsed time is clamped (30 days) so a DataStore anomaly can't hand out a huge payout.
- **Monetization**: [MonetizationService](src/server/Services/MonetizationService.luau) sets
  `MarketplaceService.ProcessReceipt` — idempotent via `profile.purchaseHistory` (checked before
  granting, recorded only after the handler succeeds), pruned after 90 days. Product handlers are
  keyed by Dev Product ID from `ProductConfig`.
- **Policy**: [PolicyServiceWrapper](src/server/Services/PolicyServiceWrapper.luau) checks
  `PolicyService` once on join, caches, and **fails closed** (restricted) on any error.
  [TradeService](src/server/Services/TradeService.luau) is currently only this policy gate — real
  trading is deferred.

### Client

No client framework. Each `*.client.luau` under `src/client/` and `src/client/UI/` is an
independent LocalScript that builds its own `ScreenGui` imperatively and talks to remotes directly.
