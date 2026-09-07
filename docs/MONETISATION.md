# Monetisation

Little Paws is designed to earn from rewarded video and cosmetics, and never
from blocking progress. Every chapter, animal, badge and story is reachable
without spending or watching anything.

## Rewarded video (IAA)

Today the game shows a five-second stand-in. There is exactly one place to
replace:

```gdscript
# scenes/Main.gd
func show_rewarded_video(on_reward: Callable) -> void:
```

Swap the body for your SDK's show call and invoke `on_reward` from the SDK's
**reward** callback — not from its close callback, so a skipped ad pays nothing.
The reward itself is already handled:

```gdscript
GameState.grant_ad_reward()                 # +60 coins, records the view
GameState.grant_ad_reward(120, 2)           # a bigger custom reward
```

Availability rules live in `GameState` and are already enforced by the UI:

| Constant | Value | Meaning |
| --- | --- | --- |
| `AD_REWARD_COINS` | 60 | coins per completed view |
| `AD_COOLDOWN_SEC` | 90 | wait between views |
| `AD_DAILY_LIMIT` | 12 | views per calendar day |

`GameState.ad_available()`, `ad_wait_seconds()` and `ads_left_today()` drive the
button label and disabled state in the top bar and the shop.

### Suggested placements

- **Free coins** in the top bar — always visible, never interrupting.
- **Shop** — offered exactly when the player is short of coins.
- **Double a chapter reward** — offer once, on the celebration popup, never
  auto-playing.

Do not put an interstitial between care actions or at app launch. The whole
promise of this game is that it is a calm place.

For Godot 4, [Poing Studios' AdMob plugin](https://github.com/Poing-Studios/godot-admob-plugin)
covers Android and iOS. Add it as an addon, initialise it once in
`Main._ready()`, and keep everything else as-is.

## In-app purchases

Not wired up. The natural products, in order of how well they fit the game:

1. **Remove ads** — one purchase, keeps the free-coins button paying out.
2. **Gem packs** — gems already buy the premium cosmetic in each category. The
   `+` on each currency bar is the natural entry point: coins open a rewarded
   video, gems open the shop, hearts explain where hearts come from.
3. **Cosmetic bundles** — seasonal outfit + accessory + decor sets. Adding one
   is a `data/items.json` edit, no code.

Never sell care actions, trust, or a faster path through a chapter. Selling
impatience would undo the reason someone opened this game.

## Analytics worth having

`GameState.counter()` already tracks `care_total`, `coins_earned` and `ads`.
The events worth sending: onboarding species chosen, chapter completed, rescue
completed, animal homed, rewarded video completed, day-N retention. Together
they tell you whether the care loop or the collection loop is holding people.
