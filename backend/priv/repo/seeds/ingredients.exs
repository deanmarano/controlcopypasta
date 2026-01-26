# Seed data for canonical ingredients, preparations, and forms
#
# Run with: mix run priv/repo/seeds/ingredients.exs
#
# This creates the base ingredient catalog with categories, allergen info,
# and dietary flags for recipe ingredient matching.

alias Controlcopypasta.Ingredients

IO.puts("Seeding canonical ingredients...")

# =============================================================================
# Canonical Ingredients
# =============================================================================

canonical_ingredients = [
  # ---------------------------------------------------------------------------
  # Flour & Grains
  # ---------------------------------------------------------------------------
  %{
    name: "flour",
    display_name: "All-Purpose Flour",
    category: "grain",
    subcategory: "flour",
    tags: ["baking", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["all-purpose flour", "all purpose flour", "ap flour", "plain flour"]
  },
  %{
    name: "bread flour",
    display_name: "Bread Flour",
    category: "grain",
    subcategory: "flour",
    tags: ["baking", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["strong flour", "high-gluten flour"]
  },
  %{
    name: "cake flour",
    display_name: "Cake Flour",
    category: "grain",
    subcategory: "flour",
    tags: ["baking", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["pastry flour"]
  },
  %{
    name: "whole wheat flour",
    display_name: "Whole Wheat Flour",
    category: "grain",
    subcategory: "flour",
    tags: ["baking", "wheat", "whole grain"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["wholemeal flour", "graham flour"]
  },
  %{
    name: "self-rising flour",
    display_name: "Self-Rising Flour",
    category: "grain",
    subcategory: "flour",
    tags: ["baking", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["self rising flour", "self-raising flour"]
  },
  %{
    name: "rice",
    display_name: "Rice",
    category: "grain",
    tags: ["staple"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["white rice", "long grain rice"]
  },
  %{
    name: "pasta",
    display_name: "Pasta",
    category: "grain",
    tags: ["wheat", "staple"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["spaghetti", "penne", "linguine", "fettuccine"]
  },
  %{
    name: "oats",
    display_name: "Oats",
    category: "grain",
    tags: ["breakfast", "whole grain"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["rolled oats", "old fashioned oats", "oatmeal"]
  },

  # ---------------------------------------------------------------------------
  # Sugar & Sweeteners
  # ---------------------------------------------------------------------------
  %{
    name: "sugar",
    display_name: "Granulated Sugar",
    category: "sweetener",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["granulated sugar", "white sugar", "caster sugar", "castor sugar"]
  },
  %{
    name: "brown sugar",
    display_name: "Brown Sugar",
    category: "sweetener",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["light brown sugar", "dark brown sugar", "packed brown sugar"]
  },
  %{
    name: "powdered sugar",
    display_name: "Powdered Sugar",
    category: "sweetener",
    tags: ["baking", "frosting"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["confectioners sugar", "confectioners' sugar", "icing sugar", "10x sugar"]
  },
  %{
    name: "honey",
    display_name: "Honey",
    category: "sweetener",
    tags: ["natural"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["raw honey", "local honey"]
  },
  %{
    name: "maple syrup",
    display_name: "Maple Syrup",
    category: "sweetener",
    tags: ["natural"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["pure maple syrup"]
  },

  # ---------------------------------------------------------------------------
  # Dairy
  # ---------------------------------------------------------------------------
  %{
    name: "butter",
    display_name: "Butter",
    category: "dairy",
    tags: ["fat", "baking"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["unsalted butter", "salted butter", "sweet butter"]
  },
  %{
    name: "milk",
    display_name: "Milk",
    category: "dairy",
    tags: ["liquid"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["whole milk", "2% milk", "skim milk", "low-fat milk"]
  },
  %{
    name: "heavy cream",
    display_name: "Heavy Cream",
    category: "dairy",
    tags: ["fat"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["heavy whipping cream", "whipping cream", "double cream"]
  },
  %{
    name: "half and half",
    display_name: "Half and Half",
    category: "dairy",
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["half-and-half"]
  },
  %{
    name: "sour cream",
    display_name: "Sour Cream",
    category: "dairy",
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: []
  },
  %{
    name: "greek yogurt",
    display_name: "Greek Yogurt",
    category: "dairy",
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["plain greek yogurt"]
  },
  %{
    name: "yogurt",
    display_name: "Yogurt",
    category: "dairy",
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["plain yogurt"]
  },
  %{
    name: "cream cheese",
    display_name: "Cream Cheese",
    category: "dairy",
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Cheese
  # ---------------------------------------------------------------------------
  %{
    name: "cheddar",
    display_name: "Cheddar Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["cheddar cheese", "sharp cheddar", "mild cheddar"]
  },
  %{
    name: "parmesan",
    display_name: "Parmesan Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "italian"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["parmesan cheese", "parmigiano-reggiano", "parmigiano reggiano", "grated parmesan"]
  },
  %{
    name: "mozzarella",
    display_name: "Mozzarella Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "italian"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["mozzarella cheese", "fresh mozzarella"]
  },
  %{
    name: "feta",
    display_name: "Feta Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "greek"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["feta cheese", "crumbled feta"]
  },
  %{
    name: "goat cheese",
    display_name: "Goat Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["chevre"]
  },

  # ---------------------------------------------------------------------------
  # Eggs
  # ---------------------------------------------------------------------------
  %{
    name: "egg",
    display_name: "Egg",
    category: "protein",
    subcategory: "eggs",
    tags: ["breakfast", "baking"],
    is_allergen: true,
    allergen_groups: ["eggs"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["eggs", "large egg", "large eggs"]
  },
  %{
    name: "egg white",
    display_name: "Egg White",
    category: "protein",
    subcategory: "eggs",
    tags: ["baking"],
    is_allergen: true,
    allergen_groups: ["eggs"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["egg whites"]
  },
  %{
    name: "egg yolk",
    display_name: "Egg Yolk",
    category: "protein",
    subcategory: "eggs",
    tags: ["baking"],
    is_allergen: true,
    allergen_groups: ["eggs"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["egg yolks"]
  },

  # ---------------------------------------------------------------------------
  # Oils & Fats
  # ---------------------------------------------------------------------------
  %{
    name: "olive oil",
    display_name: "Olive Oil",
    category: "oil",
    tags: ["mediterranean", "healthy fat"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["extra virgin olive oil", "extra-virgin olive oil", "evoo"]
  },
  %{
    name: "vegetable oil",
    display_name: "Vegetable Oil",
    category: "oil",
    tags: ["neutral"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["canola oil", "neutral oil"]
  },
  %{
    name: "coconut oil",
    display_name: "Coconut Oil",
    category: "oil",
    tags: ["tropical"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["virgin coconut oil"]
  },
  %{
    name: "sesame oil",
    display_name: "Sesame Oil",
    category: "oil",
    tags: ["asian"],
    is_allergen: true,
    allergen_groups: ["sesame"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["toasted sesame oil", "dark sesame oil"]
  },

  # ---------------------------------------------------------------------------
  # Leavening
  # ---------------------------------------------------------------------------
  %{
    name: "baking powder",
    display_name: "Baking Powder",
    category: "leavening",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "baking soda",
    display_name: "Baking Soda",
    category: "leavening",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["bicarbonate of soda", "bicarb"]
  },
  %{
    name: "yeast",
    display_name: "Yeast",
    category: "leavening",
    tags: ["baking", "bread"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["active dry yeast", "instant yeast", "dry yeast"]
  },

  # ---------------------------------------------------------------------------
  # Salt & Seasonings
  # ---------------------------------------------------------------------------
  %{
    name: "salt",
    display_name: "Salt",
    category: "spice",
    tags: ["seasoning", "essential"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["kosher salt", "sea salt", "table salt", "flaky salt", "fine salt"]
  },
  %{
    name: "black pepper",
    display_name: "Black Pepper",
    category: "spice",
    tags: ["seasoning", "essential"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["pepper", "ground black pepper", "freshly ground black pepper", "cracked pepper"]
  },
  %{
    name: "white pepper",
    display_name: "White Pepper",
    category: "spice",
    tags: ["seasoning"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["ground white pepper"]
  },

  # ---------------------------------------------------------------------------
  # Vanilla & Extracts
  # ---------------------------------------------------------------------------
  %{
    name: "vanilla",
    display_name: "Vanilla Extract",
    category: "spice",
    subcategory: "extract",
    tags: ["baking", "dessert"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["vanilla extract", "pure vanilla extract", "vanilla paste"]
  },
  %{
    name: "vanilla bean",
    display_name: "Vanilla Bean",
    category: "spice",
    tags: ["baking", "dessert"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["vanilla pod"]
  },

  # ---------------------------------------------------------------------------
  # Alliums
  # ---------------------------------------------------------------------------
  %{
    name: "garlic",
    display_name: "Garlic",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["garlic clove", "garlic cloves", "fresh garlic"]
  },
  %{
    name: "onion",
    display_name: "Onion",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["onions", "yellow onion", "white onion", "spanish onion"]
  },
  %{
    name: "red onion",
    display_name: "Red Onion",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["red onions"]
  },
  %{
    name: "green onion",
    display_name: "Green Onion",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic", "garnish"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["green onions", "scallion", "scallions", "spring onion", "spring onions"]
  },
  %{
    name: "shallot",
    display_name: "Shallot",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["shallots"]
  },
  %{
    name: "leek",
    display_name: "Leek",
    category: "produce",
    subcategory: "allium",
    tags: ["aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["leeks"]
  },

  # ---------------------------------------------------------------------------
  # Herbs (Fresh)
  # ---------------------------------------------------------------------------
  %{
    name: "parsley",
    display_name: "Parsley",
    category: "herb",
    tags: ["fresh", "garnish"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh parsley", "flat-leaf parsley", "italian parsley"]
  },
  %{
    name: "cilantro",
    display_name: "Cilantro",
    category: "herb",
    tags: ["fresh", "mexican", "asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh cilantro", "coriander", "coriander leaves"]
  },
  %{
    name: "basil",
    display_name: "Basil",
    category: "herb",
    tags: ["fresh", "italian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh basil", "sweet basil"]
  },
  %{
    name: "oregano",
    display_name: "Oregano",
    category: "herb",
    tags: ["italian", "mediterranean"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh oregano", "dried oregano"]
  },
  %{
    name: "thyme",
    display_name: "Thyme",
    category: "herb",
    tags: ["french"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh thyme", "dried thyme", "thyme leaves"]
  },
  %{
    name: "rosemary",
    display_name: "Rosemary",
    category: "herb",
    tags: ["mediterranean"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh rosemary", "dried rosemary"]
  },
  %{
    name: "sage",
    display_name: "Sage",
    category: "herb",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh sage", "dried sage"]
  },
  %{
    name: "mint",
    display_name: "Mint",
    category: "herb",
    tags: ["fresh", "dessert"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh mint", "spearmint", "peppermint"]
  },
  %{
    name: "dill",
    display_name: "Dill",
    category: "herb",
    tags: ["fresh"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh dill", "dill weed", "dill fronds"]
  },
  %{
    name: "chives",
    display_name: "Chives",
    category: "herb",
    tags: ["fresh", "garnish"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh chives", "chive"]
  },
  %{
    name: "bay leaf",
    display_name: "Bay Leaf",
    category: "herb",
    tags: ["dried"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["bay leaves", "laurel leaf"]
  },

  # ---------------------------------------------------------------------------
  # Spices
  # ---------------------------------------------------------------------------
  %{
    name: "cinnamon",
    display_name: "Cinnamon",
    category: "spice",
    tags: ["baking", "sweet"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["ground cinnamon", "cinnamon stick", "cinnamon sticks"]
  },
  %{
    name: "nutmeg",
    display_name: "Nutmeg",
    category: "spice",
    tags: ["baking", "sweet"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["ground nutmeg", "whole nutmeg"]
  },
  %{
    name: "cumin",
    display_name: "Cumin",
    category: "spice",
    tags: ["indian", "mexican"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["ground cumin", "cumin seeds"]
  },
  %{
    name: "paprika",
    display_name: "Paprika",
    category: "spice",
    tags: ["hungarian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["sweet paprika"]
  },
  %{
    name: "smoked paprika",
    display_name: "Smoked Paprika",
    category: "spice",
    tags: ["spanish"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["pimenton", "pimentón"]
  },
  %{
    name: "cayenne",
    display_name: "Cayenne Pepper",
    category: "spice",
    tags: ["hot", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cayenne pepper", "ground cayenne"]
  },
  %{
    name: "red pepper flakes",
    display_name: "Red Pepper Flakes",
    category: "spice",
    tags: ["hot", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["crushed red pepper", "chili flakes"]
  },
  %{
    name: "chili powder",
    display_name: "Chili Powder",
    category: "spice",
    tags: ["mexican", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "curry powder",
    display_name: "Curry Powder",
    category: "spice",
    tags: ["indian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "ginger",
    display_name: "Fresh Ginger",
    category: "spice",
    tags: ["asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh ginger", "ginger root"]
  },
  %{
    name: "ground ginger",
    display_name: "Ground Ginger",
    category: "spice",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["dried ginger", "ginger powder"]
  },
  %{
    name: "turmeric",
    display_name: "Turmeric",
    category: "spice",
    tags: ["indian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["ground turmeric", "turmeric powder"]
  },

  # ---------------------------------------------------------------------------
  # Chicken
  # ---------------------------------------------------------------------------
  %{
    name: "chicken",
    display_name: "Chicken",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["whole chicken"]
  },
  %{
    name: "chicken breast",
    display_name: "Chicken Breast",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry", "chicken", "white meat", "lean"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["chicken breasts", "boneless skinless chicken breast", "boneless chicken breast"]
  },
  %{
    name: "chicken thigh",
    display_name: "Chicken Thigh",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry", "chicken", "dark meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["chicken thighs", "boneless chicken thigh", "boneless chicken thighs"]
  },
  %{
    name: "chicken leg",
    display_name: "Chicken Leg",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry", "chicken", "dark meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["chicken legs", "chicken drumstick", "chicken drumsticks"]
  },
  %{
    name: "ground chicken",
    display_name: "Ground Chicken",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry", "chicken", "ground"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["minced chicken"]
  },

  # ---------------------------------------------------------------------------
  # Beef
  # ---------------------------------------------------------------------------
  %{
    name: "beef",
    display_name: "Beef",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "ground beef",
    display_name: "Ground Beef",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat", "ground"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["minced beef", "hamburger meat"]
  },
  %{
    name: "beef chuck",
    display_name: "Beef Chuck",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["chuck roast", "chuck steak"]
  },
  %{
    name: "steak",
    display_name: "Steak",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["beef steak"]
  },
  %{
    name: "sirloin",
    display_name: "Sirloin",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat", "steak"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["sirloin steak", "top sirloin"]
  },
  %{
    name: "ribeye",
    display_name: "Ribeye",
    category: "protein",
    subcategory: "beef",
    tags: ["meat", "red meat", "steak"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["ribeye steak", "rib eye"]
  },

  # ---------------------------------------------------------------------------
  # Pork
  # ---------------------------------------------------------------------------
  %{
    name: "pork",
    display_name: "Pork",
    category: "protein",
    subcategory: "pork",
    tags: ["meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "ground pork",
    display_name: "Ground Pork",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "ground"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["minced pork"]
  },
  %{
    name: "pork chop",
    display_name: "Pork Chop",
    category: "protein",
    subcategory: "pork",
    tags: ["meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["pork chops"]
  },
  %{
    name: "bacon",
    display_name: "Bacon",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "breakfast", "cured"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["bacon strips", "bacon slices"]
  },
  %{
    name: "sausage",
    display_name: "Sausage",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "breakfast"],
    dietary_flags: ["gluten_free", "dairy_free"],
    aliases: ["pork sausage", "breakfast sausage"]
  },

  # ---------------------------------------------------------------------------
  # Seafood
  # ---------------------------------------------------------------------------
  %{
    name: "salmon",
    display_name: "Salmon",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["salmon fillet", "salmon filet"]
  },
  %{
    name: "shrimp",
    display_name: "Shrimp",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["prawns"]
  },
  %{
    name: "tuna",
    display_name: "Tuna",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["tuna steak", "canned tuna"]
  },

  # ---------------------------------------------------------------------------
  # Tomato Products
  # ---------------------------------------------------------------------------
  %{
    name: "tomato",
    display_name: "Tomato",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["tomatoes", "roma tomato", "roma tomatoes", "vine tomato", "vine tomatoes"]
  },
  %{
    name: "cherry tomato",
    display_name: "Cherry Tomato",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "fruit", "tomato"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cherry tomatoes", "grape tomato", "grape tomatoes"]
  },
  %{
    name: "canned tomatoes",
    display_name: "Canned Tomatoes",
    category: "produce",
    subcategory: "vegetable",
    tags: ["tomato", "canned"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["canned tomato", "diced tomatoes", "whole tomatoes", "petite diced tomatoes"]
  },
  %{
    name: "crushed tomatoes",
    display_name: "Crushed Tomatoes",
    category: "produce",
    subcategory: "vegetable",
    tags: ["tomato", "canned"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "tomato paste",
    display_name: "Tomato Paste",
    category: "condiment",
    tags: ["tomato", "concentrated"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["double-concentrated tomato paste", "concentrated tomato paste", "tube tomato paste"]
  },
  %{
    name: "tomato sauce",
    display_name: "Tomato Sauce",
    category: "condiment",
    tags: ["tomato"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Common Vegetables
  # ---------------------------------------------------------------------------
  %{
    name: "carrot",
    display_name: "Carrot",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "root"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["carrots"]
  },
  %{
    name: "celery",
    display_name: "Celery",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["celery stalk", "celery stalks"]
  },
  %{
    name: "potato",
    display_name: "Potato",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "starchy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["potatoes", "russet potato", "yukon gold potato"]
  },
  %{
    name: "bell pepper",
    display_name: "Bell Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["bell peppers", "red bell pepper", "green bell pepper", "yellow bell pepper"]
  },
  %{
    name: "broccoli",
    display_name: "Broccoli",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["broccoli florets"]
  },
  %{
    name: "spinach",
    display_name: "Spinach",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "leafy green"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["baby spinach", "fresh spinach"]
  },
  %{
    name: "kale",
    display_name: "Kale",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "leafy green"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["curly kale", "lacinato kale", "tuscan kale"]
  },
  %{
    name: "lettuce",
    display_name: "Lettuce",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "leafy green", "salad"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["romaine lettuce", "iceberg lettuce", "butter lettuce"]
  },
  %{
    name: "cucumber",
    display_name: "Cucumber",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "salad"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cucumbers", "english cucumber"]
  },
  %{
    name: "zucchini",
    display_name: "Zucchini",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "squash"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["courgette"]
  },
  %{
    name: "mushroom",
    display_name: "Mushroom",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "fungi"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["mushrooms", "button mushrooms", "cremini mushrooms", "shiitake mushrooms"]
  },

  # ---------------------------------------------------------------------------
  # Citrus
  # ---------------------------------------------------------------------------
  %{
    name: "lemon",
    display_name: "Lemon",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "citrus"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["lemons"]
  },
  %{
    name: "lemon juice",
    display_name: "Lemon Juice",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "juice"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh lemon juice"]
  },
  %{
    name: "lemon zest",
    display_name: "Lemon Zest",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "zest"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "lime",
    display_name: "Lime",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "citrus"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["limes"]
  },
  %{
    name: "lime juice",
    display_name: "Lime Juice",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "juice"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fresh lime juice"]
  },
  %{
    name: "lime zest",
    display_name: "Lime Zest",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "zest"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "orange",
    display_name: "Orange",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "citrus"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["oranges", "navel orange"]
  },
  %{
    name: "orange juice",
    display_name: "Orange Juice",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "juice"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["fresh orange juice"]
  },
  %{
    name: "orange zest",
    display_name: "Orange Zest",
    category: "produce",
    subcategory: "fruit",
    tags: ["citrus", "zest"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Nuts
  # ---------------------------------------------------------------------------
  %{
    name: "almond",
    display_name: "Almond",
    category: "nut",
    tags: ["nuts"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["almonds", "whole almonds", "sliced almonds", "slivered almonds"]
  },
  %{
    name: "walnut",
    display_name: "Walnut",
    category: "nut",
    tags: ["nuts"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["walnuts", "walnut halves"]
  },
  %{
    name: "pecan",
    display_name: "Pecan",
    category: "nut",
    tags: ["nuts"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["pecans", "pecan halves"]
  },
  %{
    name: "peanut",
    display_name: "Peanut",
    category: "legume",
    tags: ["legumes"],
    is_allergen: true,
    allergen_groups: ["peanuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["peanuts", "roasted peanuts"]
  },
  %{
    name: "cashew",
    display_name: "Cashew",
    category: "nut",
    tags: ["nuts"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cashews", "raw cashews"]
  },
  %{
    name: "pistachio",
    display_name: "Pistachio",
    category: "nut",
    tags: ["nuts"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["pistachios", "shelled pistachios"]
  },

  # ---------------------------------------------------------------------------
  # Nut Butters & Spreads
  # ---------------------------------------------------------------------------
  %{
    name: "peanut butter",
    display_name: "Peanut Butter",
    category: "condiment",
    tags: ["spread", "breakfast"],
    is_allergen: true,
    allergen_groups: ["peanuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["creamy peanut butter", "smooth peanut butter", "crunchy peanut butter", "chunky peanut butter"]
  },
  %{
    name: "almond butter",
    display_name: "Almond Butter",
    category: "condiment",
    tags: ["spread"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "tahini",
    display_name: "Tahini",
    category: "condiment",
    tags: ["middle eastern", "spread"],
    is_allergen: true,
    allergen_groups: ["sesame"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["sesame paste", "sesame tahini"]
  },

  # ---------------------------------------------------------------------------
  # More Vegetables
  # ---------------------------------------------------------------------------
  %{
    name: "red bell pepper",
    display_name: "Red Bell Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["red pepper", "red capsicum"]
  },
  %{
    name: "green bell pepper",
    display_name: "Green Bell Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["green pepper", "green capsicum"]
  },
  %{
    name: "yellow bell pepper",
    display_name: "Yellow Bell Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["yellow pepper", "yellow capsicum"]
  },
  %{
    name: "jalapeno",
    display_name: "Jalapeno",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["jalapeno pepper", "jalapeño", "jalapeño pepper"]
  },
  %{
    name: "serrano chile",
    display_name: "Serrano Chile",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["serrano", "serrano pepper", "serrano chiles", "serrano chilies"]
  },
  %{
    name: "poblano",
    display_name: "Poblano Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "mild"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["poblano pepper", "poblano chile", "poblanos"]
  },
  %{
    name: "habanero",
    display_name: "Habanero Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "very spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["habanero pepper", "habanero chile", "habaneros"]
  },
  %{
    name: "thai chile",
    display_name: "Thai Chile",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "spicy", "thai"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["thai chili", "bird's eye chile", "thai bird chile"]
  },
  %{
    name: "chipotle pepper",
    display_name: "Chipotle Pepper",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "pepper", "smoked", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["chipotle", "chipotle chile", "chipotles in adobo"]
  },
  %{
    name: "cabbage",
    display_name: "Cabbage",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["green cabbage"]
  },
  %{
    name: "red cabbage",
    display_name: "Red Cabbage",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["purple cabbage"]
  },
  %{
    name: "napa cabbage",
    display_name: "Napa Cabbage",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous", "asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["chinese cabbage"]
  },
  %{
    name: "cauliflower",
    display_name: "Cauliflower",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cauliflower florets"]
  },
  %{
    name: "asparagus",
    display_name: "Asparagus",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["asparagus spears"]
  },
  %{
    name: "green beans",
    display_name: "Green Beans",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["string beans", "snap beans", "french beans"]
  },
  %{
    name: "sweet potato",
    display_name: "Sweet Potato",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "starchy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["sweet potatoes", "yam"]
  },
  %{
    name: "corn",
    display_name: "Corn",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "grain"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sweet corn", "corn kernels"]
  },
  %{
    name: "avocado",
    display_name: "Avocado",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "healthy fat"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["avocados", "ripe avocado"]
  },

  # ---------------------------------------------------------------------------
  # More Noodles & Pasta
  # ---------------------------------------------------------------------------
  %{
    name: "lo mein noodles",
    display_name: "Lo Mein Noodles",
    category: "grain",
    tags: ["asian", "noodles"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["lo mein", "chinese noodles"]
  },
  %{
    name: "ramen noodles",
    display_name: "Ramen Noodles",
    category: "grain",
    tags: ["asian", "noodles", "japanese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["ramen", "instant ramen"]
  },
  %{
    name: "rice noodles",
    display_name: "Rice Noodles",
    category: "grain",
    tags: ["asian", "noodles"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["pad thai noodles", "vermicelli", "rice vermicelli"]
  },
  %{
    name: "udon noodles",
    display_name: "Udon Noodles",
    category: "grain",
    tags: ["asian", "noodles", "japanese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["udon"]
  },
  %{
    name: "soba noodles",
    display_name: "Soba Noodles",
    category: "grain",
    tags: ["asian", "noodles", "japanese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["soba", "buckwheat noodles"]
  },

  # ---------------------------------------------------------------------------
  # More Condiments & Sauces
  # ---------------------------------------------------------------------------
  %{
    name: "worcestershire sauce",
    display_name: "Worcestershire Sauce",
    category: "condiment",
    tags: ["british"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free"],
    aliases: ["worcestershire", "lea & perrins"]
  },
  %{
    name: "hot sauce",
    display_name: "Hot Sauce",
    category: "condiment",
    tags: ["spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["sriracha", "tabasco", "frank's red hot", "louisiana hot sauce"]
  },
  %{
    name: "mustard",
    display_name: "Mustard",
    category: "condiment",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["yellow mustard", "prepared mustard"]
  },
  %{
    name: "dijon mustard",
    display_name: "Dijon Mustard",
    category: "condiment",
    tags: ["french"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["dijon"]
  },
  %{
    name: "mayonnaise",
    display_name: "Mayonnaise",
    category: "condiment",
    is_allergen: true,
    allergen_groups: ["eggs"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["mayo"]
  },
  %{
    name: "ketchup",
    display_name: "Ketchup",
    category: "condiment",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["catsup", "tomato ketchup"]
  },

  # ---------------------------------------------------------------------------
  # Broths & Stocks
  # ---------------------------------------------------------------------------
  %{
    name: "chicken broth",
    display_name: "Chicken Broth",
    category: "other",
    tags: ["broth", "stock"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["chicken stock", "chicken bouillon"]
  },
  %{
    name: "beef broth",
    display_name: "Beef Broth",
    category: "other",
    tags: ["broth", "stock"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["beef stock", "beef bouillon"]
  },
  %{
    name: "vegetable broth",
    display_name: "Vegetable Broth",
    category: "other",
    tags: ["broth", "stock"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["vegetable stock", "veggie broth"]
  },

  # ---------------------------------------------------------------------------
  # Cured Meats
  # ---------------------------------------------------------------------------
  %{
    name: "pancetta",
    display_name: "Pancetta",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "cured", "italian"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["italian bacon"]
  },
  %{
    name: "guanciale",
    display_name: "Guanciale",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "cured", "italian"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["pork jowl", "cured pork jowl"]
  },
  %{
    name: "prosciutto",
    display_name: "Prosciutto",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "cured", "italian"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["prosciutto di parma"]
  },
  %{
    name: "ham",
    display_name: "Ham",
    category: "protein",
    subcategory: "pork",
    tags: ["meat", "cured"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["deli ham", "sliced ham"]
  },

  # ---------------------------------------------------------------------------
  # Baking Extras
  # ---------------------------------------------------------------------------
  %{
    name: "chocolate chips",
    display_name: "Chocolate Chips",
    category: "sweetener",
    tags: ["baking", "chocolate"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["semi-sweet chocolate chips", "dark chocolate chips", "milk chocolate chips"]
  },
  %{
    name: "cocoa powder",
    display_name: "Cocoa Powder",
    category: "spice",
    tags: ["baking", "chocolate"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto"],
    aliases: ["unsweetened cocoa powder", "dutch process cocoa", "cacao powder"]
  },
  %{
    name: "cornstarch",
    display_name: "Cornstarch",
    category: "grain",
    tags: ["baking", "thickener"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["corn starch", "cornflour"]
  },
  %{
    name: "cream of tartar",
    display_name: "Cream of Tartar",
    category: "leavening",
    tags: ["baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["potassium bitartrate"]
  },
  %{
    name: "gelatin",
    display_name: "Gelatin",
    category: "other",
    tags: ["baking", "thickener"],
    dietary_flags: ["gluten_free", "dairy_free"],
    aliases: ["unflavored gelatin", "powdered gelatin", "unflavored powdered gelatin", "gelatin powder"]
  },
  %{
    name: "panko",
    display_name: "Panko Breadcrumbs",
    category: "grain",
    tags: ["breading", "japanese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["panko breadcrumbs", "japanese breadcrumbs"]
  },
  %{
    name: "breadcrumbs",
    display_name: "Breadcrumbs",
    category: "grain",
    tags: ["breading"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["bread crumbs", "dried breadcrumbs"]
  },

  # ---------------------------------------------------------------------------
  # Beverages & Liquids
  # ---------------------------------------------------------------------------
  %{
    name: "coffee",
    display_name: "Coffee",
    category: "beverage",
    tags: ["beverage"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["brewed coffee", "strong coffee", "hot coffee", "espresso", "brewed espresso"]
  },
  %{
    name: "wine",
    display_name: "Wine",
    category: "beverage",
    tags: ["alcohol"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["white wine", "red wine", "dry white wine", "dry red wine"]
  },
  %{
    name: "beer",
    display_name: "Beer",
    category: "beverage",
    tags: ["alcohol"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: []
  },
  %{
    name: "sherry",
    display_name: "Sherry",
    category: "beverage",
    tags: ["alcohol", "wine", "spanish"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["dry sherry", "cooking sherry", "sherry wine"]
  },
  %{
    name: "vodka",
    display_name: "Vodka",
    category: "beverage",
    tags: ["alcohol", "spirit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "rum",
    display_name: "Rum",
    category: "beverage",
    tags: ["alcohol", "spirit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["dark rum", "white rum", "light rum", "spiced rum"]
  },
  %{
    name: "bourbon",
    display_name: "Bourbon",
    category: "beverage",
    tags: ["alcohol", "whiskey", "spirit"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["bourbon whiskey"]
  },
  %{
    name: "whiskey",
    display_name: "Whiskey",
    category: "beverage",
    tags: ["alcohol", "spirit"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["whisky", "scotch"]
  },
  %{
    name: "water",
    display_name: "Water",
    category: "beverage",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cold water", "warm water", "hot water", "ice water", "lukewarm water"]
  },
  %{
    name: "buttermilk",
    display_name: "Buttermilk",
    category: "dairy",
    tags: ["baking"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # More Produce
  # ---------------------------------------------------------------------------
  %{
    name: "beet",
    display_name: "Beet",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "root"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["beets", "beetroot", "red beet"]
  },
  %{
    name: "eggplant",
    display_name: "Eggplant",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["aubergine"]
  },
  %{
    name: "radish",
    display_name: "Radish",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "root"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["radishes"]
  },
  %{
    name: "turnip",
    display_name: "Turnip",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "root"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["turnips"]
  },
  %{
    name: "parsnip",
    display_name: "Parsnip",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "root"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["parsnips"]
  },
  %{
    name: "fennel",
    display_name: "Fennel",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "aromatic"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["fennel bulb"]
  },
  %{
    name: "artichoke",
    display_name: "Artichoke",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["artichokes", "artichoke hearts"]
  },
  %{
    name: "brussels sprouts",
    display_name: "Brussels Sprouts",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "cruciferous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["brussel sprouts"]
  },
  %{
    name: "bok choy",
    display_name: "Bok Choy",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "asian", "leafy green"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["pak choi", "chinese cabbage"]
  },

  # ---------------------------------------------------------------------------
  # Protein Additions
  # ---------------------------------------------------------------------------
  %{
    name: "tofu",
    display_name: "Tofu",
    category: "protein",
    tags: ["vegetarian", "asian"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["firm tofu", "extra-firm tofu", "silken tofu", "soft tofu"]
  },
  %{
    name: "tempeh",
    display_name: "Tempeh",
    category: "protein",
    tags: ["vegetarian", "fermented"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "chickpeas",
    display_name: "Chickpeas",
    category: "legume",
    tags: ["legumes", "protein"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["garbanzo beans", "canned chickpeas"]
  },
  %{
    name: "black beans",
    display_name: "Black Beans",
    category: "legume",
    tags: ["legumes", "protein"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["canned black beans"]
  },
  %{
    name: "kidney beans",
    display_name: "Kidney Beans",
    category: "legume",
    tags: ["legumes", "protein"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["red kidney beans", "canned kidney beans"]
  },
  %{
    name: "lentils",
    display_name: "Lentils",
    category: "legume",
    tags: ["legumes", "protein"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["red lentils", "green lentils", "brown lentils", "french lentils"]
  },
  %{
    name: "turkey",
    display_name: "Turkey",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["turkey breast", "ground turkey"]
  },
  %{
    name: "lamb",
    display_name: "Lamb",
    category: "protein",
    subcategory: "lamb",
    tags: ["meat", "red meat"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["lamb chops", "ground lamb", "lamb leg"]
  },
  %{
    name: "duck",
    display_name: "Duck",
    category: "protein",
    subcategory: "poultry",
    tags: ["meat", "poultry"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["duck breast", "duck leg"]
  },

  # ---------------------------------------------------------------------------
  # More Cheese
  # ---------------------------------------------------------------------------
  %{
    name: "pecorino romano",
    display_name: "Pecorino Romano",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "italian"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["pecorino", "romano cheese"]
  },
  %{
    name: "gruyere",
    display_name: "Gruyere",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "swiss"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["gruyère", "gruyere cheese"]
  },
  %{
    name: "swiss cheese",
    display_name: "Swiss Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["swiss", "emmental", "emmentaler"]
  },
  %{
    name: "ricotta",
    display_name: "Ricotta",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "italian"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["ricotta cheese"]
  },
  %{
    name: "monterey jack",
    display_name: "Monterey Jack",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["monterey jack cheese", "jack cheese", "pepper jack"]
  },
  %{
    name: "blue cheese",
    display_name: "Blue Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["bleu cheese", "gorgonzola", "roquefort", "stilton"]
  },
  %{
    name: "cotija",
    display_name: "Cotija",
    category: "dairy",
    subcategory: "cheese",
    tags: ["cheese", "mexican"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto"],
    aliases: ["cotija cheese", "queso cotija"]
  },

  # ---------------------------------------------------------------------------
  # International Ingredients
  # ---------------------------------------------------------------------------
  %{
    name: "ghee",
    display_name: "Ghee",
    category: "oil",
    tags: ["indian", "fat"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian", "gluten_free", "keto", "paleo"],
    aliases: ["clarified butter"]
  },
  %{
    name: "miso",
    display_name: "Miso",
    category: "condiment",
    tags: ["japanese", "fermented"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["miso paste", "white miso", "red miso"]
  },
  %{
    name: "gochujang",
    display_name: "Gochujang",
    category: "condiment",
    tags: ["korean", "spicy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["korean chili paste", "korean red pepper paste"]
  },
  %{
    name: "sambal oelek",
    display_name: "Sambal Oelek",
    category: "condiment",
    tags: ["indonesian", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sambal", "chili paste"]
  },
  %{
    name: "harissa",
    display_name: "Harissa",
    category: "condiment",
    tags: ["north african", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["harissa paste"]
  },
  %{
    name: "chaat masala",
    display_name: "Chaat Masala",
    category: "spice",
    tags: ["indian", "spice blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "garam masala",
    display_name: "Garam Masala",
    category: "spice",
    tags: ["indian", "spice blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "za'atar",
    display_name: "Za'atar",
    category: "spice",
    tags: ["middle eastern", "spice blend"],
    is_allergen: true,
    allergen_groups: ["sesame"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["zaatar"]
  },
  %{
    name: "sumac",
    display_name: "Sumac",
    category: "spice",
    tags: ["middle eastern"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "cardamom",
    display_name: "Cardamom",
    category: "spice",
    tags: ["indian", "baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ground cardamom", "cardamom pods"]
  },
  %{
    name: "coriander",
    display_name: "Coriander Seeds",
    category: "spice",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ground coriander", "coriander seeds"]
  },
  %{
    name: "fennel seeds",
    display_name: "Fennel Seeds",
    category: "spice",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ground fennel"]
  },
  %{
    name: "pita",
    display_name: "Pita Bread",
    category: "grain",
    subcategory: "bread",
    tags: ["bread", "middle eastern"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["pita", "pita breads", "pita pockets"]
  },
  %{
    name: "tortilla",
    display_name: "Tortilla",
    category: "grain",
    subcategory: "bread",
    tags: ["bread", "mexican"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["tortillas", "flour tortilla", "flour tortillas", "corn tortilla", "corn tortillas"]
  },
  %{
    name: "naan",
    display_name: "Naan",
    category: "grain",
    subcategory: "bread",
    tags: ["bread", "indian"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["naan bread"]
  },

  # ---------------------------------------------------------------------------
  # More Sweets & Spreads
  # ---------------------------------------------------------------------------
  %{
    name: "nutella",
    display_name: "Nutella",
    category: "condiment",
    tags: ["spread", "chocolate"],
    is_allergen: true,
    allergen_groups: ["tree_nuts", "dairy"],
    dietary_flags: ["vegetarian", "gluten_free"],
    aliases: ["chocolate hazelnut spread"]
  },
  %{
    name: "jam",
    display_name: "Jam",
    category: "condiment",
    tags: ["spread", "fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["jelly", "preserves", "fruit preserves"]
  },

  # ---------------------------------------------------------------------------
  # Cooking Sprays & Oils
  # ---------------------------------------------------------------------------
  %{
    name: "cooking spray",
    display_name: "Cooking Spray",
    category: "oil",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["nonstick spray", "nonstick cooking spray", "vegetable oil spray", "nonstick vegetable oil spray", "pan spray"]
  },

  # ---------------------------------------------------------------------------
  # More Pasta & Grains
  # ---------------------------------------------------------------------------
  %{
    name: "orzo",
    display_name: "Orzo",
    category: "grain",
    tags: ["pasta", "italian"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["orzo pasta", "risoni"]
  },
  %{
    name: "gnocchi",
    display_name: "Gnocchi",
    category: "grain",
    tags: ["pasta", "italian"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: ["potato gnocchi"]
  },
  %{
    name: "rigatoni",
    display_name: "Rigatoni",
    category: "grain",
    tags: ["pasta", "italian"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: []
  },
  %{
    name: "tagliatelle",
    display_name: "Tagliatelle",
    category: "grain",
    tags: ["pasta", "italian", "fresh pasta"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "eggs"],
    dietary_flags: ["vegetarian"],
    aliases: ["tagliatelli"]
  },
  %{
    name: "pappardelle",
    display_name: "Pappardelle",
    category: "grain",
    tags: ["pasta", "italian", "fresh pasta"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "eggs"],
    dietary_flags: ["vegetarian"],
    aliases: []
  },
  %{
    name: "ditalini",
    display_name: "Ditalini",
    category: "grain",
    tags: ["pasta", "italian", "soup pasta"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: ["ditalini pasta"]
  },
  %{
    name: "basmati rice",
    display_name: "Basmati Rice",
    category: "grain",
    tags: ["rice", "indian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["basmati"]
  },
  %{
    name: "jasmine rice",
    display_name: "Jasmine Rice",
    category: "grain",
    tags: ["rice", "thai"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "quinoa",
    display_name: "Quinoa",
    category: "grain",
    tags: ["whole grain", "protein"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "couscous",
    display_name: "Couscous",
    category: "grain",
    tags: ["north african"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["israeli couscous", "pearl couscous"]
  },
  %{
    name: "polenta",
    display_name: "Polenta",
    category: "grain",
    tags: ["italian", "cornmeal"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["cornmeal", "corn meal"]
  },
  %{
    name: "farro",
    display_name: "Farro",
    category: "grain",
    tags: ["whole grain", "italian"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: []
  },
  %{
    name: "barley",
    display_name: "Barley",
    category: "grain",
    tags: ["whole grain"],
    is_allergen: true,
    allergen_groups: ["gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["pearl barley"]
  },

  # ---------------------------------------------------------------------------
  # Olives & Pickled Items
  # ---------------------------------------------------------------------------
  %{
    name: "olives",
    display_name: "Olives",
    category: "produce",
    tags: ["mediterranean", "pickled"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["green olives", "black olives", "kalamata olives", "castelvetrano olives"]
  },
  %{
    name: "capers",
    display_name: "Capers",
    category: "produce",
    tags: ["mediterranean", "pickled"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["caper berries"]
  },
  %{
    name: "pickles",
    display_name: "Pickles",
    category: "produce",
    tags: ["pickled"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto"],
    aliases: ["dill pickles", "pickle", "gherkins"]
  },
  %{
    name: "sauerkraut",
    display_name: "Sauerkraut",
    category: "produce",
    tags: ["fermented", "german"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto"],
    aliases: []
  },
  %{
    name: "kimchi",
    display_name: "Kimchi",
    category: "produce",
    tags: ["fermented", "korean"],
    dietary_flags: ["vegan", "gluten_free"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Seafood Additions
  # ---------------------------------------------------------------------------
  %{
    name: "anchovy",
    display_name: "Anchovy",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish", "cured"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["anchovies", "anchovy fillets", "oil-packed anchovy fillets", "white anchovy"]
  },
  %{
    name: "sardines",
    display_name: "Sardines",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish", "canned"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "crab",
    display_name: "Crab",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["crab meat", "lump crab"]
  },
  %{
    name: "lobster",
    display_name: "Lobster",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["lobster tail"]
  },
  %{
    name: "scallops",
    display_name: "Scallops",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["sea scallops", "bay scallops"]
  },
  %{
    name: "mussels",
    display_name: "Mussels",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "clams",
    display_name: "Clams",
    category: "protein",
    subcategory: "shellfish",
    tags: ["seafood", "shellfish"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["littleneck clams", "manila clams"]
  },
  %{
    name: "cod",
    display_name: "Cod",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish", "white fish"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["cod fillet"]
  },
  %{
    name: "halibut",
    display_name: "Halibut",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish", "white fish"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["halibut fillet"]
  },
  %{
    name: "tilapia",
    display_name: "Tilapia",
    category: "protein",
    subcategory: "fish",
    tags: ["seafood", "fish", "white fish"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["tilapia fillet"]
  },

  # ---------------------------------------------------------------------------
  # More Fruits
  # ---------------------------------------------------------------------------
  %{
    name: "apple",
    display_name: "Apple",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["apples", "granny smith apple", "granny smith apples", "honeycrisp apple", "fuji apple", "gala apple"]
  },
  %{
    name: "pear",
    display_name: "Pear",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["pears", "bartlett pear", "bosc pear"]
  },
  %{
    name: "peach",
    display_name: "Peach",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "stone fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["peaches", "yellow peach", "white peach"]
  },
  %{
    name: "plum",
    display_name: "Plum",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "stone fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["plums"]
  },
  %{
    name: "cherry",
    display_name: "Cherry",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "stone fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["cherries", "sweet cherries", "sour cherries", "bing cherries"]
  },
  %{
    name: "mango",
    display_name: "Mango",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "tropical"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["mangoes", "mangos"]
  },
  %{
    name: "pineapple",
    display_name: "Pineapple",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "tropical"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: []
  },
  %{
    name: "banana",
    display_name: "Banana",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "tropical"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["bananas", "ripe banana"]
  },
  %{
    name: "plantain",
    display_name: "Plantain",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "tropical", "starchy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["plantains", "green plantain", "ripe plantain"]
  },
  %{
    name: "dates",
    display_name: "Dates",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "dried fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["medjool dates", "deglet noor dates", "date"]
  },
  %{
    name: "figs",
    display_name: "Figs",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["fresh figs", "dried figs", "fig"]
  },
  %{
    name: "grapes",
    display_name: "Grapes",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["red grapes", "green grapes", "grape"]
  },
  %{
    name: "berries",
    display_name: "Berries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["mixed berries", "fresh berries"]
  },
  %{
    name: "strawberries",
    display_name: "Strawberries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "berries"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["strawberry", "fresh strawberries"]
  },
  %{
    name: "blueberries",
    display_name: "Blueberries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "berries"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["blueberry", "fresh blueberries"]
  },
  %{
    name: "raspberries",
    display_name: "Raspberries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "berries"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["raspberry", "fresh raspberries"]
  },
  %{
    name: "blackberries",
    display_name: "Blackberries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "berries"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["blackberry", "fresh blackberries"]
  },
  %{
    name: "cranberries",
    display_name: "Cranberries",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "berries"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["fresh cranberries", "dried cranberries", "craisins"]
  },
  %{
    name: "raisins",
    display_name: "Raisins",
    category: "produce",
    subcategory: "fruit",
    tags: ["fruit", "dried fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["golden raisins"]
  },
  %{
    name: "pumpkin",
    display_name: "Pumpkin",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "squash"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: ["pumpkin puree", "pumpkin purée", "canned pumpkin"]
  },
  %{
    name: "butternut squash",
    display_name: "Butternut Squash",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "squash"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: []
  },
  %{
    name: "acorn squash",
    display_name: "Acorn Squash",
    category: "produce",
    subcategory: "vegetable",
    tags: ["vegetable", "squash"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Tea, Matcha & Specialty
  # ---------------------------------------------------------------------------
  %{
    name: "tea",
    display_name: "Tea",
    category: "beverage",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["black tea", "green tea", "tea bags", "earl grey tea bags", "earl grey tea", "chai tea"]
  },
  %{
    name: "matcha",
    display_name: "Matcha",
    category: "beverage",
    tags: ["japanese", "tea"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["matcha powder", "green tea powder"]
  },
  %{
    name: "cocoa nibs",
    display_name: "Cocoa Nibs",
    category: "other",
    tags: ["chocolate", "baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto"],
    aliases: ["cacao nibs"]
  },
  %{
    name: "aquafaba",
    display_name: "Aquafaba",
    category: "other",
    tags: ["vegan", "egg substitute"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["chickpea liquid", "chickpea water"]
  },
  %{
    name: "pomegranate molasses",
    display_name: "Pomegranate Molasses",
    category: "condiment",
    tags: ["middle eastern"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "mirin",
    display_name: "Mirin",
    category: "condiment",
    tags: ["japanese"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sweet rice wine"]
  },
  %{
    name: "sake",
    display_name: "Sake",
    category: "beverage",
    tags: ["japanese", "alcohol"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["cooking sake", "rice wine"]
  },
  %{
    name: "coconut milk",
    display_name: "Coconut Milk",
    category: "dairy",
    tags: ["dairy alternative", "thai"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["canned coconut milk", "full-fat coconut milk", "light coconut milk"]
  },
  %{
    name: "coconut cream",
    display_name: "Coconut Cream",
    category: "dairy",
    tags: ["dairy alternative"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "almond milk",
    display_name: "Almond Milk",
    category: "dairy",
    tags: ["dairy alternative"],
    is_allergen: true,
    allergen_groups: ["tree_nuts"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["unsweetened almond milk"]
  },
  %{
    name: "oat milk",
    display_name: "Oat Milk",
    category: "dairy",
    tags: ["dairy alternative"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: []
  },
  %{
    name: "soy milk",
    display_name: "Soy Milk",
    category: "dairy",
    tags: ["dairy alternative"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },

  # ---------------------------------------------------------------------------
  # Vinegars
  # ---------------------------------------------------------------------------
  %{
    name: "vinegar",
    display_name: "Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["distilled vinegar"]
  },
  %{
    name: "white vinegar",
    display_name: "White Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["distilled white vinegar"]
  },
  %{
    name: "red wine vinegar",
    display_name: "Red Wine Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "white wine vinegar",
    display_name: "White Wine Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: []
  },
  %{
    name: "balsamic vinegar",
    display_name: "Balsamic Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["balsamic"]
  },
  %{
    name: "apple cider vinegar",
    display_name: "Apple Cider Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "keto", "paleo"],
    aliases: ["cider vinegar"]
  },
  %{
    name: "rice vinegar",
    display_name: "Rice Vinegar",
    category: "condiment",
    subcategory: "vinegar",
    tags: ["asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["rice wine vinegar"]
  },

  # ---------------------------------------------------------------------------
  # Asian Sauces
  # ---------------------------------------------------------------------------
  %{
    name: "soy sauce",
    display_name: "Soy Sauce",
    category: "condiment",
    tags: ["asian"],
    is_allergen: true,
    allergen_groups: ["soy", "wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["low sodium soy sauce", "tamari", "shoyu"]
  },
  %{
    name: "fish sauce",
    display_name: "Fish Sauce",
    category: "condiment",
    tags: ["asian", "thai"],
    is_allergen: true,
    allergen_groups: ["fish"],
    dietary_flags: ["gluten_free", "dairy_free", "keto", "paleo"],
    aliases: ["nam pla", "nuoc mam"]
  },
  %{
    name: "oyster sauce",
    display_name: "Oyster Sauce",
    category: "condiment",
    tags: ["asian", "chinese"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: ["gluten_free"],
    aliases: []
  },
  %{
    name: "hoisin sauce",
    display_name: "Hoisin Sauce",
    category: "condiment",
    tags: ["asian", "chinese"],
    is_allergen: true,
    allergen_groups: ["soy", "wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: []
  }
]

{count, _} = Ingredients.bulk_insert_canonical_ingredients(canonical_ingredients)
IO.puts("  Inserted #{count} canonical ingredients")

# =============================================================================
# Preparations
# =============================================================================

IO.puts("Seeding preparations...")

preparations = [
  # Cutting methods
  %{name: "chopped", display_name: "Chopped", category: "cut", aliases: ["roughly chopped"]},
  %{name: "diced", display_name: "Diced", category: "cut", aliases: ["cubed", "cut into cubes"]},
  %{name: "minced", display_name: "Minced", category: "cut", aliases: ["finely minced"]},
  %{name: "sliced", display_name: "Sliced", category: "cut", aliases: ["thinly sliced"]},
  %{name: "julienned", display_name: "Julienned", category: "cut", aliases: ["cut into strips", "matchstick"]},
  %{name: "shredded", display_name: "Shredded", category: "cut", aliases: []},
  %{name: "grated", display_name: "Grated", category: "cut", aliases: ["finely grated"]},
  %{name: "crushed", display_name: "Crushed", category: "cut", aliases: []},
  %{name: "halved", display_name: "Halved", category: "cut", aliases: ["cut in half"]},
  %{name: "quartered", display_name: "Quartered", category: "cut", aliases: ["cut into quarters"]},
  %{name: "torn", display_name: "Torn", category: "cut", aliases: []},

  # Temperature/state
  %{name: "melted", display_name: "Melted", category: "temperature", aliases: []},
  %{name: "softened", display_name: "Softened", category: "temperature", aliases: ["at room temperature"]},
  %{name: "room temperature", display_name: "Room Temperature", category: "temperature", aliases: ["at room temp"]},
  %{name: "cold", display_name: "Cold", category: "temperature", aliases: ["chilled"]},
  %{name: "warm", display_name: "Warm", category: "temperature", aliases: ["warmed"]},
  %{name: "hot", display_name: "Hot", category: "temperature", aliases: []},
  %{name: "frozen", display_name: "Frozen", category: "temperature", aliases: []},
  %{name: "thawed", display_name: "Thawed", category: "temperature", aliases: ["defrosted"]},

  # Processing
  %{name: "drained", display_name: "Drained", category: "process", aliases: ["well drained"]},
  %{name: "rinsed", display_name: "Rinsed", category: "process", aliases: ["rinsed and drained"]},
  %{name: "strained", display_name: "Strained", category: "process", aliases: []},
  %{name: "peeled", display_name: "Peeled", category: "process", aliases: []},
  %{name: "seeded", display_name: "Seeded", category: "process", aliases: ["seeds removed"]},
  %{name: "cored", display_name: "Cored", category: "process", aliases: ["core removed"]},
  %{name: "pitted", display_name: "Pitted", category: "process", aliases: ["pit removed"]},
  %{name: "trimmed", display_name: "Trimmed", category: "process", aliases: []},
  %{name: "deveined", display_name: "Deveined", category: "process", aliases: []},

  # Texture
  %{name: "mashed", display_name: "Mashed", category: "texture", aliases: []},
  %{name: "pureed", display_name: "Pureed", category: "texture", aliases: ["blended"]},
  %{name: "beaten", display_name: "Beaten", category: "texture", aliases: ["lightly beaten"]},
  %{name: "whisked", display_name: "Whisked", category: "texture", aliases: []},
  %{name: "sifted", display_name: "Sifted", category: "texture", aliases: []},

  # Cooking state
  %{name: "fresh", display_name: "Fresh", category: "other", aliases: []},
  %{name: "dried", display_name: "Dried", category: "other", aliases: []},
  %{name: "canned", display_name: "Canned", category: "other", aliases: []},
  %{name: "cooked", display_name: "Cooked", category: "other", aliases: ["pre-cooked"]},
  %{name: "raw", display_name: "Raw", category: "other", aliases: []},
  %{name: "toasted", display_name: "Toasted", category: "heat", aliases: ["lightly toasted"]},
  %{name: "roasted", display_name: "Roasted", category: "heat", aliases: []}
]

{count, _} = Ingredients.bulk_insert_preparations(preparations)
IO.puts("  Inserted #{count} preparations")

IO.puts("Ingredient seeding complete!")
