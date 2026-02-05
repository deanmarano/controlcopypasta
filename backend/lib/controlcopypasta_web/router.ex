defmodule ControlcopypastaWeb.Router do
  use ControlcopypastaWeb, :router

  alias ControlcopypastaWeb.Plugs.Auth

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check endpoint (no auth required)
  scope "/api", ControlcopypastaWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Auth
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug Auth
    plug :require_auth
  end

  pipeline :api_admin do
    plug :accepts, ["json"]
    plug Auth
    plug :require_auth
    plug ControlcopypastaWeb.Plugs.AdminAuth
  end

  defp require_auth(conn, _opts), do: Auth.require_auth(conn, [])

  # Public auth endpoints
  scope "/api/auth", ControlcopypastaWeb do
    pipe_through :api

    post "/magic-link", AuthController, :request_magic_link
    post "/magic-link/verify", AuthController, :verify_magic_link

    # Public passkey endpoints (for authentication)
    post "/passkeys/authenticate/options", PasskeyController, :authenticate_options
    post "/passkeys/authenticate", PasskeyController, :authenticate
  end

  # Auth endpoints that need optional auth
  scope "/api/auth", ControlcopypastaWeb do
    pipe_through :api_auth

    post "/refresh", AuthController, :refresh
    post "/logout", AuthController, :logout
    get "/me", AuthController, :me
  end

  # Authenticated passkey management endpoints
  scope "/api/auth/passkeys", ControlcopypastaWeb do
    pipe_through :api_authenticated

    post "/register/options", PasskeyController, :register_options
    post "/register", PasskeyController, :register
    get "/", PasskeyController, :index
    delete "/:id", PasskeyController, :delete
  end

  # Public API endpoints (no auth required)
  scope "/api", ControlcopypastaWeb do
    pipe_through :api

    # Domain screenshots (public for <img> tags)
    get "/browse/domains/:domain/screenshot", BrowseController, :domain_screenshot
  end

  # Protected API endpoints (require authentication)
  scope "/api", ControlcopypastaWeb do
    pipe_through :api_authenticated

    resources "/recipes", RecipeController, except: [:new, :edit]
    post "/recipes/parse", RecipeController, :parse
    post "/recipes/:id/archive", RecipeController, :archive
    post "/recipes/:id/unarchive", RecipeController, :unarchive
    get "/recipes/:id/similar", RecipeController, :similar
    get "/recipes/:id/compare/:compare_id", RecipeController, :compare
    get "/recipes/:id/nutrition", RecipeController, :nutrition
    get "/recipes/:id/decisions", RecipeController, :list_decisions
    post "/recipes/:id/decisions", RecipeController, :save_decision
    delete "/recipes/:id/decisions", RecipeController, :clear_decisions
    delete "/recipes/:id/decisions/:ingredient_index", RecipeController, :delete_decision

    resources "/tags", TagController, only: [:index, :create, :delete]

    # Avoided ingredients
    resources "/avoided-ingredients", AvoidedIngredientController, only: [:index, :create, :delete]
    get "/avoided-ingredients/options", AvoidedIngredientController, :options
    get "/avoided-ingredients/:id/ingredients", AvoidedIngredientController, :show_ingredients
    post "/avoided-ingredients/:id/exceptions", AvoidedIngredientController, :add_exception
    delete "/avoided-ingredients/:id/exceptions/:canonical_ingredient_id", AvoidedIngredientController, :remove_exception

    # Settings / Preferences
    get "/settings/preferences", SettingsController, :show_preferences
    put "/settings/preferences", SettingsController, :update_preferences

    # Ingredients catalog and scaling
    get "/ingredients", IngredientController, :index
    get "/ingredients/:id", IngredientController, :show
    post "/ingredients/lookup", IngredientController, :lookup
    post "/ingredients/scale", IngredientController, :scale
    post "/ingredients/scale_bulk", IngredientController, :scale_bulk
    get "/ingredients/:id/package_sizes", IngredientController, :package_sizes

    # Browse recipes by domain
    get "/browse/domains", BrowseController, :domains
    get "/browse/domains/:domain", BrowseController, :recipes_by_domain
    get "/browse/domains/:domain/recipes/:id", BrowseController, :show_recipe
    get "/browse/domains/:domain/recipes/:id/nutrition", BrowseController, :nutrition

    # Import endpoints
    post "/import/copymethat", ImportController, :copy_me_that

    # Shopping lists
    resources "/shopping-lists", ShoppingListController, except: [:new, :edit]
    post "/shopping-lists/:id/archive", ShoppingListController, :archive
    post "/shopping-lists/:id/clear-checked", ShoppingListController, :clear_checked
    post "/shopping-lists/:id/add-recipe", ShoppingListController, :add_recipe

    # Shopping list items
    post "/shopping-lists/:id/items", ShoppingListController, :create_item
    put "/shopping-lists/:id/items/:item_id", ShoppingListController, :update_item
    delete "/shopping-lists/:id/items/:item_id", ShoppingListController, :delete_item
    post "/shopping-lists/:id/items/:item_id/check", ShoppingListController, :check_item
    post "/shopping-lists/:id/items/:item_id/uncheck", ShoppingListController, :uncheck_item
  end

  # Admin endpoints (require admin role)
  scope "/api", ControlcopypastaWeb do
    pipe_through :api_admin

    # Ingredient management
    get "/admin/ingredients", Admin.IngredientController, :index
    get "/admin/ingredients/options", Admin.IngredientController, :options
    post "/admin/ingredients/test-scorer", Admin.IngredientController, :test_scorer
    get "/admin/ingredients/:id", Admin.IngredientController, :show
    put "/admin/ingredients/:id", Admin.IngredientController, :update

    # Preparation management
    get "/admin/preparations", Admin.PreparationController, :index
    get "/admin/preparations/options", Admin.PreparationController, :options
    post "/admin/preparations", Admin.PreparationController, :create
    get "/admin/preparations/:id", Admin.PreparationController, :show
    put "/admin/preparations/:id", Admin.PreparationController, :update
    delete "/admin/preparations/:id", Admin.PreparationController, :delete

    # Kitchen tool management
    get "/admin/kitchen-tools", Admin.KitchenToolController, :index
    get "/admin/kitchen-tools/options", Admin.KitchenToolController, :options
    post "/admin/kitchen-tools", Admin.KitchenToolController, :create
    get "/admin/kitchen-tools/:id", Admin.KitchenToolController, :show
    put "/admin/kitchen-tools/:id", Admin.KitchenToolController, :update
    delete "/admin/kitchen-tools/:id", Admin.KitchenToolController, :delete

    # Scraper management
    get "/admin/scraper/domains", Admin.ScraperController, :domains
    post "/admin/scraper/domains", Admin.ScraperController, :add_domain
    get "/admin/scraper/queue", Admin.ScraperController, :queue_stats
    get "/admin/scraper/rate-limits", Admin.ScraperController, :rate_limits
    post "/admin/scraper/pause", Admin.ScraperController, :pause
    post "/admin/scraper/resume", Admin.ScraperController, :resume
    get "/admin/scraper/failed", Admin.ScraperController, :failed
    post "/admin/scraper/retry-failed", Admin.ScraperController, :retry_failed
    post "/admin/scraper/domains/:domain/screenshot", Admin.ScraperController, :capture_screenshot
    get "/admin/scraper/browser-status", Admin.ScraperController, :browser_status
    get "/admin/scraper/workers", Admin.ScraperController, :executing_workers
    post "/admin/scraper/parse-ingredients", Admin.ScraperController, :parse_ingredients
    get "/admin/scraper/parsing-stats", Admin.ScraperController, :parsing_stats
    post "/admin/scraper/reset-stale", Admin.ScraperController, :reset_stale

    # Ingredient enrichment
    get "/admin/scraper/ingredient-enrichment", Admin.ScraperController, :ingredient_enrichment_stats
    post "/admin/scraper/enqueue-nutrition", Admin.ScraperController, :enqueue_nutrition_enrichment
    post "/admin/scraper/enqueue-density", Admin.ScraperController, :enqueue_density_enrichment
    post "/admin/scraper/resume-nutrition", Admin.ScraperController, :resume_nutrition_enrichment
    post "/admin/scraper/resume-density", Admin.ScraperController, :resume_density_enrichment
    post "/admin/scraper/enqueue-nutrition-all-sources", Admin.ScraperController, :enqueue_nutrition_all_sources

    # Pending ingredients review
    get "/admin/pending-ingredients", Admin.PendingIngredientController, :index
    get "/admin/pending-ingredients/stats", Admin.PendingIngredientController, :stats
    post "/admin/pending-ingredients/scan", Admin.PendingIngredientController, :scan
    get "/admin/pending-ingredients/:id", Admin.PendingIngredientController, :show
    put "/admin/pending-ingredients/:id", Admin.PendingIngredientController, :update
    post "/admin/pending-ingredients/:id/approve", Admin.PendingIngredientController, :approve
    post "/admin/pending-ingredients/:id/reject", Admin.PendingIngredientController, :reject
    post "/admin/pending-ingredients/:id/merge", Admin.PendingIngredientController, :merge
    post "/admin/pending-ingredients/:id/preparation", Admin.PendingIngredientController, :mark_as_preparation
    post "/admin/pending-ingredients/:id/tool", Admin.PendingIngredientController, :mark_as_tool
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:controlcopypasta, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ControlcopypastaWeb.Telemetry
    end
  end
end
