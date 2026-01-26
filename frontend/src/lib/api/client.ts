// Use VITE_API_URL if set, otherwise use the same hostname as the frontend on port 4000
const API_BASE = import.meta.env.VITE_API_URL ||
  (typeof window !== 'undefined'
    ? `http://${window.location.hostname}:4000/api`
    : 'http://localhost:4000/api');

interface ApiOptions {
  method?: string;
  body?: unknown;
  token?: string | null;
}

class ApiError extends Error {
  constructor(
    public status: number,
    public data: unknown
  ) {
    super(`API Error: ${status}`);
    this.name = 'ApiError';
  }
}

async function request<T>(endpoint: string, options: ApiOptions = {}): Promise<T> {
  const { method = 'GET', body, token } = options;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}${endpoint}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new ApiError(response.status, data);
  }

  if (response.status === 204) {
    return null as T;
  }

  return response.json();
}

// Auth API
export const auth = {
  requestMagicLink: (email: string) =>
    request<{ message: string }>('/auth/magic-link', {
      method: 'POST',
      body: { email }
    }),

  verifyMagicLink: (token: string) =>
    request<{ token: string; user: { id: string; email: string } }>('/auth/magic-link/verify', {
      method: 'POST',
      body: { token }
    }),

  refresh: (token: string) =>
    request<{ token: string }>('/auth/refresh', {
      method: 'POST',
      token
    }),

  me: (token: string) =>
    request<{ user: { id: string; email: string; inserted_at: string } }>('/auth/me', {
      token
    }),

  logout: (token: string) =>
    request<{ message: string }>('/auth/logout', {
      method: 'POST',
      token
    })
};

// Passkey types
export interface Passkey {
  id: string;
  name: string;
  transports: string[];
  inserted_at: string;
}

// Registration options from server
export interface PasskeyRegistrationOptions {
  challenge: string;
  challengeToken: string;
  rp: { id: string; name: string };
  user: { id: string; name: string; displayName: string };
  pubKeyCredParams: Array<{ type: string; alg: number }>;
  timeout?: number;
  attestation?: string;
  excludeCredentials?: Array<{ id: string; type: string; transports?: string[] }>;
  authenticatorSelection?: {
    authenticatorAttachment?: string;
    residentKey?: string;
    requireResidentKey?: boolean;
    userVerification?: string;
  };
}

// Authentication options from server
export interface PasskeyAuthenticationOptions {
  challenge: string;
  challengeToken: string;
  timeout?: number;
  rpId?: string;
  allowCredentials?: Array<{ id: string; type: string; transports?: string[] }>;
  userVerification?: string;
}

// Passkeys API
export const passkeys = {
  registerOptions: (token: string) =>
    request<PasskeyRegistrationOptions>('/auth/passkeys/register/options', {
      method: 'POST',
      token
    }),

  register: (token: string, credential: unknown, challengeToken: string, name?: string, transports?: string[]) =>
    request<{ data: Passkey }>('/auth/passkeys/register', {
      method: 'POST',
      token,
      body: { ...credential as object, challengeToken, name, transports }
    }),

  authenticateOptions: (email: string) =>
    request<PasskeyAuthenticationOptions>('/auth/passkeys/authenticate/options', {
      method: 'POST',
      body: { email }
    }),

  authenticate: (credential: unknown, challengeToken: string) =>
    request<{ token: string; user: { id: string; email: string } }>('/auth/passkeys/authenticate', {
      method: 'POST',
      body: { ...credential as object, challengeToken }
    }),

  list: (token: string) =>
    request<{ data: Passkey[] }>('/auth/passkeys', { token }),

  delete: (token: string, id: string) =>
    request<null>(`/auth/passkeys/${id}`, {
      method: 'DELETE',
      token
    })
};

// Recipe types
export interface Ingredient {
  text: string;
  group: string | null;
}

export interface Instruction {
  step: number;
  text: string;
}

export interface Tag {
  id: string;
  name: string;
}

export interface AvoidedIngredientMatch {
  name: string;
  canonical: string;
  original: string;
}

export interface Recipe {
  id: string;
  title: string;
  description: string | null;
  source_url: string | null;
  source_domain: string | null;
  image_url: string | null;
  ingredients: Ingredient[];
  instructions: Instruction[];
  prep_time_minutes: number | null;
  cook_time_minutes: number | null;
  total_time_minutes: number | null;
  servings: string | null;
  notes: string | null;
  tags: Tag[];
  archived_at: string | null;
  inserted_at: string;
  updated_at: string;
  contains_avoided?: boolean;
  avoided_ingredients?: AvoidedIngredientMatch[];
}

