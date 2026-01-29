# Ingredient Parser Improvements

Based on analysis of 15,396 unique unmatched ingredients (18,847 total occurrences) from production data.

---

## High Priority (Parser Fixes)

### 1. Filter Non-Ingredients (~268) ✅ DONE

Kitchen equipment and tools are being included in ingredient lists.

- [x] **As a user, I want kitchen equipment filtered out of ingredients** so that my ingredient lists only contain actual food items.
  - Examples: "A deep-fry thermometer", "A spice mill or mortar and pestle", "A 9"-diameter springform pan"
  - Detection: starts with "A " or "An " followed by equipment words (thermometer, mill, pan, cutter, skewer, etc.)
  - **Implemented**: `is_equipment?/1` function in `token_parser.ex` preprocessing

### 2. Improve Butter Matching (~1,282) ✅ DONE

Butter with stick/tablespoon notation is not matching to "butter" canonical.

- [x] **As a user, I want butter with stick notation to match** so that "2 sticks (1 cup) salted butter" → butter.
  - Examples: "½ cup (1 stick) unsalted butter", "1 stick (8 tablespoons) salted butter, melted"
  - Pattern: `X stick(s)` or `(X stick)` in text containing "butter"
  - **Implemented**: `normalize_stick_butter/1` function extracts the measurement from parenthetical

### 3. Improve Ginger Matching (~608) ✅ DONE

Ginger with size notation (inch piece) is not matching.

- [x] **As a user, I want ginger with size notation to match** so that "1 inch piece ginger" → ginger.
  - Examples: "1 1" piece ginger, peeled", "1 2-inch piece ginger"
  - Pattern: `X inch/in/" piece ginger`
  - **Implemented**: `normalize_ginger_size/1` function normalizes to "X piece ginger"

### 4. Handle Slash Notation (~888) ✅ DONE

Ingredients with slash-separated measurements (cup/grams) aren't parsing correctly.

- [x] **As a user, I want slash notation measurements to parse** so that "1/2 cup/100 grams granulated sugar" extracts the ingredient.
  - Examples: "2 cups/256 grams all-purpose flour", "1 cup/200 grams granulated sugar"
  - Pattern: `X unit/Y grams ingredient` — strip the gram measurement
  - **Implemented**: `normalize_slash_measurements/1` function strips `/Y grams` suffix

### 5. Handle Gram Measurements (~1,051) ✅ DONE

Ingredients with inline gram weights aren't matching.

- [x] **As a user, I want gram measurements in parentheses to be stripped** so that "1 cup (200g) flour" → flour.
  - Examples: "1/2 cup (45g) rolled oats", "3/4 cup (150g) sugar"
  - Pattern: strip `(Xg)` or `X grams` from ingredient text before matching
  - **Implemented**: `normalize_gram_measurements/1` function strips `(Xg)` patterns

---

## Medium Priority (Missing Canonicals)

### 6. Add Alcoholic Beverages (~1,364)

Wines, spirits, and liqueurs used in cooking are missing from canonicals.

- [ ] **As a user, I want alcoholic ingredients to match** so that "2 oz bourbon" → bourbon.
  - Common: bourbon, rum, vodka, gin, wine (red/white), beer, vermouth, brandy, cognac
  - Specialty: Kahlúa, amaretto, Cointreau, Grand Marnier, Prosecco, Champagne, sake

### 7. Add Seasoning Blends (~103) ✅ DONE

Common seasoning blends are missing.

- [x] **As a user, I want seasoning blends to match** so that "1 tbsp creole seasoning" → creole seasoning.
  - Added: creole seasoning, cajun seasoning (alias), poultry seasoning, italian seasoning, taco seasoning, five-spice powder
  - **Implemented**: Migration adds canonical ingredients with aliases

### 8. Add Generic Ingredients (~400+) - Partially Done

Generic terms without specific variety aren't matching.

- [x] **Generic broth** (~111): "4 cups broth" (not chicken/beef/vegetable)
  - **Implemented**: Added "broth" canonical with "stock" alias
- [x] **Generic nuts** (~285): "1 cup chopped nuts" (not specific type)
  - **Implemented**: Added "nuts" canonical with "mixed nuts", "chopped nuts", "assorted nuts" aliases
- [ ] **Generic oats** (~73): "rolled oats, old-fashioned"
- [ ] **Generic cheese blends** (~67): "Mexican cheese blend", "shredded cheese"

### 9. Add Cloves (Spice) (~140) ✅ DONE

