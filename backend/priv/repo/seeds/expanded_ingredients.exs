# Expanded canonical ingredients for improved recipe matching
#
# Run with: mix run priv/repo/seeds/expanded_ingredients.exs
#
# These ingredients cover common unmatched names found in the 131K recipe corpus.
# Uses on_conflict: :nothing so safe to re-run.

alias Controlcopypasta.Ingredients

IO.puts("Seeding expanded canonical ingredients...")

expanded_ingredients = [
  # ---------------------------------------------------------------------------
  # Spices & Seasonings
  # ---------------------------------------------------------------------------
  %{
    name: "calabrian chile paste",
    display_name: "Calabrian Chile Paste",
    category: "spice",
    subcategory: "chile paste",
    tags: ["italian", "spicy", "condiment"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["calabrian chili paste", "calabrian pepper paste"]
  },
  %{
    name: "adobo seasoning",
    display_name: "Adobo Seasoning",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["latin", "blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["adobo", "adobo all-purpose seasoning"]
  },
  %{
    name: "berbere spice",
    display_name: "Berbere Spice Blend",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["ethiopian", "african", "blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["berbere", "berbere spice blend", "berberé"]
  },
  %{
    name: "kala namak",
    display_name: "Kala Namak (Black Salt)",
    category: "spice",
    subcategory: "salt",
    tags: ["indian", "sulfurous"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["black salt", "himalayan black salt"]
  },
  %{
    name: "tajin seasoning",
    display_name: "Tajín Seasoning",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["mexican", "chili-lime"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["tajín", "tajin", "tajin clasico"]
  },
  %{
    name: "everything bagel seasoning",
    display_name: "Everything Bagel Seasoning",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["blend", "topping"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["everything seasoning", "everything but the bagel seasoning"]
  },
  %{
    name: "old bay seasoning",
    display_name: "Old Bay Seasoning",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["seafood", "blend", "american"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["old bay"]
  },
  %{
    name: "zaatar",
    display_name: "Za'atar",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["middle eastern", "blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["za'atar", "zatar", "zahtar"]
  },
  %{
    name: "ras el hanout",
    display_name: "Ras el Hanout",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["moroccan", "north african", "blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ras el hanout spice blend"]
  },
  %{
    name: "herbs de provence",
    display_name: "Herbs de Provence",
    category: "spice",
    subcategory: "herb blend",
    tags: ["french", "blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["herbes de provence"]
  },
  %{
    name: "furikake",
    display_name: "Furikake",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["japanese", "rice topping"],
    dietary_flags: [],
    aliases: ["furikake seasoning", "rice seasoning"]
  },
  %{
    name: "shichimi togarashi",
    display_name: "Shichimi Togarashi",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["japanese", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["togarashi", "seven spice", "nanami togarashi"]
  },

  # ---------------------------------------------------------------------------
  # Asian Pantry
  # ---------------------------------------------------------------------------
  %{
    name: "dashi",
    display_name: "Dashi",
    category: "pantry",
    subcategory: "stock",
    tags: ["japanese", "umami"],
    dietary_flags: [],
    aliases: ["instant dashi", "instant dashi powder", "dashi stock", "dashi powder", "hondashi"]
  },
  %{
    name: "bonito flakes",
    display_name: "Bonito Flakes",
    category: "seafood",
    subcategory: "dried fish",
    tags: ["japanese", "umami"],
    dietary_flags: [],
    aliases: ["katsuobushi", "dried bonito flakes", "shaved bonito"]
  },
  %{
    name: "yuzu juice",
    display_name: "Yuzu Juice",
    category: "produce",
    subcategory: "citrus juice",
    tags: ["japanese", "citrus"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["yuzu", "bottled yuzu juice"]
  },
  %{
    name: "fermented soybean paste",
    display_name: "Fermented Soybean Paste",
    category: "pantry",
    subcategory: "fermented",
    tags: ["asian", "umami", "fermented"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["fermented soy beans", "fermented soybeans", "doenjang"]
  },
  %{
    name: "aonori",
    display_name: "Aonori (Green Seaweed Flakes)",
    category: "pantry",
    subcategory: "seaweed",
    tags: ["japanese"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ao nori", "green laver flakes"]
  },
  %{
    name: "somen noodles",
    display_name: "Somen Noodles",
    category: "grain",
    subcategory: "noodle",
    tags: ["japanese", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["somen", "soumen noodles", "thin wheat noodles"]
  },
  %{
    name: "yakisoba noodles",
    display_name: "Yakisoba Noodles",
    category: "grain",
    subcategory: "noodle",
    tags: ["japanese", "wheat"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["yakisoba", "stir-fry noodles"]
  },
  %{
    name: "wheat vermicelli",
    display_name: "Wheat Vermicelli",
    category: "grain",
    subcategory: "noodle",
    tags: ["thin noodle"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["thin wheat noodles"]
  },
  %{
    name: "gochugaru",
    display_name: "Gochugaru (Korean Red Pepper Flakes)",
    category: "spice",
    subcategory: "pepper flakes",
    tags: ["korean", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["korean red pepper flakes", "korean chili flakes"]
  },
  %{
    name: "doubanjiang",
    display_name: "Doubanjiang (Chili Bean Paste)",
    category: "pantry",
    subcategory: "fermented paste",
    tags: ["chinese", "sichuan", "spicy"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["doubanjiang paste", "chili bean paste", "toban djan", "broad bean paste"]
  },
  %{
    name: "shaoxing wine",
    display_name: "Shaoxing Wine",
    category: "pantry",
    subcategory: "cooking wine",
    tags: ["chinese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["shaoxing cooking wine", "shaoxing rice wine", "chinese cooking wine"]
  },
  %{
    name: "tamarind paste",
    display_name: "Tamarind Paste",
    category: "pantry",
    subcategory: "paste",
    tags: ["asian", "sour"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["tamarind concentrate", "tamarind"]
  },
  %{
    name: "palm sugar",
    display_name: "Palm Sugar",
    category: "pantry",
    subcategory: "sweetener",
    tags: ["asian", "thai"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["coconut palm sugar", "jaggery"]
  },

  # ---------------------------------------------------------------------------
  # Produce
  # ---------------------------------------------------------------------------
  %{
    name: "shishito pepper",
    display_name: "Shishito Peppers",
    category: "produce",
    subcategory: "pepper",
    tags: ["japanese", "mild"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["shishito peppers", "shishito"]
  },
  %{
    name: "endive",
    display_name: "Endive",
    category: "produce",
    subcategory: "lettuce",
    tags: ["salad", "bitter"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["endives", "belgian endive", "belgian endives"]
  },
  %{
    name: "culantro",
    display_name: "Culantro",
    category: "produce",
    subcategory: "herb",
    tags: ["caribbean", "latin"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["recao", "long coriander", "sawtooth herb"]
  },
  %{
    name: "sweet pepper",
    display_name: "Sweet Peppers",
    category: "produce",
    subcategory: "pepper",
    tags: ["sweet", "snacking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sweet peppers", "mini sweet peppers", "mini peppers"]
  },
  %{
    name: "fresno chile",
    display_name: "Fresno Chile",
    category: "produce",
    subcategory: "chile pepper",
    tags: ["medium heat"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["fresno chili", "fresno pepper", "fresno chiles", "red fresno chile"]
  },
  %{
    name: "banana pepper",
    display_name: "Banana Pepper",
    category: "produce",
    subcategory: "pepper",
    tags: ["mild"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["banana peppers", "yellow wax pepper"]
  },
  %{
    name: "persian cucumber",
    display_name: "Persian Cucumber",
    category: "produce",
    subcategory: "cucumber",
    tags: ["seedless", "snacking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["persian cucumbers", "mini cucumber", "mini cucumbers"]
  },
  %{
    name: "delicata squash",
    display_name: "Delicata Squash",
    category: "produce",
    subcategory: "winter squash",
    tags: ["sweet"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["delicata"]
  },
  %{
    name: "kohlrabi",
    display_name: "Kohlrabi",
    category: "produce",
    subcategory: "root vegetable",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["german turnip"]
  },
  %{
    name: "ramp",
    display_name: "Ramps",
    category: "produce",
    subcategory: "allium",
    tags: ["spring", "wild"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ramps", "wild leek", "wild leeks", "wild ramps"]
  },
  %{
    name: "watermelon radish",
    display_name: "Watermelon Radish",
    category: "produce",
    subcategory: "radish",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["watermelon radishes"]
  },
  %{
    name: "broccolini",
    display_name: "Broccolini",
    category: "produce",
    subcategory: "brassica",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["baby broccoli", "tenderstem broccoli"]
  },
  %{
    name: "romanesco",
    display_name: "Romanesco",
    category: "produce",
    subcategory: "brassica",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["romanesco broccoli", "roman cauliflower"]
  },

  # ---------------------------------------------------------------------------
  # Dairy & Alternatives
  # ---------------------------------------------------------------------------
  %{
    name: "creme fraiche",
    display_name: "Crème Fraîche",
    category: "dairy",
    subcategory: "cream",
    tags: ["french", "cultured"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["crème fraîche", "crème fraiche", "creme fraîche"]
  },
  %{
    name: "whole milk ricotta",
    display_name: "Whole Milk Ricotta",
    category: "dairy",
    subcategory: "cheese",
    tags: ["italian"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["whole-milk ricotta", "whole milk ricotta cheese"]
  },
  %{
    name: "whole milk yogurt",
    display_name: "Whole Milk Yogurt",
    category: "dairy",
    subcategory: "yogurt",
    tags: [],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["whole-milk yogurt", "full-fat yogurt", "full fat yogurt"]
  },
  %{
    name: "labneh",
    display_name: "Labneh",
    category: "dairy",
    subcategory: "yogurt",
    tags: ["middle eastern", "strained"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["labne", "labna", "yogurt cheese"]
  },
  %{
    name: "queso fresco",
    display_name: "Queso Fresco",
    category: "dairy",
    subcategory: "cheese",
    tags: ["mexican"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["fresh mexican cheese"]
  },
  %{
    name: "cotija cheese",
    display_name: "Cotija Cheese",
    category: "dairy",
    subcategory: "cheese",
    tags: ["mexican", "aged"],
    is_allergen: true,
    allergen_groups: ["dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["cotija"]
  },

  # ---------------------------------------------------------------------------
  # Meat & Protein
  # ---------------------------------------------------------------------------
  %{
    name: "beef eye of round",
    display_name: "Beef Eye of Round",
    category: "meat",
    subcategory: "beef",
    tags: ["lean", "roast"],
    dietary_flags: [],
    aliases: ["eye of round", "eye of round roast", "eye round"]
  },
  %{
    name: "beef stew meat",
    display_name: "Beef Stew Meat",
    category: "meat",
    subcategory: "beef",
    tags: ["cubed"],
    dietary_flags: [],
    aliases: ["stew meat", "stewing beef", "beef stew chunks"]
  },
  %{
    name: "cocktail sausage",
    display_name: "Cocktail Sausages",
    category: "meat",
    subcategory: "sausage",
    tags: ["party", "smoked"],
    dietary_flags: [],
    aliases: ["cocktail sausages", "smoked cocktail sausages", "little smokies", "lil smokies"]
  },
  %{
    name: "beef short rib",
    display_name: "Beef Short Ribs",
    category: "meat",
    subcategory: "beef",
    tags: ["braising"],
    dietary_flags: [],
    aliases: ["short ribs", "beef short ribs", "bone-in short ribs", "boneless short ribs"]
  },
  %{
    name: "pork belly",
    display_name: "Pork Belly",
    category: "meat",
    subcategory: "pork",
    tags: [],
    dietary_flags: [],
    aliases: ["skin-on pork belly", "skinless pork belly"]
  },
  %{
    name: "lamb shoulder",
    display_name: "Lamb Shoulder",
    category: "meat",
    subcategory: "lamb",
    tags: ["braising"],
    dietary_flags: [],
    aliases: ["boneless lamb shoulder", "lamb shoulder roast"]
  },
  %{
    name: "duck breast",
    display_name: "Duck Breast",
    category: "meat",
    subcategory: "poultry",
    tags: [],
    dietary_flags: [],
    aliases: ["duck breasts", "magret", "magret de canard"]
  },

  # ---------------------------------------------------------------------------
  # Condiments & Sauces
  # ---------------------------------------------------------------------------
  %{
    name: "cranberry sauce",
    display_name: "Cranberry Sauce",
    category: "pantry",
    subcategory: "condiment",
    tags: ["holiday", "thanksgiving"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["jellied cranberry sauce", "whole berry cranberry sauce", "canned cranberry sauce"]
  },
  %{
    name: "buffalo wing sauce",
    display_name: "Buffalo Wing Sauce",
    category: "pantry",
    subcategory: "hot sauce",
    tags: ["spicy", "american"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["buffalo sauce", "wing sauce", "frank's red hot buffalo sauce"]
  },
  %{
    name: "sweet chili sauce",
    display_name: "Sweet Chili Sauce",
    category: "pantry",
    subcategory: "sauce",
    tags: ["thai", "sweet", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["thai sweet chili sauce", "mae ploy sweet chili sauce"]
  },
  %{
    name: "olive brine",
    display_name: "Olive Brine",
    category: "pantry",
    subcategory: "brine",
    tags: ["cocktail"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["olive juice", "green olive brine"]
  },
  %{
    name: "chicago-style relish",
    display_name: "Chicago-Style Relish",
    category: "pantry",
    subcategory: "relish",
    tags: ["american", "hot dog"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["neon relish", "chicago relish", "bright green relish"]
  },
  %{
    name: "gochujang",
    display_name: "Gochujang",
    category: "pantry",
    subcategory: "fermented paste",
    tags: ["korean", "spicy", "fermented"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["korean red pepper paste", "korean chili paste"]
  },
  %{
    name: "harissa",
    display_name: "Harissa",
    category: "pantry",
    subcategory: "chile paste",
    tags: ["north african", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["harissa paste", "harissa sauce"]
  },
  %{
    name: "chimichurri",
    display_name: "Chimichurri",
    category: "pantry",
    subcategory: "sauce",
    tags: ["argentinian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["chimichurri sauce"]
  },

  # ---------------------------------------------------------------------------
  # Prepared & Packaged Foods
  # ---------------------------------------------------------------------------
  %{
    name: "hash brown patty",
    display_name: "Hash Brown Patties",
    category: "frozen",
    subcategory: "potato",
    tags: ["breakfast"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["hash brown patties", "frozen hash browns", "hash brown"]
  },
  %{
    name: "stuffing mix",
    display_name: "Stuffing Mix",
    category: "pantry",
    subcategory: "baking mix",
    tags: ["thanksgiving", "holiday"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: ["stovetop stuffing", "boxed stuffing"]
  },
  %{
    name: "crescent roll dough",
    display_name: "Crescent Roll Dough",
    category: "refrigerated",
    subcategory: "dough",
    tags: ["convenience"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["refrigerated crescent rolls", "crescent rolls", "pillsbury crescent rolls", "crescent roll"]
  },
  %{
    name: "matzo meal",
    display_name: "Matzo Meal",
    category: "pantry",
    subcategory: "flour",
    tags: ["jewish", "passover"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["matzah meal", "matzo", "matzoh meal"]
  },
  %{
    name: "puff pastry",
    display_name: "Puff Pastry",
    category: "frozen",
    subcategory: "dough",
    tags: ["baking", "french"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "dairy"],
    dietary_flags: ["vegetarian"],
    aliases: ["puff pastry sheets", "frozen puff pastry", "puff pastry dough"]
  },
  %{
    name: "phyllo dough",
    display_name: "Phyllo Dough",
    category: "frozen",
    subcategory: "dough",
    tags: ["baking", "greek"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["filo dough", "phyllo sheets", "filo pastry", "phyllo pastry"]
  },
  %{
    name: "pie crust",
    display_name: "Pie Crust",
    category: "refrigerated",
    subcategory: "dough",
    tags: ["baking"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: ["refrigerated pie crust", "premade pie crust", "frozen pie crust", "pie shell"]
  },
  %{
    name: "wonton wrapper",
    display_name: "Wonton Wrappers",
    category: "refrigerated",
    subcategory: "wrapper",
    tags: ["chinese", "dumpling"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["wonton wrappers", "wonton skins", "dumpling wrappers"]
  },
  %{
    name: "egg roll wrapper",
    display_name: "Egg Roll Wrappers",
    category: "refrigerated",
    subcategory: "wrapper",
    tags: ["chinese"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten", "egg"],
    dietary_flags: ["vegetarian"],
    aliases: ["egg roll wrappers", "spring roll wrappers", "egg roll skins"]
  },

  # ---------------------------------------------------------------------------
  # Spirits & Beverages
  # ---------------------------------------------------------------------------
  %{
    name: "midori",
    display_name: "Midori (Melon Liqueur)",
    category: "alcohol",
    subcategory: "liqueur",
    tags: ["cocktail", "melon"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["melon liqueur", "midori melon liqueur"]
  },
  %{
    name: "suze",
    display_name: "Suze (Gentian Liqueur)",
    category: "alcohol",
    subcategory: "liqueur",
    tags: ["cocktail", "bitter", "french"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["suze liqueur", "gentian liqueur"]
  },
  %{
    name: "passoa",
    display_name: "Passoã (Passion Fruit Liqueur)",
    category: "alcohol",
    subcategory: "liqueur",
    tags: ["cocktail", "passion fruit"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["passoã", "passion fruit liqueur"]
  },
  %{
    name: "aperol",
    display_name: "Aperol",
    category: "alcohol",
    subcategory: "aperitivo",
    tags: ["cocktail", "bitter", "italian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["aperol aperitivo"]
  },
  %{
    name: "citrus aperitivo",
    display_name: "Citrus Aperitivo",
    category: "alcohol",
    subcategory: "aperitivo",
    tags: ["cocktail", "bitter"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["nonalcoholic citrus aperitivo", "non-alcoholic aperitivo", "ghia"]
  },
  %{
    name: "amaretto",
    display_name: "Amaretto",
    category: "alcohol",
    subcategory: "liqueur",
    tags: ["cocktail", "almond", "italian"],
    is_allergen: true,
    allergen_groups: ["tree_nut"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["amaretto liqueur", "disaronno"]
  },
  %{
    name: "maraschino liqueur",
    display_name: "Maraschino Liqueur",
    category: "alcohol",
    subcategory: "liqueur",
    tags: ["cocktail", "cherry"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["luxardo maraschino", "maraschino"]
  },

  # ---------------------------------------------------------------------------
  # Baking & Sweets
  # ---------------------------------------------------------------------------
  %{
    name: "passion fruit puree",
    display_name: "Passion Fruit Purée",
    category: "produce",
    subcategory: "fruit puree",
    tags: ["tropical", "baking"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["passion fruit purée", "passionfruit puree", "passion fruit pulp"]
  },
  %{
    name: "meringue powder",
    display_name: "Meringue Powder",
    category: "pantry",
    subcategory: "baking",
    tags: ["baking", "icing"],
    dietary_flags: ["vegetarian"],
    aliases: []
  },
  %{
    name: "cream of tartar",
    display_name: "Cream of Tartar",
    category: "pantry",
    subcategory: "baking",
    tags: ["baking", "leavening"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["potassium bitartrate"]
  },
  %{
    name: "black cocoa powder",
    display_name: "Black Cocoa Powder",
    category: "pantry",
    subcategory: "cocoa",
    tags: ["baking", "chocolate"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["black onyx cocoa powder", "ultra-dutch cocoa"]
  },

  # ---------------------------------------------------------------------------
  # Miscellaneous
  # ---------------------------------------------------------------------------
  %{
    name: "psyllium husk",
    display_name: "Psyllium Husk",
    category: "pantry",
    subcategory: "fiber",
    tags: ["gluten-free baking", "fiber"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["psyllium husk powder", "psyllium husks", "whole psyllium husk"]
  },
  %{
    name: "seaweed snack",
    display_name: "Seaweed Snacks",
    category: "pantry",
    subcategory: "seaweed",
    tags: ["korean", "japanese", "snack"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["seaweed snacks", "roasted seaweed", "nori snacks", "seasoned seaweed"]
  },
  %{
    name: "rose water",
    display_name: "Rose Water",
    category: "pantry",
    subcategory: "flavoring",
    tags: ["middle eastern", "floral"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["rosewater"]
  },
  %{
    name: "orange blossom water",
    display_name: "Orange Blossom Water",
    category: "pantry",
    subcategory: "flavoring",
    tags: ["middle eastern", "floral"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["orange flower water"]
  },
  %{
    name: "barberry",
    display_name: "Barberries",
    category: "pantry",
    subcategory: "dried fruit",
    tags: ["persian", "tart"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["barberries", "dried barberries", "zereshk"]
  },
  %{
    name: "sumac",
    display_name: "Sumac",
    category: "spice",
    subcategory: "ground spice",
    tags: ["middle eastern", "tart"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["ground sumac", "sumac powder"]
  },
  %{
    name: "nigella seed",
    display_name: "Nigella Seeds",
    category: "spice",
    subcategory: "whole spice",
    tags: ["indian", "middle eastern"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["nigella seeds", "black onion seeds", "kalonji"]
  },
  %{
    name: "urfa biber",
    display_name: "Urfa Biber",
    category: "spice",
    subcategory: "chile flakes",
    tags: ["turkish", "smoky"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["urfa pepper", "urfa chile flakes", "urfa biber flakes", "isot pepper"]
  },
  %{
    name: "aleppo pepper",
    display_name: "Aleppo Pepper",
    category: "spice",
    subcategory: "chile flakes",
    tags: ["middle eastern", "mild heat"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["aleppo pepper flakes", "pul biber", "aleppo chile flakes", "aleppo-style pepper"]
  },
  %{
    name: "thai basil",
    display_name: "Thai Basil",
    category: "produce",
    subcategory: "herb",
    tags: ["thai", "southeast asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["horapa", "holy basil"]
  },
  %{
    name: "makrut lime leaf",
    display_name: "Makrut Lime Leaves",
    category: "produce",
    subcategory: "herb",
    tags: ["thai", "southeast asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["makrut lime leaves", "kaffir lime leaf", "kaffir lime leaves"]
  },
  %{
    name: "lemongrass",
    display_name: "Lemongrass",
    category: "produce",
    subcategory: "herb",
    tags: ["thai", "southeast asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["lemon grass", "lemongrass stalk", "lemongrass stalks"]
  },
  %{
    name: "galangal",
    display_name: "Galangal",
    category: "produce",
    subcategory: "root",
    tags: ["thai", "southeast asian"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["galangal root", "fresh galangal"]
  },
  %{
    name: "chinese five spice powder",
    display_name: "Chinese Five Spice Powder",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["chinese"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["five spice powder", "five-spice powder", "chinese five-spice", "5 spice powder"]
  },
  %{
    name: "preserved lemon",
    display_name: "Preserved Lemons",
    category: "pantry",
    subcategory: "preserved",
    tags: ["moroccan", "north african"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["preserved lemons", "salt-preserved lemon"]
  },
  %{
    name: "peppadew pepper",
    display_name: "Peppadew Peppers",
    category: "pantry",
    subcategory: "pickled pepper",
    tags: ["south african", "sweet-spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["peppadew peppers", "peppadew", "piquante peppers"]
  },
  %{
    name: "calabrian chile",
    display_name: "Calabrian Chiles",
    category: "pantry",
    subcategory: "chile pepper",
    tags: ["italian", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["calabrian chiles", "calabrian chili", "calabrian peppers", "crushed calabrian chiles"]
  },
  %{
    name: "sambal oelek",
    display_name: "Sambal Oelek",
    category: "pantry",
    subcategory: "chile paste",
    tags: ["indonesian", "spicy"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sambal", "sambal ulek", "ground fresh chili paste"]
  },
  %{
    name: "mirin",
    display_name: "Mirin",
    category: "pantry",
    subcategory: "cooking wine",
    tags: ["japanese", "sweet"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["rice wine", "sweet rice wine", "hon mirin"]
  },
  %{
    name: "tahini",
    display_name: "Tahini",
    category: "pantry",
    subcategory: "paste",
    tags: ["middle eastern", "sesame"],
    is_allergen: true,
    allergen_groups: ["sesame"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["sesame paste", "tahini paste"]
  },
  %{
    name: "pomegranate molasses",
    display_name: "Pomegranate Molasses",
    category: "pantry",
    subcategory: "syrup",
    tags: ["middle eastern", "tart"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["pomegranate syrup"]
  },
  %{
    name: "corn tortilla",
    display_name: "Corn Tortillas",
    category: "grain",
    subcategory: "tortilla",
    tags: ["mexican"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["corn tortillas", "small corn tortillas", "6-inch corn tortillas"]
  },
  %{
    name: "flour tortilla",
    display_name: "Flour Tortillas",
    category: "grain",
    subcategory: "tortilla",
    tags: ["mexican"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian"],
    aliases: ["flour tortillas", "burrito-size flour tortillas", "large flour tortillas"]
  },
  %{
    name: "panko breadcrumbs",
    display_name: "Panko Breadcrumbs",
    category: "pantry",
    subcategory: "breadcrumb",
    tags: ["japanese", "crispy"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["panko", "japanese breadcrumbs", "panko bread crumbs"]
  },
  %{
    name: "hemp seed",
    display_name: "Hemp Seeds",
    category: "pantry",
    subcategory: "seed",
    tags: ["superfood", "omega-3"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["hemp seeds", "hemp hearts", "shelled hemp seeds"]
  },
  %{
    name: "nutritional yeast",
    display_name: "Nutritional Yeast",
    category: "pantry",
    subcategory: "seasoning",
    tags: ["vegan", "cheese substitute"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["nooch", "nutritional yeast flakes"]
  },
  %{
    name: "aquafaba",
    display_name: "Aquafaba",
    category: "pantry",
    subcategory: "egg substitute",
    tags: ["vegan", "chickpea"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["chickpea brine", "chickpea liquid", "liquid from canned chickpeas"]
  },
  %{
    name: "liquid smoke",
    display_name: "Liquid Smoke",
    category: "pantry",
    subcategory: "flavoring",
    tags: ["smoky", "bbq"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["hickory liquid smoke", "mesquite liquid smoke"]
  },
  %{
    name: "pickling spice",
    display_name: "Pickling Spice",
    category: "spice",
    subcategory: "seasoning blend",
    tags: ["preserving"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["pickling spice blend"]
  },
  %{
    name: "celery salt",
    display_name: "Celery Salt",
    category: "spice",
    subcategory: "seasoned salt",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: []
  },
  %{
    name: "lemon pepper",
    display_name: "Lemon Pepper Seasoning",
    category: "spice",
    subcategory: "seasoning blend",
    tags: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"],
    aliases: ["lemon pepper seasoning"]
  },
  %{
    name: "chili crisp",
    display_name: "Chili Crisp",
    category: "pantry",
    subcategory: "condiment",
    tags: ["chinese", "spicy", "crunchy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["chili crunch", "lao gan ma", "chilli crisp", "crispy chili oil"]
  },
  %{
    name: "fish sauce",
    display_name: "Fish Sauce",
    category: "pantry",
    subcategory: "sauce",
    tags: ["thai", "vietnamese", "umami"],
    dietary_flags: [],
    aliases: ["nam pla", "nuoc mam", "patis"]
  },
  %{
    name: "oyster sauce",
    display_name: "Oyster Sauce",
    category: "pantry",
    subcategory: "sauce",
    tags: ["chinese", "umami"],
    is_allergen: true,
    allergen_groups: ["shellfish"],
    dietary_flags: [],
    aliases: []
  },
  %{
    name: "hoisin sauce",
    display_name: "Hoisin Sauce",
    category: "pantry",
    subcategory: "sauce",
    tags: ["chinese", "sweet"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["hoisin"]
  },
  %{
    name: "black bean sauce",
    display_name: "Black Bean Sauce",
    category: "pantry",
    subcategory: "sauce",
    tags: ["chinese", "fermented"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["fermented black bean sauce", "black bean garlic sauce"]
  },
  %{
    name: "thai curry paste",
    display_name: "Thai Curry Paste",
    category: "pantry",
    subcategory: "paste",
    tags: ["thai", "spicy"],
    dietary_flags: [],
    aliases: ["curry paste"]
  },
  %{
    name: "thai red curry paste",
    display_name: "Thai Red Curry Paste",
    category: "pantry",
    subcategory: "paste",
    tags: ["thai", "spicy"],
    dietary_flags: [],
    aliases: ["red curry paste", "red thai curry paste"]
  },
  %{
    name: "thai green curry paste",
    display_name: "Thai Green Curry Paste",
    category: "pantry",
    subcategory: "paste",
    tags: ["thai", "spicy"],
    dietary_flags: [],
    aliases: ["green curry paste", "green thai curry paste"]
  },
  %{
    name: "white miso paste",
    display_name: "White Miso Paste",
    category: "pantry",
    subcategory: "fermented paste",
    tags: ["japanese", "umami"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["white miso", "shiro miso"]
  },
  %{
    name: "red miso paste",
    display_name: "Red Miso Paste",
    category: "pantry",
    subcategory: "fermented paste",
    tags: ["japanese", "umami"],
    is_allergen: true,
    allergen_groups: ["soy"],
    dietary_flags: ["vegetarian", "vegan"],
    aliases: ["red miso", "aka miso"]
  },
]

{count, _} = Ingredients.bulk_insert_canonical_ingredients(expanded_ingredients)
IO.puts("  Inserted #{count} expanded canonical ingredients")

IO.puts("Expanded ingredient seeding complete!")