export interface SimilarRecipe {
  recipe: Recipe;
  score: number;
  overlap_score: number;
  proportion_score: number;
  shared_ingredients: string[];
  unique_to_other: string[];
}

export interface SharedIngredient {
  name: string;
  proportion1: number;
  proportion2: number;
}

export interface UniqueIngredient {
  name: string;
  proportion: number;
}

export interface RecipeComparison {
  recipe1: Recipe;
  recipe2: Recipe;
  score: number;
  overlap_score: number;
  proportion_score: number;
  shared_ingredients: SharedIngredient[];
  only_in_first: UniqueIngredient[];
  only_in_second: UniqueIngredient[];
}

// Recipe Nutrition types

// A nutrient range with uncertainty tracking
export interface NutrientRange {
  min: number | null;
  best: number | null;
  max: number | null;
  confidence: number;
}

// Helper to extract the "best" value from a range or scalar
export function getNutrientValue(value: NutrientRange | number | null): number | null {
  if (value === null) return null;
  if (typeof value === 'number') return value;
  return value.best;
}

// Check if a value is a NutrientRange
export function isNutrientRange(value: unknown): value is NutrientRange {
  return typeof value === 'object' && value !== null &&
    'min' in value && 'best' in value && 'max' in value && 'confidence' in value;
}

// Nutrient data with range support - each nutrient can be a range or scalar
export interface NutrientData {
  calories: NutrientRange | number | null;
  protein_g: NutrientRange | number | null;
  fat_total_g: NutrientRange | number | null;
  fat_saturated_g: NutrientRange | number | null;
  carbohydrates_g: NutrientRange | number | null;
  fiber_g: NutrientRange | number | null;
  sugar_g: NutrientRange | number | null;
  sodium_mg: NutrientRange | number | null;
  cholesterol_mg: NutrientRange | number | null;
  potassium_mg: NutrientRange | number | null;
  calcium_mg: NutrientRange | number | null;
  iron_mg: NutrientRange | number | null;
  vitamin_a_mcg: NutrientRange | number | null;
  vitamin_c_mg: NutrientRange | number | null;
  vitamin_d_mcg: NutrientRange | number | null;
}

// All-range version of NutrientData for strongly-typed usage
export interface NutrientDataWithRanges {
  calories: NutrientRange | null;
  protein_g: NutrientRange | null;
  fat_total_g: NutrientRange | null;
  fat_saturated_g: NutrientRange | null;
  carbohydrates_g: NutrientRange | null;
  fiber_g: NutrientRange | null;
  sugar_g: NutrientRange | null;
  sodium_mg: NutrientRange | null;
  cholesterol_mg: NutrientRange | null;
  potassium_mg: NutrientRange | null;
  calcium_mg: NutrientRange | null;
  iron_mg: NutrientRange | null;
  vitamin_a_mcg: NutrientRange | null;
  vitamin_c_mg: NutrientRange | null;
  vitamin_d_mcg: NutrientRange | null;
}

export interface IngredientNutritionResult {
  original: string;
  status: 'calculated' | 'no_match' | 'no_quantity' | 'no_density' | 'no_nutrition' | 'error' | 'invalid';
  canonical_name: string | null;
  canonical_id: string | null;
  quantity: number | null;
  quantity_min: number | null;
  quantity_max: number | null;
  unit: string | null;
  grams: NutrientRange | number | null;
  calories: NutrientRange | number | null;
  protein_g: NutrientRange | number | null;
  carbohydrates_g: NutrientRange | number | null;
  fat_total_g: NutrientRange | number | null;
  error: string | null;
}

export interface RecipeNutrition {
  recipe_id: string;
  recipe_title: string;
  servings: number;
  completeness: number;
  total: NutrientData;
  per_serving: NutrientData;
  ingredients: IngredientNutritionResult[];
  warnings: string[];
}

export interface RecipeInput {
  title: string;
  description?: string;
  source_url?: string;
  image_url?: string;
  ingredients?: Ingredient[];
  instructions?: Instruction[];
  prep_time_minutes?: number;
  cook_time_minutes?: number;
  total_time_minutes?: number;
  servings?: string;
  notes?: string;
  tag_ids?: string[];
}