The spice "cloves" is being confused with garlic cloves.

- [x] **As a user, I want the spice cloves recognized** so that "1/4 teaspoon cloves" → cloves (spice).
  - **Implemented**: Added "cloves" canonical with "ground cloves", "whole cloves", "clove" aliases
  - Note: "4 cloves" alone remains ambiguous (could be garlic). Context like "1/4 tsp cloves" now matches correctly.

### 10. Add Chipotle in Adobo (~87)

A common ingredient with complex phrasing.

- [ ] **As a user, I want "chipotle in adobo" variations to match**.
  - Examples: "2 chipotle peppers from a can of chipotles in adobo", "chipotle in adobo sauce"

---

## Lower Priority (Edge Cases)

### 11. Handle Recipe References (~321)

Some ingredients reference other recipes or prepared components.

- [ ] **As a user, I want recipe references flagged** so that "Guacamole" or "all of the preferment" are marked appropriately.
  - Examples: "Guacamole", "Granola", "all of the preferment", "click for recipe", "homemade"
  - Detection: capitalized single word, "all of the X", links, "(recipe)"

### 12. Handle "For Serving" Items (~443)

Serving suggestions mixed into ingredient lists.

- [ ] **As a user, I want serving items flagged** so that "Sour cream, for serving" is marked as optional/garnish.
  - Examples: "for serving", "for garnish", "to serve"
  - Mark as `is_garnish: true` or similar

### 13. Handle Vague/Optional Items (~1,202)

Ingredients with "your choice" or "optional" phrasing.

- [ ] **As a user, I want vague ingredients handled** so that "fresh herbs of your choice" parses reasonably.
  - Examples: "your favorite BBQ sauce", "nuts of choice", "as needed", "(optional)"
  - Extract base ingredient, mark as vague/optional

### 14. Handle Packaged/Brand Products (~876)

Brand-name products and packaged mixes.

- [ ] **As a user, I want packaged products to match** so that "1 package taco seasoning mix" → taco seasoning.
  - Brand names (~528): King Arthur, Nestlé, Betty Crocker, Pillsbury
  - Packaged mixes (~348): cake mix, soup mix, seasoning packets

### 15. Handle Prepared Doughs (~316) ✅ DONE

Puff pastry, phyllo, and prepared doughs.

- [x] **As a user, I want prepared doughs to match** so that "2 sheets frozen puff pastry" → puff pastry.
  - **Implemented**: Added canonicals for puff pastry, phyllo dough, pie crust, pizza dough
  - **Implemented**: Added "sheets" and "leaves" as unit types in tokenizer

### 16. Handle Canned Goods (~113)

Canned goods with size in parentheses.

- [ ] **As a user, I want canned goods to parse** so that "1 (15 oz) can black beans" → black beans.
  - Pattern: `(X oz) can ingredient` — extract ingredient, store can size

---

## Summary

| Priority | Category | Occurrences | Status |
|----------|----------|-------------|--------|
| **High** | Butter (stick notation) | 1,282 | ✅ Done |
| **High** | Gram measurements | 1,051 | ✅ Done |
| **High** | Slash notation (cup/grams) | 888 | ✅ Done |
| **High** | Ginger (size notation) | 608 | ✅ Done |
| **High** | Filter equipment | 268 | ✅ Done |
| Medium | Alcoholic beverages | 1,364 | Pending |
| Medium | Vague/optional items | 1,202 | Pending |
| Medium | For serving items | 443 | Pending |
| Medium | Generic ingredients | ~400 | Partial (broth, nuts done) |
| Medium | Recipe references | 321 | Pending |
| Lower | Packaged/brand products | 876 | Pending |
| Lower | Prepared doughs | 316 | ✅ Done |
| Lower | Cloves (spice) | 140 | ✅ Done |
| Lower | Canned goods | 113 | Pending |
| Lower | Seasoning blends | 103 | ✅ Done |
| Lower | Chipotle in adobo | 87 | Pending |

**Parser fixes (High priority): ~4,097 occurrences (22% of unmatched) — ✅ COMPLETE**
**Missing canonicals (Medium): ~3,730 occurrences (20% of unmatched) — Partial progress**
**Edge cases (Lower): ~1,635 occurrences (9% of unmatched) — ~560 addressed**

**Total addressable: ~9,462 occurrences (50% of unmatched)**

The remaining ~9,385 are long-tail unique phrasings (single occurrence each) that would require either fuzzy matching or extensive canonical expansion.
