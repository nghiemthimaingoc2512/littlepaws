# Little Paws — Sprint 1

## The feeling we are building

> "My pet" → "I want to meet more pets" → "Aww, they became friends."

Everything in Sprint 1 serves that sentence. Anything that does not is cut.

## The one loop

```
Home → interact with my pet → one mini-game → a treat
     → the park → meet a pet → introduce them → friends ♥ → a memory → home
```

The player can finish this in a couple of minutes and then do it again. There
are four pets at the park, so there are four runs of the loop before the
collection is full.

## What we deliberately did not build

Pet-to-human matching, adoption, NPC simulation, currencies, an economy,
hunger/energy/hygiene stats, friendship levels, events, seasons, a world map,
quests, badges, a shop, an inventory, customisation, accounts, monetisation.

Some of these existed before this sprint and were removed. They were the reason
the game read as a management dashboard rather than something cozy. If they come
back, they come back one at a time, after this loop is genuinely fun.

## Rules

**Nothing can be lost.** No fail state, no timers that punish, no decay. The
mini-game's forty seconds end a round; they do not end anything else.

**One primary action per screen.** Home has three, and that is the most anywhere
gets. The park has exactly one: *Introduce them*.

**Friendship is a state, not a number.** Strangers → friends. The reward is a
sentence and two faces with a heart between them, not a meter.

**Rewards are objects, not currency.** A round of play leaves a treat waiting at
home. You give it to her and it is gone. Nothing accumulates.

## Visual direction

Warm and clean rather than sugary. Deep cocoa (`#4a3728`) does the text *and*
the outline on every raised thing, which is what makes the pets sit on top of
the painted backgrounds instead of floating over them. Honey (`#f0b75e`) is the
only call-to-action colour, so the primary action is never ambiguous. Sage and
clay appear once or twice each. No sparkles, no gradients, no pink fields.

Baloo 2 for anything that speaks, Nunito for anything that explains. Both are
inlined as woff2, so the game renders identically offline.

The stage is a fixed 1280×720 scaled to fit: the composition is the same on
every screen and nothing ever needs scrolling.

## Where Sprint 2 could go

In rough order of how much they would add for how little they would cost:

1. A second thing to do with a friend pet once you have met them.
2. A second location, reusing the park's screen wholesale.
3. Pet poses beyond the portrait — the art currently gives one image per pet.
4. Naming the pets you meet.

None of it should start before this loop is one people want to repeat.