// Recipes API
export const recipes = {
  list: (token: string, params?: { q?: string; tag?: string; limit?: number; offset?: number; archived?: 'true' | 'all' }) => {
    const searchParams = new URLSearchParams();
    if (params?.q) searchParams.set('q', params.q);
    if (params?.tag) searchParams.set('tag', params.tag);
    if (params?.limit) searchParams.set('limit', params.limit.toString());
    if (params?.offset) searchParams.set('offset', params.offset.toString());
    if (params?.archived) searchParams.set('archived', params.archived);
    const query = searchParams.toString();
    return request<{ data: Recipe[] }>(`/recipes${query ? `?${query}` : ''}`, { token });
  },

  get: (token: string, id: string) =>
    request<{ data: Recipe }>(`/recipes/${id}`, { token }),

  create: (token: string, recipe: RecipeInput) =>
    request<{ data: Recipe }>('/recipes', {
      method: 'POST',
      token,
      body: { recipe }
    }),

  update: (token: string, id: string, recipe: Partial<RecipeInput>) =>
    request<{ data: Recipe }>(`/recipes/${id}`, {
      method: 'PUT',
      token,
      body: { recipe }
    }),

  delete: (token: string, id: string) =>
    request<null>(`/recipes/${id}`, {
      method: 'DELETE',
      token
    }),

  parse: (token: string, url: string) =>
    request<{ data: Omit<Recipe, 'id' | 'tags' | 'inserted_at' | 'updated_at'> }>('/recipes/parse', {
      method: 'POST',
      token,
      body: { url }
    }),

  archive: (token: string, id: string) =>
    request<{ data: Recipe }>(`/recipes/${id}/archive`, {
      method: 'POST',
      token
    }),

  unarchive: (token: string, id: string) =>
    request<{ data: Recipe }>(`/recipes/${id}/unarchive`, {
      method: 'POST',
      token
    }),

  similar: (token: string, id: string, limit?: number) => {
    const params = new URLSearchParams();
    if (limit) params.set('limit', limit.toString());
    const query = params.toString();
    return request<{ data: SimilarRecipe[] }>(`/recipes/${id}/similar${query ? `?${query}` : ''}`, { token });
  },

  compare: (token: string, id: string, compareId: string) =>
    request<{ data: RecipeComparison }>(`/recipes/${id}/compare/${compareId}`, { token }),

  nutrition: (token: string, id: string, servings?: number) => {
    const params = new URLSearchParams();
    if (servings) params.set('servings', servings.toString());
    const query = params.toString();
    return request<{ data: RecipeNutrition }>(`/recipes/${id}/nutrition${query ? `?${query}` : ''}`, { token });
  }
};

// Avoided Ingredients API
export interface AvoidedIngredient {
  id: string;
  canonical_name: string;
  display_name: string;
  inserted_at: string;
}

export const avoidedIngredients = {
  list: (token: string) =>
    request<{ data: AvoidedIngredient[] }>('/avoided-ingredients', { token }),

  create: (token: string, displayName: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: { avoided_ingredient: { display_name: displayName } }
    }),

  delete: (token: string, id: string) =>
    request<null>(`/avoided-ingredients/${id}`, {
      method: 'DELETE',
      token
    })
};

// Browse API
export interface DomainInfo {
  domain: string;
  count: number;
}

export const browse = {
  domains: (token: string) =>
    request<{ data: DomainInfo[] }>('/browse/domains', { token }),

  recipesByDomain: (token: string, domain: string, params?: { q?: string; limit?: number; offset?: number }) => {
    const searchParams = new URLSearchParams();
    if (params?.q) searchParams.set('q', params.q);
    if (params?.limit) searchParams.set('limit', params.limit.toString());
    if (params?.offset) searchParams.set('offset', params.offset.toString());
    const query = searchParams.toString();
    return request<{ data: Recipe[]; total: number }>(`/browse/domains/${encodeURIComponent(domain)}${query ? `?${query}` : ''}`, { token });
  },

  getRecipe: (token: string, domain: string, id: string) =>
    request<{ data: Recipe }>(`/browse/domains/${encodeURIComponent(domain)}/recipes/${id}`, { token }),

  nutrition: (token: string, domain: string, id: string, params?: { servings?: number }) => {
    const searchParams = new URLSearchParams();
    if (params?.servings) searchParams.set('servings', params.servings.toString());
    const query = searchParams.toString();
    return request<{ data: RecipeNutrition }>(`/browse/domains/${encodeURIComponent(domain)}/recipes/${id}/nutrition${query ? `?${query}` : ''}`, { token });
  }
};

