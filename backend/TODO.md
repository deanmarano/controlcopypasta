# Ingredient Parser Improvements

Remaining unmatched: ~90k of 1.13M ingredients (92% match rate)

## Preprocessing Fixes

- [x] Unicode fraction slash (U+2044) → regular slash — recovered ~10k
- [ ] Dual metric/imperial: `200ml/7fl oz double cream` → `double cream`
- [ ] Parenthetical weights: `2 cups (10 ounces/283 grams) all-purpose flour` → `2 cups all-purpose flour`
- [ ] Section headers / advertising: `FILLING`, `TO SERVE`, `SHOP JAMIE'S SERVEWARE`
- [ ] "for serving" / "to serve" suffix: `Hot sauce, for serving` → `Hot sauce`
- [ ] British `chilli` → `chili` normalization
- [ ] `salt and pepper` combo → split or handle as compound
- [ ] "heaped" measurement modifier: `1 heaped tablespoon` → `1 tablespoon`
- [ ] `Xcm piece of ginger`: `5cm piece of ginger` → `ginger`
- [ ] `X x Yg sachet/tin/can of`: `1 x 400g tin of chopped tomatoes` → `chopped tomatoes`

## Equipment Detector

- [ ] Expand equipment list (thermometer, spice mill, mortar and pestle, etc.)

## Missing Canonicals

- [x] Hot sauce
- [ ] Mixed spice (British spice blend)
- [ ] Mixed-colour peppers

## Future / ML

- [ ] Embedding-based matcher for long-tail unmatched ingredients
