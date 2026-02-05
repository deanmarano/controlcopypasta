defmodule Controlcopypasta.Repo.Migrations.SeedKitchenTools do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    tools = [
      # From preparation metadata tools
      %{name: "knife", display_name: "Knife", category: "cutting", aliases: ["chef's knife", "kitchen knife", "paring knife"]},
      %{name: "grater", display_name: "Grater", category: "cutting", aliases: ["box grater", "cheese grater", "microplane"]},
      %{name: "whisk", display_name: "Whisk", category: "mixing", aliases: ["wire whisk", "balloon whisk"]},
      %{name: "sifter", display_name: "Sifter", category: "processing", aliases: ["flour sifter", "sieve"]},
      %{name: "masher", display_name: "Masher", category: "processing", aliases: ["potato masher"]},
      %{name: "blender", display_name: "Blender", category: "processing", aliases: ["countertop blender", "immersion blender"]},
      %{name: "zester", display_name: "Zester", category: "cutting", aliases: ["citrus zester", "lemon zester"]},
      %{name: "juicer", display_name: "Juicer", category: "processing", aliases: ["citrus juicer", "lemon squeezer"]},

      # From EquipmentDetector items
      %{name: "thermometer", display_name: "Thermometer", category: "measuring", aliases: ["meat thermometer", "instant-read thermometer", "candy thermometer"]},
      %{name: "peeler", display_name: "Peeler", category: "cutting", aliases: ["vegetable peeler", "potato peeler", "y-peeler"]},
      %{name: "strainer", display_name: "Strainer", category: "processing", aliases: ["fine-mesh strainer", "colander", "mesh sieve"]},
      %{name: "spatula", display_name: "Spatula", category: "cooking", aliases: ["rubber spatula", "silicone spatula", "turner", "flipper"]},
      %{name: "tongs", display_name: "Tongs", category: "cooking", aliases: ["kitchen tongs", "serving tongs"]},
      %{name: "mandoline", display_name: "Mandoline", category: "cutting", aliases: ["mandolin", "mandoline slicer"]},
      %{name: "food processor", display_name: "Food Processor", category: "processing", aliases: ["food chopper", "mini food processor"]},
      %{name: "stand mixer", display_name: "Stand Mixer", category: "mixing", aliases: ["kitchen aid", "kitchenaid", "electric mixer"]},
      %{name: "skewer", display_name: "Skewer", category: "cooking", aliases: ["skewers", "bamboo skewer", "metal skewer", "wooden skewer"]},
      %{name: "baking sheet", display_name: "Baking Sheet", category: "baking", aliases: ["sheet pan", "cookie sheet", "baking tray", "half sheet pan"]},
      %{name: "dutch oven", display_name: "Dutch Oven", category: "cooking", aliases: ["heavy pot", "cast iron pot", "braiser"]},
      %{name: "rolling pin", display_name: "Rolling Pin", category: "baking", aliases: ["dough roller"]},
      %{name: "measuring cup", display_name: "Measuring Cup", category: "measuring", aliases: ["measuring cups", "liquid measuring cup", "dry measuring cup"]}
    ]

    entries =
      Enum.map(tools, fn tool ->
        tool
        |> Map.put(:id, Ecto.UUID.bingenerate())
        |> Map.put(:metadata, %{})
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    repo().insert_all("kitchen_tools", entries, on_conflict: :nothing, conflict_target: :name)
  end

  def down do
    repo().delete_all("kitchen_tools")
  end
end
