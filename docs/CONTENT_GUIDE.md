# CONTENT_GUIDE — writing chat lines

The feature lives or dies on tone. Lines must feel like a real NPC noticing a real
player: **rare and delightful, never spammy, never meta.** (Spec §9.)

## Rules

1. **Length ≤ ~110 characters.** One remark, not a speech. (Hard server ceiling is 255
   bytes; the emitter truncates on a UTF-8 boundary as a safety net.)
2. **WotLK-lore-friendly.** 3.3.5a setting only. No retail zones, no references to
   events that haven't happened, no anachronisms.
3. **Never meta.** The NPC does not know it's a game. No "player", "toon", "server",
   "buff", "epic loot", "ilvl", stats, or fourth-wall breaks. Say "fine armor", not
   "epic gear".
4. **Tone: friendly / neutral / cautious / impressed.** Never hostile, never servile.
   A city guard is watchful and a little gruff; that's the voice of the seed set.
5. **Placeholders are whitelist-only:** `{player}` `{class}` `{race}` `{weapon_type}`.
   Nothing else is substituted (unknown `{tokens}` are left verbatim). Values are
   inserted literally and are injection-safe — a name containing `%`, `{`, or pattern
   characters cannot break or inject (see `02_inc_util.ReplacePlaceholders`; there is a
   unit test for hostile names). **Never** interpolate any player-typed content beyond
   these server-derived values.
6. **Match, don't assume.** If a line names a `{weapon_type}`, gate it on
   `required_item_tags_lo = HAS_WEAPON (1)` so it only fires for an armed player. If it
   compliments fine gear, gate `min_item_quality`. A line that reads wrong out of
   context is a content bug.
7. **Whisper (`chat_mode = 1`) only for personal asides**, and only where the NPC
   profile has `allow_personal_lines = 1`. Keep whispers genuinely private in feel.
8. **Emote (`chat_mode = 2`)**: the `text` is the *action phrase* ("nods respectfully
   as you pass.") rendered as a text emote. (A purely numeric text is played as an
   animation id instead — ADR-006.)

## Categories → `cooldown_group`

Group lines so a category can't repeat too often (the group cooldown spans all lines
sharing a number):

| group | category | notes |
|---|---|---|
| 1 | greeting | generic hellos |
| 2 | equipment | require an item tag / quality |
| 3 | class | `class_mask` set |
| 4 | faction / place | `team_mask` or `location_mask` set |
| 5 | warning | cautious/procedural |
| 6 | gesture | whispers + emotes |

## Matching semantics (author's cheat-sheet)

- **0 = no restriction** on every mask field.
- `class_mask` / `race_mask` / `team_mask` / `location_mask` are **ANY-of**.
- `required_item_tags_*` are **ALL-of** (player must have every required tag).
- `min_item_quality` compares against the player's **highest** equipped quality.
- `npc_role_mask_*` are **ANY-of** against the speaking NPC's profile role.
- Bit values live in `sql/world/base/inc_base.sql` (mirrored from
  `scripts/inc/02_inc_util.lua` — the single source of truth).

## Extending

Add rows to `immersive_npc_chat_line`; run `python3 tools/check_sql.py <file>`; import;
`.inm reload` (no restart needed for new lines). Tune pacing live: author → `.inm
reload` → watch → adjust — the Lua advantage. The seed set is 36 lines (all GUARD role);
v2 grows the library to 200+ and adds more NPC roles.
