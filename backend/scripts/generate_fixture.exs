# Script to generate CMT fixture from actual parsed data
# All URLs from CMT scrape (excluding YouTube)
urls = [
  "https://basicswithbabish.co/basicsepisodes/friedrice",
  "https://cookieandkate.com/pasta-e-fagioli-recipe/",
  "https://cooking.nytimes.com/recipes/1019681-cheesy-white-bean-tomato-bake",
  "https://cooking.nytimes.com/recipes/1025764-potato-leek-soup",
  "https://culinaryginger.com/cheese-tortellini/",
  "https://cupcakesandkalechips.com/strawberry-cheesecake-frozen-yogurt-popsicles/",
  "https://eatwithclarity.com/sticky-sesame-chickpeas/",
  "https://food52.com/recipes/9993-beet-ravioli-with-goat-cheese-ricotta-and-mint-filling",
  "https://healthynibblesandbits.com/easiest-egg-fried-rice/",
  "https://jas1092.wordpress.com/2014/08/23/grilled-halloumi-salad/",
  "https://kirbiecravings.com/japanese-souffle-pancakes/",
  "https://maureenabood.com/simple-raspberry-jam-recipe/",
  "https://minimalistbaker.com/butternut-squash-miso-brussels-sprouts-nourish-bowl/",
  "https://minimalistbaker.com/cornbread-black-bean-enchilada-bake/",
  "https://minimalistbaker.com/easy-chana-masala/",
  "https://minimalistbaker.com/zucchini-pasta-with-lentil-bolognese/",
  "https://pastaevangelists.com/blogs/blog/how-to-make-orecchiette-pasta-recipe",
  "https://pinchandswirl.com/homemade-tonic-water-for-the-ultimate-gin-and-tonic/",
  "https://pinchofyum.com/30-minute-meal-prep-roasted-vegetable-bowls-with-green-tahini",
  "https://pinchofyum.com/fall-favorite-maple-mustard-tempeh-bowls",
  "https://pinchofyum.com/green-curry-scallops",
  "https://pinchofyum.com/mushroom-bowls-with-kale-pesto",
  "https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw",
  "https://pinchofyum.com/summery-chipotle-corn-chowder",
  "https://recipetamia.com/recipes/spicy-chocolate-drink-chilcacahuatl/",
  "https://senseandedibility.com/cucumber-mint-lime-popsicles/",
  "https://seonkyounglongest.com/mayak-eggs/",
  "https://spainonafork.com/chickpea-meatballs-in-tomato-sauce-recipe/",
  "https://spainonafork.com/classic-spanish-lentil-stew-recipe/",
  "https://spanishsabores.com/best-spanish-omelet-recipe/",
  "https://thedefineddish.com/grain-free-nutella-brownies/",
  "https://theelliotthomestead.com/2021/09/fermented-hot-sauce/",
  "https://thefirstmess.com/2023/09/06/baked-pearl-couscous-with-butternut-squash-basil-tahini/",
  "https://thesourdoughbaker.com/recipe/english-muffins/",
  "https://thetakeout.com/recipe-caramelized-mushroom-pasta-with-miso-and-sage-1846368039",
  "https://thetakeout.com/recipe-salted-oatmeal-butterscotch-cookies-1845803611",
  "https://theviewfromgreatisland.com/finnish-salmon-soup-lohikeitto-recipe/",
  "https://us.gozney.com/blogs/recipes/easy-foolproof-flatbread-recipe",
  "https://veenaazmanov.com/brioche-pullman-loaf-recipe/",
  "https://veganheaven.org/recipe/spinach-artichoke-pasta/",
  "https://wickedhealthyfood.com/2020/07/16/mushroom-shawarma/",
  "https://www.allrecipes.com/recipe/24717/vegetarian-shepherds-pie-ii/",
  "https://www.allrecipes.com/recipe/38410/strawberry-jam/",
  "https://www.ambitiouskitchen.com/best-homemade-healthy-sandwich-bread-recipe/",
  "https://www.ambitiouskitchen.com/curry-chickpea-salad-wraps/",
  "https://www.bacardi.com/culture/the-famous-bacardi-rum-cake/",
  "https://www.bonappetit.com/recipe/pasta-al-limone",
  "https://www.bonappetit.com/recipe/roasted-salmon-salsa-verde",
  "https://www.bonappetit.com/recipe/sesame-tofu-with-broccoli",
  "https://www.bonappetit.com/recipe/soy-glazed-tofu-and-mushrooms",
  "https://www.bonappetit.com/recipe/spicy-shrimp-pilaf",
  "https://www.bonappetit.com/recipe/vegetarian-green-curry",
  "https://www.budgetbytes.com/tempeh-burrito-bowls/",
  "https://www.charlieandersoncooking.com/recipes/artisan-cheesesteak-rolls",
  "https://www.delish.com/cooking/recipe-ideas/a25325036/how-to-make-fried-rice/",
  "https://www.epicurious.com/recipes/food/views/bombay-toasties-masala-chile-cheese-tara-obrady",
  "https://www.epicurious.com/recipes/food/views/homemade-baked-tofu",
  "https://www.epicurious.com/recipes/food/views/old-fashioned-raspberry-jam-230700",
  "https://www.fabfood4all.co.uk/peach-apricot-jam/",
  "https://www.feastingathome.com/stuffed-shells/",
  "https://www.food.com/recipe/slovenian-traditional-prekmurska-gibanica-412339",
  "https://www.food.com/recipe/split-pea-soup-with-tempeh-bacon-and-chipotle-cream-423276",
  "https://www.foodnetwork.com/recipes/food-network-kitchen/waffled-falafel-recipe-3361890",
  "https://www.foodnetwork.com/recipes/giada-de-laurentiis/baked-penne-with-roasted-vegetables-recipe-1916906",
  "https://www.forksoverknives.com/recipes/vegan-soups-stews/best-ever-beefless-stew/",
  "https://www.halfbakedharvest.com/brown-butter-lobster-ravioli/",
  "https://www.halfbakedharvest.com/greek-watermelon-feta-salad/",
  "https://www.healthygreenkitchen.com/bircher-muesli/",
  "https://www.howsweeteats.com/2022/02/tortilla-pizza-pepperoni-chickpeas/",
  "https://www.huffpost.com/entry/chickpea-soup-the-best-it_b_6429696",
  "https://www.justataste.com/quick-and-easy-skillet-brownie-recipe/",
  "https://www.kingarthurbaking.com/blog/2008/12/26/a-toast-for-the-new-year",
  "https://www.kingarthurbaking.com/recipes/a-smaller-100-whole-wheat-pain-de-mie-recipe",
  "https://www.kingarthurbaking.com/recipes/a-smaller-pain-de-mie-recipe",
  "https://www.kingarthurbaking.com/recipes/beautiful-burger-buns-recipe",
  "https://www.kingarthurbaking.com/recipes/simple-raspberry-jam-recipe",
  "https://www.loveandlemons.com/carrot-ginger-soup/",
  "https://www.loveandlemons.com/greek-salad/",
  "https://www.mybakingaddiction.com/mint-chocolate-cookies-recipe/",
  "https://www.olgasflavorfactory.com/recipes/weeknight-dinners/potato-waffles/",
  "https://www.oliviascuisine.com/brazilian-camarao-na-moranga/",
  "https://www.onceuponachef.com/recipes/chocolate-caramel-shortbread-squares-a-k-a-millionaires-shortbread.html?recipe_print=yes",
  "https://www.seriouseats.com/concord-grape-jam-recipe-grape-jelly",
  "https://www.seriouseats.com/kimchi-fried-rice-recipe",
  "https://www.seriouseats.com/miso-glazed-salmon-in-the-toaster-oven-recipe",
  "https://www.seriouseats.com/model-bakery-napa-english-muffin-recipe",
  "https://www.seriouseats.com/strawberry-popsicles",
  "https://www.seriouseats.com/virgin-pina-colada-popsicles",
  "https://www.sigsbeestreet.co/recipe/fettuccine-pasta-recipe",
  "https://www.simpleitaliancooking.com/anise-pizzelle/",
  "https://www.skinnytaste.com/protein-cookies/",
  "https://www.skinnytaste.com/whipped-ricotta-toast-with-roasted-tomatoes/",
  "https://www.tasteofhome.com/recipes/mushroom-barley-soup-2/",
  "https://www.tastingtable.com/1201903/frico-italys-cheesy-potato-filled-comfort-food/",
  "https://www.thekitchn.com/i-tried-pasta-queens-rebellious-carbonara-23232156",
  "https://www.thesaturdaypaper.com.au/2021/06/30/pumpkin-stuffed-with-farro-chestnut-and-mushrooms/162281520011790#mtr",
  "https://www.theseasonedmom.com/ravioli-lasagna/",
  "https://www.thespruceeats.com/original-sicilian-style-pizza-2018150",
  "https://www.triedandtruerecipe.com/2021/01/29/pasta-and-chickpeas-with-harissa/",
  "https://www.yummytoddlerfood.com/pastina-pasta/",
  "http://www.tinyfarmhouse.com/2009/02/a-ravioli-primer-artichoke-ravioli-in-a-lemon-cream-sauce/"
]