// Tags API
export const tags = {
  list: (token: string) => request<{ data: Tag[] }>('/tags', { token }),

  create: (token: string, name: string) =>
    request<{ data: Tag }>('/tags', {
      method: 'POST',
      token,
      body: { tag: { name } }
    }),

  delete: (token: string, id: string) =>
    request<null>(`/tags/${id}`, {
      method: 'DELETE',
      token
    })
};

// Ingredients API types
export interface PackageSize {
  type: string;
  size_value: number;
  size_unit: string;
  label: string;
  is_default: boolean;
}

export interface ScaledIngredient {
  original_name?: string;
  scaled_quantity: number;
  scaled_unit: string;
  total_volume?: { value: number; unit: string } | null;
  package_suggestion?: string | null;
  packages_to_buy?: number;
  package_size?: string;
  available_packages: PackageSize[];
}

export interface ScaleBulkResult {
  scale_factor: number;
  ingredients: ScaledIngredient[];
}

export interface IngredientNutrition {
  source: 'usda' | 'manual' | 'open_food_facts' | 'nutritionix' | 'estimated';
  source_name: string | null;
  source_url: string | null;
  serving_size_value: number;
  serving_size_unit: string;
  serving_description: string | null;
  is_primary: boolean;

  // Macros
  calories: number | null;
  protein_g: number | null;
  fat_total_g: number | null;
  fat_saturated_g: number | null;
  fat_trans_g: number | null;
  fat_polyunsaturated_g: number | null;
  fat_monounsaturated_g: number | null;
  carbohydrates_g: number | null;
  fiber_g: number | null;
  sugar_g: number | null;
  sugar_added_g: number | null;

  // Minerals
  sodium_mg: number | null;
  potassium_mg: number | null;
  calcium_mg: number | null;
  iron_mg: number | null;
  magnesium_mg: number | null;
  phosphorus_mg: number | null;
  zinc_mg: number | null;

  // Vitamins
  vitamin_a_mcg: number | null;
  vitamin_c_mg: number | null;
  vitamin_d_mcg: number | null;
  vitamin_e_mg: number | null;
  vitamin_k_mcg: number | null;
  vitamin_b6_mg: number | null;
  vitamin_b12_mcg: number | null;
  folate_mcg: number | null;
  thiamin_mg: number | null;
  riboflavin_mg: number | null;
  niacin_mg: number | null;

  // Other
  cholesterol_mg: number | null;
  water_g: number | null;
}

export interface CanonicalIngredient {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
  subcategory: string | null;
  tags: string[];
  is_allergen: boolean;
  allergen_groups: string[];
  dietary_flags: string[];
  aliases: string[];
  is_branded: boolean;
  brand: string | null;
  parent_company: string | null;
  image_url: string | null;
  usage_count: number;
  package_sizes?: PackageSize[];
  nutrition?: IngredientNutrition | null;
  all_nutrition?: IngredientNutrition[];
}

// Ingredients API
export const ingredients = {
  list: (token: string, params?: { is_branded?: boolean; parent_company?: string; category?: string; search?: string; order_by?: 'popularity' | 'name' }) => {
    const searchParams = new URLSearchParams();
    if (params?.is_branded !== undefined) searchParams.set('is_branded', params.is_branded.toString());
    if (params?.parent_company) searchParams.set('parent_company', params.parent_company);
    if (params?.category) searchParams.set('category', params.category);
    if (params?.search) searchParams.set('search', params.search);
    if (params?.order_by) searchParams.set('order_by', params.order_by);
    const query = searchParams.toString();
    return request<{ data: CanonicalIngredient[] }>(`/ingredients${query ? `?${query}` : ''}`, { token });
  },

  get: (token: string, id: string) =>
    request<{ data: CanonicalIngredient }>(`/ingredients/${id}`, { token }),

  lookup: (token: string, name: string) =>
    request<{ data: CanonicalIngredient }>('/ingredients/lookup', {
      method: 'POST',
      token,
      body: { name }
    }),

  scale: (token: string, params: { name: string; quantity: number; unit: string; scale_factor: number }) =>
    request<{ data: ScaledIngredient }>('/ingredients/scale', {
      method: 'POST',
      token,
      body: params
    }),

  scaleBulk: (token: string, scaleFactor: number, ingredientsList: Array<{ name: string; quantity: number; unit: string }>) =>
    request<{ data: ScaleBulkResult }>('/ingredients/scale_bulk', {
      method: 'POST',
      token,
      body: {
        scale_factor: scaleFactor,
        ingredients: ingredientsList
      }
    }),

  packageSizes: (token: string, id: string) =>
    request<{ data: PackageSize[] }>(`/ingredients/${id}/package_sizes`, { token })
};

