defmodule Controlcopypasta.Repo.Migrations.SyncProdIngredientsToDev do
  use Ecto.Migration

  @moduledoc """
  Syncs canonical ingredients from production to dev.
  Adds 178 ingredients that exist in production but not in the dev seed.
  """

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ingredients = [
      %{
        name: "absinthe",
        display_name: "Absinthe",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "adobo sauce",
        display_name: "Adobo Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "alfredo sauce",
        display_name: "Alfredo Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "angostura bitters",
        display_name: "Angostura Bitters",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "aperol",
        display_name: "Aperol",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "apple juice concentrate",
        display_name: "Apple Juice Concentrate",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "apple pie spice",
        display_name: "Apple Pie Spice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "applesauce",
        display_name: "Applesauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "arrowroot",
        display_name: "Arrowroot",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "baby lima beans",
        display_name: "Baby Lima Beans",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "bamboo shoots",
        display_name: "Bamboo Shoots",
        category: nil,
        subcategory: nil,
        aliases: ["bamboo shoot"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "barbecue sauce",
        display_name: "Barbecue Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "bisquick",
        display_name: "Bisquick",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "bisquick baking mix",
        display_name: "Bisquick Baking Mix",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "bouillon paste",
        display_name: "Bouillon Paste",
        category: "condiment",
        subcategory: nil,
        aliases: ["bouillon", "better than bouillon", "stock concentrate", "stock paste", "bouillon concentrate", "soup base"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: ["gluten_free"]
      },
      %{
        name: "broccolini",
        display_name: "Broccolini",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "brownie mix",
        display_name: "Brownie Mix",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "burrata",
        display_name: "Burrata",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "butterscotch chips",
        display_name: "Butterscotch Chips",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cajun seasoning",
        display_name: "Cajun Seasoning",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "canola oil",
        display_name: "Canola Oil",
        category: "oil",
        subcategory: nil,
        aliases: ["rapeseed oil", "grape seed oil", "grapeseed oil"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: ["vegetarian", "vegan", "gluten_free"]
      },
      %{
        name: "caramel",
        display_name: "Caramel",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "caraway seeds",
        display_name: "Caraway Seeds",
        category: nil,
        subcategory: nil,
        aliases: ["caraway seed", "caraway"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chambord",
        display_name: "Chambord",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "champagne",
        display_name: "Champagne",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cheese tortellini",
        display_name: "Cheese Tortellini",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cherry pie filling",
        display_name: "Cherry Pie Filling",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chia seeds",
        display_name: "Chia Seeds",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chili crisp",
        display_name: "Chili Crisp",
        category: "condiment",
        subcategory: nil,
        aliases: ["chili crunch", "crunchy chili oil", "lao gan ma", "chili crisp oil", "chile crisp"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: ["vegetarian", "vegan", "gluten_free"]
      },
      %{
        name: "chili-garlic sauce",
        display_name: "Chili-garlic Sauce",
        category: nil,
        subcategory: nil,
        aliases: ["chile-garlic sauce"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chili oil",
        display_name: "Chili Oil",
        category: nil,
        subcategory: nil,
        aliases: ["chile oil"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chocolate cake mix",
        display_name: "Chocolate Cake Mix",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "chocolate syrup",
        display_name: "Chocolate Syrup",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "clam juice",
        display_name: "Clam Juice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "coconut extract",
        display_name: "Coconut Extract",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "coconut flakes",
        display_name: "Coconut Flakes",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "coleslaw mix",
        display_name: "Coleslaw Mix",
        category: nil,
        subcategory: nil,
        aliases: ["coleslaw", "cole slaw mix"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "collard greens",
        display_name: "Collard Greens",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cornbread",
        display_name: "Cornbread",
        category: nil,
        subcategory: nil,
        aliases: ["corn bread"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cornichons",
        display_name: "Cornichons",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "crabmeat",
        display_name: "Crabmeat",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "cranberry juice",
        display_name: "Cranberry Juice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "crisco",
        display_name: "Crisco",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "croutons",
        display_name: "Croutons",
        category: nil,
        subcategory: nil,
        aliases: ["crouton"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "curacao",
        display_name: "Curacao",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "currants",
        display_name: "Currants",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "dark brown sugar",
        display_name: "Dark Brown Sugar",
        category: "sweetener",
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "dark chocolate",
        display_name: "Dark Chocolate",
        category: "sweetener",
        subcategory: nil,
        aliases: ["dark chocolate chips", "dark chocolate chunks", "dark chocolate wafers", "dark chocolate disks", "dark chocolate pistoles", "dark chocolate fèves"],
        is_allergen: true,
        allergen_groups: ["dairy"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },
      %{
        name: "delicata squash",
        display_name: "Delicata Squash",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "diastatic malt powder",
        display_name: "Diastatic Malt Powder",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "dried hibiscus flowers",
        display_name: "Dried Hibiscus Flowers",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "edible flowers",
        display_name: "Edible Flowers",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "everything bagel seasoning",
        display_name: "Everything Bagel Seasoning",
        category: nil,
        subcategory: nil,
        aliases: ["everything bagel topping", "everything bagel spice", "everything seasoning"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "farfalle",
        display_name: "Farfalle",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fava beans",
        display_name: "Fava Beans",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fenugreek leaves",
        display_name: "Fenugreek Leaves",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fenugreek seeds",
        display_name: "Fenugreek Seeds",
        category: nil,
        subcategory: nil,
        aliases: ["fenugreek seed", "methi seeds"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fernet branca",
        display_name: "Fernet Branca",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fettuccine",
        display_name: "Fettuccine",
        category: nil,
        subcategory: nil,
        aliases: ["fettuccini", "fettucine"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "flatbread",
        display_name: "Flatbread",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fleur de sel",
        display_name: "Fleur De Sel",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fontina",
        display_name: "Fontina",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "frangipane",
        display_name: "Frangipane",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "french dressing",
        display_name: "French Dressing",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fresh okra",
        display_name: "Fresh Okra",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "fusilli",
        display_name: "Fusilli",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "garlic powder",
        display_name: "Garlic Powder",
        category: "spice",
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "garnet yams",
        display_name: "Garnet Yams",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "gin",
        display_name: "Gin",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "gingersnap cookie",
        display_name: "Gingersnap Cookie",
        category: nil,
        subcategory: nil,
        aliases: ["gingersnap cookies", "gingersnaps", "gingersnap"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "golden raisin",
        display_name: "Golden Raisin",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "golden syrup",
        display_name: "Golden Syrup",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "gouda",
        display_name: "Gouda",
        category: nil,
        subcategory: nil,
        aliases: ["gouda cheese", "smoked gouda"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "grapefruit juice",
        display_name: "Grapefruit Juice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "green chartreuse",
        display_name: "Green Chartreuse",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "green chile",
        display_name: "Green Chile",
        category: nil,
        subcategory: nil,
        aliases: ["green chilies", "green chiles", "green chili"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "grenadine",
        display_name: "Grenadine",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "ground cloves",
        display_name: "Ground Cloves",
        category: nil,
        subcategory: nil,
        aliases: ["ground clove"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "ground fenugreek",
        display_name: "Ground Fenugreek",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "ground veal",
        display_name: "Ground Veal",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "guacamole",
        display_name: "Guacamole",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "haddock",
        display_name: "Haddock",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "halloumi",
        display_name: "Halloumi",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "hemp seeds",
        display_name: "Hemp Seeds",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "horseradish",
        display_name: "Horseradish",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "ice",
        display_name: "Ice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "instant clearjel",
        display_name: "Instant Clearjel",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "italian salad dressing",
        display_name: "Italian Salad Dressing",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "jackfruit",
        display_name: "Jackfruit",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "japanese eggplant",
        display_name: "Japanese Eggplant",
        category: nil,
        subcategory: nil,
        aliases: ["japanese eggplants"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "jicama",
        display_name: "Jicama",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "kabocha squash",
        display_name: "Kabocha Squash",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "kahlua",
        display_name: "Kahlua",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "kirsch",
        display_name: "Kirsch",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "kiwi",
        display_name: "Kiwi",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "lard",
        display_name: "Lard",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "lemongrass",
        display_name: "Lemongrass",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "light brown sugar",
        display_name: "Light Brown Sugar",
        category: "sweetener",
        subcategory: nil,
        aliases: ["golden brown sugar"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "lima beans",
        display_name: "Lima Beans",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "liquid smoke",
        display_name: "Liquid Smoke",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "macadamia nut",
        display_name: "Macadamia Nut",
        category: nil,
        subcategory: nil,
        aliases: ["macadamia nuts", "raw macadamia nuts", "macadamia"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "maca powder",
        display_name: "Maca Powder",
        category: nil,
        subcategory: nil,
        aliases: ["maca"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "mace",
        display_name: "Mace",
        category: nil,
        subcategory: nil,
        aliases: ["ground mace", "blade of mace"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "mahi mahi",
        display_name: "Mahi Mahi",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "marinara sauce",
        display_name: "Marinara Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "mezcal",
        display_name: "Mezcal",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "microgreens",
        display_name: "Microgreens",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "mixed greens",
        display_name: "Mixed Greens",
        category: nil,
        subcategory: nil,
        aliases: ["spring greens", "baby salad greens", "salad greens"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "nigella seeds",
        display_name: "Nigella Seeds",
        category: nil,
        subcategory: nil,
        aliases: ["nigella seed", "black seed", "kalonji"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "nilla wafers",
        display_name: "Nilla Wafers",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "non-diastatic malt powder",
        display_name: "Non-diastatic Malt Powder",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "nori",
        display_name: "Nori",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "oat bran",
        display_name: "Oat Bran",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "okra",
        display_name: "Okra",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "old bay seasoning",
        display_name: "Old Bay Seasoning",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "oyster crackers",
        display_name: "Oyster Crackers",
        category: nil,
        subcategory: nil,
        aliases: ["oyster cracker"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "peach pie filling",
        display_name: "Peach Pie Filling",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pea shoots",
        display_name: "Pea Shoots",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "peppadew pepper",
        display_name: "Peppadew Pepper",
        category: nil,
        subcategory: nil,
        aliases: ["peppadew peppers", "peppadew"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "peppercorns",
        display_name: "Peppercorns",
        category: nil,
        subcategory: nil,
        aliases: ["whole peppercorns"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pepperoni",
        display_name: "Pepperoni",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pesto",
        display_name: "Pesto",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pico de gallo",
        display_name: "Pico De Gallo",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pine nuts",
        display_name: "Pine Nuts",
        category: nil,
        subcategory: nil,
        aliases: ["pine nut"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pinto beans",
        display_name: "Pinto Beans",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pizza sauce",
        display_name: "Pizza Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pomegranate",
        display_name: "Pomegranate",
        category: "produce",
        subcategory: nil,
        aliases: ["arils", "pomegranate arils", "pomegranate seeds"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: ["vegetarian", "vegan", "gluten_free", "paleo"]
      },
      %{
        name: "pomegranate juice",
        display_name: "Pomegranate Juice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "popped popcorn",
        display_name: "Popped Popcorn",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "poppy seeds",
        display_name: "Poppy Seeds",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "port",
        display_name: "Port",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "prosecco",
        display_name: "Prosecco",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "provolone",
        display_name: "Provolone",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "pumpkin pie spice",
        display_name: "Pumpkin Pie Spice",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "ramps",
        display_name: "Ramps",
        category: nil,
        subcategory: nil,
        aliases: ["ramp", "wild ramps", "wild leek"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "raw sunflower seeds",
        display_name: "Raw Sunflower Seeds",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "red food coloring",
        display_name: "Red Food Coloring",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "refried beans",
        display_name: "Refried Beans",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "rhubarb",
        display_name: "Rhubarb",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "romaine lettuce",
        display_name: "Romaine Lettuce",
        category: nil,
        subcategory: nil,
        aliases: ["romaine", "romaine heart", "romaine hearts"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "roti",
        display_name: "Roti",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "russian salad dressing",
        display_name: "Russian Salad Dressing",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "safflower oil",
        display_name: "Safflower Oil",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "saltine crackers",
        display_name: "Saltine Crackers",
        category: nil,
        subcategory: nil,
        aliases: ["saltine cracker", "saltines", "soda crackers"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "schmaltz",
        display_name: "Schmaltz",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "shortening",
        display_name: "Shortening",
        category: nil,
        subcategory: nil,
        aliases: ["vegetable shortening"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "sichuan peppercorns",
        display_name: "Sichuan Peppercorns",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "splenda",
        display_name: "Splenda",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "stevia",
        display_name: "Stevia",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "sultanas",
        display_name: "Sultanas",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "summer squash",
        display_name: "Summer Squash",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "sunflower oil",
        display_name: "Sunflower Oil",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "sweet relish",
        display_name: "Sweet Relish",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "swiss chard",
        display_name: "Swiss Chard",
        category: nil,
        subcategory: nil,
        aliases: ["chard", "rainbow chard", "red chard"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "tamari",
        display_name: "Tamari",
        category: nil,
        subcategory: nil,
        aliases: ["tamari/soy sauce", "tamari soy sauce"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "tangerine",
        display_name: "Tangerine",
        category: nil,
        subcategory: nil,
        aliases: ["tangerines", "clementine", "clementines"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "tapioca starch",
        display_name: "Tapioca Starch",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "taro",
        display_name: "Taro",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "teriyaki sauce",
        display_name: "Teriyaki Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "thousand island dressing",
        display_name: "Thousand Island Dressing",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "toor dal",
        display_name: "Toor Dal",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "tzatziki",
        display_name: "Tzatziki",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "unsweetened coconut flakes",
        display_name: "Unsweetened Coconut Flakes",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "urad dal",
        display_name: "Urad Dal",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "vanilla protein powder",
        display_name: "Vanilla Protein Powder",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "veal",
        display_name: "Veal",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "vegetable shortening",
        display_name: "Vegetable Shortening",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "wasabi",
        display_name: "Wasabi",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "watermelon",
        display_name: "Watermelon",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "wheat bran",
        display_name: "Wheat Bran",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "whipped topping",
        display_name: "Whipped Topping",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "white hominy",
        display_name: "White Hominy",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "whole cloves",
        display_name: "Whole Cloves",
        category: nil,
        subcategory: nil,
        aliases: ["clove", "whole clove"],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "worchestire sauce",
        display_name: "Worchestire Sauce",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "yellow cake mix",
        display_name: "Yellow Cake Mix",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "yellow chartreuse",
        display_name: "Yellow Chartreuse",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "yellow squash",
        display_name: "Yellow Squash",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      },
      %{
        name: "yellow summer squash",
        display_name: "Yellow Summer Squash",
        category: nil,
        subcategory: nil,
        aliases: [],
        is_allergen: false,
        allergen_groups: [],
        dietary_flags: []
      }
    ]

    for ing <- ingredients do
      name = escape_sql(ing.name)
      display_name = escape_sql(ing.display_name)
      category = if ing.category, do: "'#{escape_sql(ing.category)}'", else: "NULL"
      subcategory = if ing.subcategory, do: "'#{escape_sql(ing.subcategory)}'", else: "NULL"
      aliases_sql = format_array(ing.aliases)
      allergen_sql = format_array(ing.allergen_groups)
      dietary_sql = format_array(ing.dietary_flags)

      execute """
      INSERT INTO canonical_ingredients (id, name, display_name, category, subcategory, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        '#{name}',
        '#{display_name}',
        #{category},
        #{subcategory},
        ARRAY[#{aliases_sql}]::varchar[],
        #{ing.is_allergen},
        ARRAY[#{allergen_sql}]::varchar[],
        ARRAY[#{dietary_sql}]::varchar[],
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO UPDATE SET
        display_name = EXCLUDED.display_name,
        category = COALESCE(EXCLUDED.category, canonical_ingredients.category),
        subcategory = COALESCE(EXCLUDED.subcategory, canonical_ingredients.subcategory),
        aliases = EXCLUDED.aliases,
        is_allergen = EXCLUDED.is_allergen,
        allergen_groups = EXCLUDED.allergen_groups,
        dietary_flags = EXCLUDED.dietary_flags,
        updated_at = EXCLUDED.updated_at
      """
    end
  end

  def down do
    # List of ingredient names added by this migration
    names = [
      "absinthe", "adobo sauce", "alfredo sauce", "angostura bitters", "aperol",
      "apple juice concentrate", "apple pie spice", "applesauce", "arrowroot",
      "baby lima beans", "bamboo shoots", "barbecue sauce", "bisquick",
      "bisquick baking mix", "bouillon paste", "broccolini", "brownie mix",
      "burrata", "butterscotch chips", "cajun seasoning", "canola oil", "caramel",
      "caraway seeds", "chambord", "champagne", "cheese tortellini",
      "cherry pie filling", "chia seeds", "chili crisp", "chili-garlic sauce",
      "chili oil", "chocolate cake mix", "chocolate syrup", "clam juice",
      "coconut extract", "coconut flakes", "coleslaw mix", "collard greens",
      "cornbread", "cornichons", "crabmeat", "cranberry juice", "crisco",
      "croutons", "curacao", "currants", "dark brown sugar", "dark chocolate",
      "delicata squash", "diastatic malt powder", "dried hibiscus flowers",
      "edible flowers", "everything bagel seasoning", "farfalle", "fava beans",
      "fenugreek leaves", "fenugreek seeds", "fernet branca", "fettuccine",
      "flatbread", "fleur de sel", "fontina", "frangipane", "french dressing",
      "fresh okra", "fusilli", "garlic powder", "garnet yams", "gin",
      "gingersnap cookie", "golden raisin", "golden syrup", "gouda",
      "grapefruit juice", "green chartreuse", "green chile", "grenadine",
      "ground cloves", "ground fenugreek", "ground veal", "guacamole", "haddock",
      "halloumi", "hemp seeds", "horseradish", "ice", "instant clearjel",
      "italian salad dressing", "jackfruit", "japanese eggplant", "jicama",
      "kabocha squash", "kahlua", "kirsch", "kiwi", "lard", "lemongrass",
      "light brown sugar", "lima beans", "liquid smoke", "macadamia nut",
      "maca powder", "mace", "mahi mahi", "marinara sauce", "mezcal",
      "microgreens", "mixed greens", "nigella seeds", "nilla wafers",
      "non-diastatic malt powder", "nori", "oat bran", "okra", "old bay seasoning",
      "oyster crackers", "peach pie filling", "pea shoots", "peppadew pepper",
      "peppercorns", "pepperoni", "pesto", "pico de gallo", "pine nuts",
      "pinto beans", "pizza sauce", "pomegranate", "pomegranate juice",
      "popped popcorn", "poppy seeds", "port", "prosecco", "provolone",
      "pumpkin pie spice", "ramps", "raw sunflower seeds", "red food coloring",
      "refried beans", "rhubarb", "romaine lettuce", "roti", "russian salad dressing",
      "safflower oil", "saltine crackers", "schmaltz", "shortening",
      "sichuan peppercorns", "splenda", "stevia", "sultanas", "summer squash",
      "sunflower oil", "sweet relish", "swiss chard", "tamari", "tangerine",
      "tapioca starch", "taro", "teriyaki sauce", "thousand island dressing",
      "toor dal", "tzatziki", "unsweetened coconut flakes", "urad dal",
      "vanilla protein powder", "veal", "vegetable shortening", "wasabi",
      "watermelon", "wheat bran", "whipped topping", "white hominy",
      "whole cloves", "worchestire sauce", "yellow cake mix", "yellow chartreuse",
      "yellow squash", "yellow summer squash"
    ]

    for name <- names do
      execute "DELETE FROM canonical_ingredients WHERE name = '#{escape_sql(name)}'"
    end
  end

  defp format_array([]), do: ""
  defp format_array(items) do
    items
    |> Enum.map(&"'#{escape_sql(&1)}'")
    |> Enum.join(", ")
  end

  defp escape_sql(str) when is_binary(str), do: String.replace(str, "'", "''")
  defp escape_sql(nil), do: ""
end
