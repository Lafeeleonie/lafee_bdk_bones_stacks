# lafee bdk bones stacks

Local Retail 12.1 prototype for text-only aura application counters.

## Security model

Each tracker owns an `AuraContainer` and a single `AuraButton` slot. It uses a candidate filter containing only the configured aura IDs and binds a child `FontString` with `AuraButton:SetApplicationCount(fontString, { formatter = C_StringUtil.CreateAbbreviatedNumberFormatter() })`.

The addon never reads aura application counts. Blizzard writes and clears the FontString itself. No icon, cooldown, border, or glow is created.

`HideWhenMissing` is fail-closed: Blizzard clears the bound text when the aura is absent. Showing a synthetic `0` is deliberately not supported because absence is not read by addon Lua.

## Test checklist

1. Bone Shield absent: no residual number.
2. Bone Shield with one, multiple, decreasing, and increasing stacks.
3. Aura expiration and reapplication.
4. Combat, dungeon, Mythic+, specialization change, and `/reload`.
5. Cursor mode and changed UI scale.
6. Frame anchor missing, then late-loaded.
7. Preview open/close and multiple cursor trackers.