// Shopping List types
export interface ShoppingListItem {
  id: string;
  display_text: string;
  quantity: number | null;
  unit: string | null;
  canonical_ingredient_id: string | null;
  canonical_name: string | null;
  raw_name: string | null;
  category: string;
  checked_at: string | null;
  notes: string | null;
  source_recipe_ids: string[];
  inserted_at: string;
  updated_at: string;
}

export interface ItemsByCategory {
  category: string;
  items: ShoppingListItem[];
}

export interface ShoppingList {
  id: string;
  name: string;
  archived_at: string | null;
  inserted_at: string;
  updated_at: string;
  items?: ShoppingListItem[];
  items_by_category?: ItemsByCategory[];
  checked_count?: number;
  total_count?: number;
}

export interface ShoppingListInput {
  name: string;
}

export interface ShoppingListItemInput {
  display_text: string;
  quantity?: number;
  unit?: string;
  category?: string;
  notes?: string;
}

// Shopping Lists API
export const shoppingLists = {
  list: (token: string, params?: { archived?: 'true' | 'all' }) => {
    const searchParams = new URLSearchParams();
    if (params?.archived) searchParams.set('archived', params.archived);
    const query = searchParams.toString();
    return request<{ data: ShoppingList[] }>(`/shopping-lists${query ? `?${query}` : ''}`, { token });
  },

  get: (token: string, id: string) =>
    request<{ data: ShoppingList }>(`/shopping-lists/${id}`, { token }),

  create: (token: string, shoppingList: ShoppingListInput) =>
    request<{ data: ShoppingList }>('/shopping-lists', {
      method: 'POST',
      token,
      body: { shopping_list: shoppingList }
    }),

  update: (token: string, id: string, shoppingList: Partial<ShoppingListInput>) =>
    request<{ data: ShoppingList }>(`/shopping-lists/${id}`, {
      method: 'PUT',
      token,
      body: { shopping_list: shoppingList }
    }),

  delete: (token: string, id: string) =>
    request<null>(`/shopping-lists/${id}`, {
      method: 'DELETE',
      token
    }),

  archive: (token: string, id: string) =>
    request<{ data: ShoppingList }>(`/shopping-lists/${id}/archive`, {
      method: 'POST',
      token
    }),

  clearChecked: (token: string, id: string) =>
    request<{ data: ShoppingList }>(`/shopping-lists/${id}/clear-checked`, {
      method: 'POST',
      token
    }),

  addRecipe: (token: string, id: string, recipeId: string, scale?: number) =>
    request<{ data: ShoppingList }>(`/shopping-lists/${id}/add-recipe`, {
      method: 'POST',
      token,
      body: { recipe_id: recipeId, scale }
    }),

  // Item operations
  createItem: (token: string, listId: string, item: ShoppingListItemInput) =>
    request<{ data: ShoppingListItem }>(`/shopping-lists/${listId}/items`, {
      method: 'POST',
      token,
      body: { item }
    }),

  updateItem: (token: string, listId: string, itemId: string, item: Partial<ShoppingListItemInput>) =>
    request<{ data: ShoppingListItem }>(`/shopping-lists/${listId}/items/${itemId}`, {
      method: 'PUT',
      token,
      body: { item }
    }),

  deleteItem: (token: string, listId: string, itemId: string) =>
    request<null>(`/shopping-lists/${listId}/items/${itemId}`, {
      method: 'DELETE',
      token
    }),

  checkItem: (token: string, listId: string, itemId: string) =>
    request<{ data: ShoppingListItem }>(`/shopping-lists/${listId}/items/${itemId}/check`, {
      method: 'POST',
      token
    }),

  uncheckItem: (token: string, listId: string, itemId: string) =>
    request<{ data: ShoppingListItem }>(`/shopping-lists/${listId}/items/${itemId}/uncheck`, {
      method: 'POST',
      token
    })
};

export { ApiError };