recipes = Enum.map(urls, fn url ->
  IO.puts("Parsing: #{url}")
  case Controlcopypasta.Parser.parse_url(url) do
    {:ok, parsed} ->
      %{
        "name" => parsed[:title],
        "url" => url,
        "description" => parsed[:description],
        "image" => parsed[:image_url],
        "ingredients" => Enum.map(parsed[:ingredients] || [], fn
          %{"text" => t} -> t
          t when is_binary(t) -> t
          _ -> ""
        end),
        "instructions" => Enum.map_join(parsed[:instructions] || [], "\n", fn
          %{"text" => t} -> t
          t when is_binary(t) -> t
          _ -> ""
        end),
        "prepTime" => if(parsed[:prep_time_minutes], do: "#{parsed[:prep_time_minutes]} mins", else: nil),
        "cookTime" => if(parsed[:cook_time_minutes], do: "#{parsed[:cook_time_minutes]} mins", else: nil),
        "totalTime" => if(parsed[:total_time_minutes], do: "#{parsed[:total_time_minutes]} mins", else: nil),
        "yield" => parsed[:servings],
        "tags" => []
      }
    {:error, e} ->
      IO.puts("  Error: #{inspect(e)}")
      nil
  end
end)
|> Enum.reject(&is_nil/1)

json = Jason.encode!(recipes, pretty: true)
File.write!("test/fixtures/cmt_export.json", json)
IO.puts("\nSaved #{length(recipes)} recipes to fixture")
