defmodule Controlcopypasta.Repo.Migrations.SetMeasurementTypesForCanonicalIngredients do
  use Ecto.Migration

  def up do
    # Set measurement_type for liquid ingredients (water-based, ~1g/ml density)
    # These can use water density as a reasonable approximation
    execute """
    UPDATE canonical_ingredients
    SET measurement_type = 'liquid'
    WHERE name IN (
      -- Vinegars
      'rice vinegar', 'white vinegar', 'red wine vinegar', 'balsamic vinegar',
      'apple cider vinegar', 'sherry vinegar', 'champagne vinegar', 'malt vinegar',
      'distilled white vinegar', 'cider vinegar', 'white wine vinegar',
      -- Asian cooking wines and sauces
      'mirin', 'sake', 'rice wine', 'cooking wine', 'sherry', 'shaoxing wine',
      'soy sauce', 'fish sauce', 'worcestershire sauce', 'worcestershire',
      'coconut aminos', 'tamari', 'oyster sauce', 'hoisin sauce',
      -- Broths and stocks
      'broth', 'stock', 'vegetable broth', 'chicken broth', 'beef broth',
      'vegetable stock', 'chicken stock', 'beef stock', 'bone broth',
      -- Alcoholic beverages (used in cooking)
      'lager', 'beer', 'ale', 'stout', 'wine', 'white wine', 'red wine',
      'prosecco', 'champagne', 'cava', 'marsala', 'madeira', 'port',
      'dry white wine', 'dry red wine', 'cooking sherry',
      -- Spirits (used in cooking)
      'campari', 'aperol', 'mezcal', 'calvados', 'amaro', 'absinthe',
      'rum', 'vodka', 'gin', 'whiskey', 'bourbon', 'brandy', 'cognac',
      'grand marnier', 'kahlua', 'amaretto', 'frangelico', 'triple sec',
      -- Juices
      'juice', 'orange juice', 'lemon juice', 'lime juice', 'apple juice',
      'grape juice', 'cranberry juice', 'pineapple juice', 'tomato juice',
      'pomegranate juice', 'grapefruit juice', 'carrot juice',
      -- Water and water-based beverages
      'water', 'coconut water', 'seltzer', 'club soda', 'sparkling water',
      'tonic water', 'mineral water',
      -- Dairy liquids
      'milk', 'buttermilk', 'cream', 'half and half', 'heavy cream',
      'light cream', 'whipping cream', 'whole milk', 'skim milk',
      '2% milk', '1% milk', 'evaporated milk', 'coconut milk', 'coconut cream',
      'almond milk', 'oat milk', 'soy milk', 'cashew milk', 'rice milk',
      -- Other liquid condiments
      'maple syrup', 'honey', 'agave', 'agave nectar', 'corn syrup',
      'molasses', 'golden syrup', 'simple syrup'
    )
    """

    # Set measurement_type for weight-primary ingredients
    # These are typically sold and measured by weight, not volume
    execute """
    UPDATE canonical_ingredients
    SET measurement_type = 'weight_primary'
    WHERE name IN (
      -- Pork cuts
      'pork shoulder', 'pork tenderloin', 'pork belly', 'pork loin',
      'pork chop', 'pork chops', 'pork butt', 'pork roast',
      'ground pork', 'pork ribs', 'spare ribs', 'baby back ribs',
      -- Beef cuts
      'beef chuck', 'flank steak', 'sirloin', 'sirloin steak',
      'skirt steak', 'ribeye', 'ribeye steak', 'beef brisket', 'brisket',
      'beef tenderloin', 'filet mignon', 'new york strip', 'strip steak',
      'beef short ribs', 'short ribs', 'chuck roast', 'pot roast',
      'ground beef', 'beef stew meat', 'stew meat', 'beef roast',
      'tri-tip', 'flat iron steak', 'hanger steak', 'london broil',
      -- Chicken
      'chicken breast', 'chicken thigh', 'chicken thighs', 'chicken leg',
      'chicken drumstick', 'chicken wing', 'chicken wings', 'whole chicken',
      'ground chicken', 'chicken tender', 'chicken tenders',
      -- Other poultry
      'turkey breast', 'ground turkey', 'turkey thigh', 'turkey leg',
      'duck breast', 'duck leg', 'whole duck', 'cornish hen',
      -- Lamb and game
      'lamb chop', 'lamb chops', 'lamb shoulder', 'lamb leg', 'leg of lamb',
      'ground lamb', 'lamb shank', 'rack of lamb', 'lamb loin',
      'venison', 'ground venison', 'venison steak',
      'ground bison', 'bison steak', 'bison roast',
      -- Fish
      'salmon fillet', 'salmon', 'halibut', 'halibut fillet',
      'mahi mahi', 'mahi-mahi', 'dover sole', 'sole', 'whitefish',
      'cod', 'cod fillet', 'tilapia', 'tilapia fillet', 'trout',
      'sea bass', 'bass', 'snapper', 'red snapper', 'swordfish',
      'tuna steak', 'ahi tuna', 'salmon steak',
      'arctic char', 'branzino', 'flounder', 'catfish',
      -- Sausages
      'italian sausage', 'andouille sausage', 'andouille', 'kielbasa',
      'chorizo', 'breakfast sausage', 'sausage', 'bratwurst',
      'hot italian sausage', 'sweet italian sausage', 'chicken sausage',
      'turkey sausage', 'polish sausage',
      -- Seafood
      'shrimp', 'prawns', 'scallops', 'sea scallops', 'bay scallops',
      'lobster', 'lobster tail', 'crab', 'crab meat', 'lump crab',
      'mussels', 'clams', 'oysters', 'squid', 'calamari', 'octopus'
    )
    """

    # Also set weight_primary for ingredients in the protein category
    # that aren't already set (catch-all for meats)
    execute """
    UPDATE canonical_ingredients
    SET measurement_type = 'weight_primary'
    WHERE category = 'protein'
    AND measurement_type = 'standard'
    AND subcategory IN ('poultry', 'beef', 'pork', 'lamb', 'game', 'seafood', 'fish')
    """

    # Set measurement_type for count-primary ingredients
    # These are sold/measured per piece
    execute """
    UPDATE canonical_ingredients
    SET measurement_type = 'count_primary'
    WHERE name IN (
      -- Bread products
      'hot dog bun', 'hamburger bun', 'english muffin', 'kaiser roll', 'kaiser rolls',
      'hawaiian rolls', 'hawaiian roll', 'brioche bun', 'hoagie roll', 'sub roll',
      'ciabatta roll', 'dinner roll', 'dinner rolls', 'slider bun', 'slider buns',
      -- Prepared doughs
      'pizza dough', 'puff pastry', 'puff pastry sheet', 'phyllo dough', 'filo dough',
      'pie dough', 'pie crust', 'wonton wrapper', 'wonton wrappers', 'egg roll wrapper',
      'spring roll wrapper', 'dumpling wrapper', 'gyoza wrapper',
      -- Crackers and cookies (when used whole)
      'pretzel', 'pretzels', 'ritz cracker', 'ritz crackers', 'graham cracker',
      'gingersnap cookie', 'gingersnap', 'gingersnaps', 'ladyfinger', 'ladyfingers',
      'biscoff', 'biscoff cookie', 'oreo', 'oreo cookie',
      -- Flatbreads and wraps
      'tortilla', 'flour tortilla', 'corn tortilla', 'pita', 'pita bread',
      'naan', 'naan bread', 'lavash', 'roti', 'chapati',
      -- Specialty breads (when whole)
      'challah', 'country bread', 'baguette', 'croissant', 'bagel',
      -- Eggs
      'egg', 'eggs', 'egg yolk', 'egg yolks', 'egg white', 'egg whites',
      -- Hot dogs and similar
      'hot dog', 'hot dogs', 'frankfurter', 'frankfurters',
      -- Produce items typically sold/used by count
      'avocado', 'banana', 'apple', 'orange', 'lemon', 'lime',
      'grapefruit', 'pear', 'peach', 'nectarine', 'plum', 'apricot',
      'mango', 'papaya', 'kiwi', 'pomegranate', 'persimmon',
      'jalapeno', 'serrano', 'habanero', 'poblano', 'bell pepper',
      'onion', 'shallot', 'garlic head', 'head of garlic',
      'potato', 'sweet potato', 'yam', 'beet', 'turnip', 'parsnip',
      'carrot', 'celery stalk', 'corn cob', 'ear of corn',
      'cucumber', 'zucchini', 'eggplant', 'artichoke',
      'head of lettuce', 'head of cabbage', 'head of cauliflower',
      'bunch of cilantro', 'bunch of parsley', 'bunch of basil'
    )
    """
  end

  def down do
    # Reset all measurement_types back to standard
    execute "UPDATE canonical_ingredients SET measurement_type = 'standard'"
  end
end
