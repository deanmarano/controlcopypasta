# Expanded aliases for existing canonical ingredients
#
# Run with: mix run priv/repo/seeds/expanded_aliases.exs
#
# Adds aliases to existing canonical ingredients for common variations
# that are not currently matched. Safe to re-run.

alias Controlcopypasta.Ingredients

IO.puts("Adding expanded aliases to existing canonical ingredients...")

# Each entry: {canonical_name, [new_aliases_to_add]}
alias_additions = [
  {"eggplant", ["italian eggplant", "italian eggplants", "japanese eggplant", "japanese eggplants",
                 "chinese eggplant", "chinese eggplants", "baby eggplant", "baby eggplants",
                 "graffiti eggplant"]},
  {"red pepper flakes", ["red-pepper flakes", "crushed red pepper flakes", "crushed red-pepper flakes",
                          "crushed red pepper"]},
  {"bell pepper", ["mini sweet pepper", "mini sweet peppers", "sweet bell pepper", "sweet bell peppers"]},
  {"pita", ["pita with pockets", "pita bread", "pitas", "pita rounds", "pocket pita"]},
  {"tortilla chip", ["tortilla chips", "corn chips", "corn tortilla chips"]},
  {"chicken thigh", ["boneless skinless chicken thighs", "bone-in chicken thighs",
                     "skin-on chicken thighs", "bone-in skin-on chicken thighs"]},
  {"chicken breast", ["boneless skinless chicken breasts", "boneless chicken breasts",
                      "skinless chicken breasts"]},
  {"ground beef", ["lean ground beef", "extra-lean ground beef", "ground chuck",
                    "ground sirloin", "85% lean ground beef", "80/20 ground beef"]},
  {"ground turkey", ["lean ground turkey", "extra-lean ground turkey", "93% lean ground turkey"]},
  {"ground pork", ["ground pork sausage"]},
  {"bacon", ["thick-cut bacon", "thick cut bacon", "center-cut bacon", "applewood-smoked bacon",
             "regular bacon", "smoked bacon"]},
  {"sausage", ["italian sausage", "sweet italian sausage", "hot italian sausage",
               "italian sausage link", "italian sausage links", "pork sausage"]},
  {"shrimp", ["large shrimp", "jumbo shrimp", "extra-large shrimp", "medium shrimp",
              "peeled and deveined shrimp", "raw shrimp", "frozen shrimp"]},
  {"salmon", ["salmon fillet", "salmon fillets", "skin-on salmon", "skinless salmon",
              "center-cut salmon", "wild salmon", "sockeye salmon", "atlantic salmon"]},
  {"cream cheese", ["full-fat cream cheese", "reduced-fat cream cheese", "neufchatel cheese",
                     "block cream cheese"]},
  {"sour cream", ["full-fat sour cream", "reduced-fat sour cream", "light sour cream"]},
  {"heavy cream", ["heavy whipping cream", "whipping cream"]},
  {"milk", ["whole milk", "2% milk", "1% milk", "skim milk", "reduced-fat milk"]},
  {"butter", ["unsalted butter", "salted butter", "cold butter", "room temperature butter",
              "softened butter", "melted butter"]},
  {"olive oil", ["extra-virgin olive oil", "extra virgin olive oil", "evoo",
                 "good-quality olive oil"]},
  {"vegetable oil", ["canola oil", "neutral oil", "neutral-flavored oil"]},
  {"coconut milk", ["full-fat coconut milk", "light coconut milk", "canned coconut milk",
                     "unsweetened coconut milk"]},
  {"coconut cream", ["cream of coconut", "coconut cream (not cream of coconut)"]},
  {"rice vinegar", ["seasoned rice vinegar", "unseasoned rice vinegar", "rice wine vinegar"]},
  {"soy sauce", ["low-sodium soy sauce", "reduced-sodium soy sauce", "tamari",
                  "light soy sauce", "dark soy sauce"]},
  {"worcestershire sauce", ["lea & perrins", "lea and perrins"]},
  {"hot sauce", ["frank's red hot", "franks red hot", "louisiana hot sauce",
                  "tabasco", "texas pete", "cholula"]},
  {"mustard", ["yellow mustard", "prepared mustard", "american mustard"]},
  {"dijon mustard", ["smooth dijon mustard", "coarse-grain dijon mustard"]},
  {"whole grain mustard", ["stone-ground mustard", "coarse mustard", "grainy mustard"]},
  {"ketchup", ["tomato ketchup", "catsup"]},
  {"mayonnaise", ["mayo", "hellmann's mayonnaise", "best foods mayonnaise",
                   "duke's mayonnaise", "japanese mayonnaise", "kewpie mayonnaise"]},
  {"honey", ["raw honey", "local honey", "wildflower honey", "clover honey"]},
  {"maple syrup", ["pure maple syrup", "grade a maple syrup", "dark maple syrup"]},
  {"brown sugar", ["light brown sugar", "dark brown sugar", "packed brown sugar"]},
  {"powdered sugar", ["confectioners' sugar", "confectioners sugar", "icing sugar",
                       "10x sugar"]},
  {"vanilla extract", ["pure vanilla extract", "vanilla"]},
  {"baking powder", ["double-acting baking powder"]},
  {"cornstarch", ["corn starch", "cornflour"]},
  {"tomato paste", ["double-concentrated tomato paste", "tomato purée", "tube tomato paste"]},
  {"crushed tomatoes", ["crushed canned tomatoes", "fire-roasted crushed tomatoes"]},
  {"diced tomatoes", ["canned diced tomatoes", "fire-roasted diced tomatoes", "petite diced tomatoes"]},
  {"chicken broth", ["chicken stock", "low-sodium chicken broth", "chicken bone broth"]},
  {"beef broth", ["beef stock", "low-sodium beef broth", "beef bone broth"]},
  {"vegetable broth", ["vegetable stock", "low-sodium vegetable broth"]},
  {"black bean", ["canned black beans", "dried black beans"]},
  {"cannellini bean", ["canned cannellini beans", "white kidney beans"]},
  {"chickpea", ["canned chickpeas", "dried chickpeas", "garbanzo bean", "garbanzo beans",
                 "canned garbanzo beans"]},
  {"kidney bean", ["canned kidney beans", "red kidney beans", "dark red kidney beans"]},
  {"pinto bean", ["canned pinto beans", "dried pinto beans"]},
  {"white bean", ["canned white beans", "great northern beans", "navy beans"]},
  {"lentil", ["green lentils", "brown lentils", "french lentils", "lentils du puy"]},
  {"red lentil", ["red lentils", "split red lentils", "masoor dal"]},
  {"cheddar cheese", ["sharp cheddar", "sharp cheddar cheese", "mild cheddar",
                       "extra-sharp cheddar", "white cheddar"]},
  {"mozzarella cheese", ["fresh mozzarella", "low-moisture mozzarella",
                           "shredded mozzarella", "mozzarella ball"]},
  {"parmesan cheese", ["parmigiano-reggiano", "parmigiano reggiano",
                         "grated parmesan", "shredded parmesan"]},
  {"feta cheese", ["crumbled feta", "block feta", "french feta", "greek feta"]},
  {"goat cheese", ["chèvre", "chevre", "fresh goat cheese", "crumbled goat cheese"]},
  {"gruyere cheese", ["gruyère", "gruyère cheese"]},
  {"pecorino romano", ["pecorino", "pecorino cheese"]},
  {"fontina cheese", ["fontina", "italian fontina"]},
  {"swiss cheese", ["emmental", "emmentaler", "jarlsberg"]},
  {"provolone cheese", ["provolone", "sharp provolone"]},
  {"monterey jack cheese", ["monterey jack", "pepper jack", "pepper jack cheese"]},
  {"green onion", ["scallion", "scallions", "green onions", "spring onion", "spring onions"]},
  {"shallot", ["shallots", "banana shallot", "banana shallots"]},
  {"jalapeno", ["jalapeño", "jalapeño pepper", "jalapeno pepper"]},
  {"serrano pepper", ["serrano chile", "serrano chili", "serrano"]},
  {"habanero pepper", ["habanero", "habanero chile"]},
  {"thai chile", ["thai chili", "thai bird chile", "bird's eye chile", "bird chile"]},
  {"poblano pepper", ["poblano", "poblano chile", "pasilla pepper"]},
  {"anaheim pepper", ["anaheim chile", "new mexico chile", "hatch chile", "hatch green chile"]},
  {"chipotle pepper", ["chipotle", "chipotle chile", "chipotles in adobo",
                        "chipotle peppers in adobo", "canned chipotles", "canned chipotle"]},
  {"arugula", ["baby arugula", "wild arugula", "rocket"]},
  {"spinach", ["baby spinach", "fresh spinach", "flat-leaf spinach"]},
  {"kale", ["curly kale", "lacinato kale", "tuscan kale", "dinosaur kale", "baby kale"]},
  {"romaine lettuce", ["romaine", "romaine hearts", "hearts of romaine"]},
  {"mixed greens", ["spring mix", "mesclun", "salad mix", "mixed salad greens"]},
  {"avocado", ["ripe avocado", "hass avocado", "haas avocado"]},
  {"tomato", ["roma tomato", "roma tomatoes", "plum tomato", "plum tomatoes",
              "vine tomato", "vine tomatoes", "beefsteak tomato", "on-the-vine tomatoes"]},
  {"cherry tomato", ["grape tomatoes", "grape tomato", "cherry tomatoes"]},
  {"cucumber", ["english cucumber", "hothouse cucumber", "seedless cucumber"]},
  {"zucchini", ["courgette", "courgettes", "summer squash"]},
  {"sweet potato", ["sweet potatoes", "garnet yam", "jewel yam"]},
  {"butternut squash", ["butternut", "peeled butternut squash", "cubed butternut squash"]},
  {"kabocha squash", ["kabocha", "japanese pumpkin"]},
  {"acorn squash", ["acorn"]},
  {"broccoli", ["broccoli florets", "broccoli crowns"]},
  {"cauliflower", ["cauliflower florets", "cauliflower head"]},
  {"brussels sprout", ["brussels sprouts", "brussel sprouts", "brussel sprout"]},
  {"asparagus", ["asparagus spears", "thick asparagus", "thin asparagus"]},
  {"green bean", ["green beans", "haricots verts", "string beans", "snap beans", "french beans"]},
  {"corn", ["sweet corn", "corn kernels", "fresh corn", "frozen corn"]},
  {"mushroom", ["button mushrooms", "cremini mushrooms", "baby bella mushrooms",
                 "white mushrooms", "brown mushrooms"]},
  {"shiitake mushroom", ["shiitake mushrooms", "shiitake", "fresh shiitake",
                          "dried shiitake mushrooms", "dried shiitake"]},
  {"portobello mushroom", ["portobello mushrooms", "portobello", "portobella",
                             "portabella mushroom", "portabella mushrooms"]},
  {"rice noodle", ["rice noodles", "pad thai noodles", "rice stick noodles", "rice vermicelli"]},
  {"ramen noodle", ["ramen noodles", "instant ramen noodles", "fresh ramen noodles"]},
  {"udon noodle", ["udon noodles", "udon", "fresh udon", "dried udon"]},
  {"tofu", ["firm tofu", "extra-firm tofu", "silken tofu", "soft tofu", "pressed tofu"]},
  {"tempeh", ["organic tempeh", "soy tempeh"]},
  {"coconut oil", ["virgin coconut oil", "refined coconut oil", "unrefined coconut oil"]},
  {"sesame oil", ["toasted sesame oil", "dark sesame oil", "roasted sesame oil"]},
  {"peanut butter", ["creamy peanut butter", "chunky peanut butter", "smooth peanut butter",
                      "natural peanut butter"]},
  {"almond butter", ["creamy almond butter", "smooth almond butter"]},
  {"almond", ["whole almonds", "raw almonds", "blanched almonds", "marcona almonds"]},
  {"walnut", ["walnuts", "walnut halves", "walnut pieces", "raw walnuts", "toasted walnuts"]},
  {"pecan", ["pecans", "pecan halves", "pecan pieces", "toasted pecans"]},
  {"cashew", ["cashews", "raw cashews", "roasted cashews", "unsalted cashews"]},
  {"pistachio", ["pistachios", "shelled pistachios", "unsalted pistachios", "roasted pistachios"]},
  {"pine nut", ["pine nuts", "pignoli", "pinoli"]},
  {"sesame seed", ["sesame seeds", "white sesame seeds", "black sesame seeds", "toasted sesame seeds"]},
  {"pepita", ["pepitas", "pumpkin seeds", "raw pepitas", "roasted pepitas"]},
  {"sunflower seed", ["sunflower seeds", "raw sunflower seeds", "roasted sunflower seeds"]},
  {"flax seed", ["flaxseed", "flaxseeds", "flax seeds", "ground flaxseed", "flax meal"]},
  {"chia seed", ["chia seeds"]},
  {"dried cranberry", ["dried cranberries", "craisins"]},
  {"raisin", ["raisins", "golden raisins", "dark raisins", "sultanas"]},
  {"date", ["medjool dates", "medjool date", "pitted dates", "deglet noor dates"]},
  {"fig", ["dried figs", "fresh figs", "black mission figs", "calimyrna figs"]},
  {"coconut flake", ["coconut flakes", "unsweetened coconut flakes", "shredded coconut",
                      "unsweetened shredded coconut", "sweetened shredded coconut",
                      "desiccated coconut", "coconut shreds"]},
  {"chocolate chip", ["chocolate chips", "semisweet chocolate chips", "semi-sweet chocolate chips",
                       "dark chocolate chips", "milk chocolate chips", "mini chocolate chips"]},
  {"tortilla", ["soft tortillas", "small tortillas"]},
  {"hamburger bun", ["hamburger buns", "brioche buns", "burger buns", "slider buns"]},
  {"hot dog bun", ["hot dog buns"]},
  {"english muffin", ["english muffins"]},
  {"naan", ["naan bread", "garlic naan"]},
  {"sourdough bread", ["sourdough", "sourdough loaf"]},
  {"white bread", ["sandwich bread", "sliced white bread"]},
  {"baguette", ["french bread", "french baguette"]},
  {"ciabatta", ["ciabatta bread", "ciabatta roll", "ciabatta rolls"]},
  {"heavy cream", ["double cream"]},
]

updated_count = Enum.reduce(alias_additions, 0, fn {canonical_name, new_aliases}, acc ->
  case Ingredients.get_canonical_ingredient_by_name(canonical_name) do
    nil ->
      IO.puts("  WARNING: Canonical ingredient '#{canonical_name}' not found, skipping aliases")
      acc

    ingredient ->
      existing_aliases = ingredient.aliases || []
      # Only add aliases that don't already exist
      truly_new = Enum.reject(new_aliases, &(&1 in existing_aliases))

      if truly_new == [] do
        acc
      else
        merged_aliases = existing_aliases ++ truly_new
        case Ingredients.update_canonical_ingredient(ingredient, %{aliases: merged_aliases}) do
          {:ok, _} -> acc + length(truly_new)
          {:error, reason} ->
            IO.puts("  ERROR updating '#{canonical_name}': #{inspect(reason)}")
            acc
        end
      end
  end
end)

IO.puts("  Added #{updated_count} new aliases to existing canonical ingredients")
IO.puts("Expanded alias seeding complete!")
