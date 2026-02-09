# Ingredient Parser Improvements

Remaining unmatched: ~90k of 1.13M ingredients (92% match rate)

## Preprocessing Fixes

- [x] Unicode fraction slash (U+2044) → regular slash — recovered ~10k
- [x] Dual metric/imperial: `200ml/7fl oz double cream` → `double cream`
- [x] Parenthetical weights: `2 cups (10 ounces/283 grams) all-purpose flour` → `2 cups all-purpose flour`
- [x] Compact paren sizes: `(15oz)` → `(15-oz)` for container detection
- [x] Prep-word retry: `hot sauce` matched when "hot" labeled as prep word
- [x] Section headers / advertising: `FILLING`, `TO SERVE`, `SHOP JAMIE'S SERVEWARE`
- [x] "for serving" / "to serve" suffix: already handled by comma-separated note stripping
- [x] British `chilli` → `chili` normalization
- [x] `salt and pepper` combo → skipped (no quantity, seasoning instruction)
- [x] "heaped" measurement modifier: `1 heaped tablespoon` → `1 tablespoon`
- [x] `X x Yg sachet/tin/can of`: `1 x 400g tin of chopped tomatoes` → container detection
- [x] `Xcm piece of ginger`: `5cm piece of ginger` → `ginger` (added cm + thumb-sized to ginger normalizer)

## Equipment Detector

- [ ] Expand equipment list (thermometer, spice mill, mortar and pestle, etc.)

## Missing Canonicals

- [x] Hot sauce
- [ ] Mixed spice (British spice blend)
- [ ] Mixed-colour peppers

## Future / ML

- [ ] Embedding-based matcher for long-tail unmatched ingredients
