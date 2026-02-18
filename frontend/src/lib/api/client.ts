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
    request<{ token: string; user: { id: string; email: string; onboarding_completed?: boolean } }>('/auth/magic-link/verify', {
      method: 'POST',
      body: { token }
    }),

  refresh: (token: string) =>
    request<{ token: string }>('/auth/refresh', {
      method: 'POST',
      token
    }),

  me: (token: string) =>
    request<{ user: { id: string; email: string; inserted_at: string; onboarding_completed?: boolean } }>('/auth/me', {
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
    request<{ token: string; user: { id: string; email: string; onboarding_completed?: boolean } }>('/auth/passkeys/authenticate', {
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
export interface IngredientDiagnostics {
  tokens: string;
  parser: string;
  match_strategy: string | null;
  alternatives: string[];
  warnings: string[];
  parse_time_us: number;
}

export interface PreStep {
  action: string;
  target: string | null;
  quantity: number | null;
  unit: string | null;
  category: 'temperature' | 'cook' | 'process' | 'cut' | 'other';
  estimated_time_min: number | null;
  tool: string | null;
  order_hint: number;
}

export interface IngredientAlternative {
  name: string;
  canonical_name: string | null;
  canonical_id: string | null;
  nutrition_diff?: {
    calories?: number;
    fat_total_g?: number;
    fat_saturated_g?: number;
    carbohydrates_g?: number;
    protein_g?: number;
  };
}

export interface RecipeReference {
  type: 'below' | 'above' | 'notes' | 'link' | 'inline';
  text: string | null;
  name: string | null;
  is_optional: boolean;
}

// Quantity can be stored as a nested object (parsed) or flat number (legacy/unprocessed)
export interface IngredientQuantity {
  value: number | null;
  min: number | null;
  max: number | null;
  unit: string | null;
}

export interface Ingredient {
  text: string;
  group: string | null;
  canonical_name?: string | null;
  canonical_id?: string | null;
  confidence?: number;
  // Quantity is nested object from TokenParser.to_jsonb_map, or flat number for legacy data
  quantity?: IngredientQuantity | number | null;
  // Legacy flat fields (for backward compatibility)
  quantity_min?: number | null;
  quantity_max?: number | null;
  unit?: string | null;
  preparations?: string[];
  is_alternative?: boolean;
  alternatives?: IngredientAlternative[];
  recipe_reference?: RecipeReference;
  pre_steps?: PreStep[];
  _diagnostics?: IngredientDiagnostics;
}

export interface IngredientDecision {
  id: string;
  recipe_id: string;
  ingredient_index: number;
  selected_canonical_id: string;
  selected_name: string | null;
  inserted_at: string;
  updated_at: string;
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
  is_owned?: boolean;
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

export type MeasurementType = 'standard' | 'liquid' | 'weight_primary' | 'count_primary';
export type ConversionMethod = 'weight' | 'volume_density' | 'liquid_density' | 'count' | 'unknown' | null;

// Nutrition source types for multi-source support
export type NutritionSource = 'composite' | 'usda' | 'manual' | 'fatsecret' | 'open_food_facts' | 'nutritionix' | 'estimated';

export interface SourceInfo {
  source: NutritionSource;
  confidence: number;
  is_primary: boolean;
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
  measurement_type: MeasurementType | null;
  conversion_method: ConversionMethod;
  source_used: NutritionSource | null;
  available_sources: SourceInfo[];
}

export interface RecipeNutrition {
  recipe_id: string;
  recipe_title: string;
  servings: number;
  completeness: number;
  source_used: NutritionSource;
  available_sources: SourceInfo[];
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
  tag_names?: string[];
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

  copy: (token: string, id: string) =>
    request<{ data: Recipe }>(`/recipes/${id}/copy`, {
      method: 'POST',
      token
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

  nutrition: (token: string, id: string, params?: { servings?: number; decisions?: Record<number, string>; source?: NutritionSource }) => {
    const searchParams = new URLSearchParams();
    if (params?.servings) searchParams.set('servings', params.servings.toString());
    if (params?.source) searchParams.set('source', params.source);
    if (params?.decisions) {
      for (const [idx, canonicalId] of Object.entries(params.decisions)) {
        searchParams.set(`decisions[${idx}]`, canonicalId);
      }
    }
    const query = searchParams.toString();
    return request<{ data: RecipeNutrition }>(`/recipes/${id}/nutrition${query ? `?${query}` : ''}`, { token });
  },

  // Ingredient decisions
  listDecisions: (token: string, id: string) =>
    request<{ data: IngredientDecision[] }>(`/recipes/${id}/decisions`, { token }),

  saveDecision: (token: string, id: string, ingredientIndex: number, selectedCanonicalId: string, selectedName?: string) =>
    request<{ data: IngredientDecision }>(`/recipes/${id}/decisions`, {
      method: 'POST',
      token,
      body: {
        ingredient_index: ingredientIndex,
        selected_canonical_id: selectedCanonicalId,
        selected_name: selectedName
      }
    }),

  deleteDecision: (token: string, id: string, ingredientIndex: number) =>
    request<{ deleted: boolean }>(`/recipes/${id}/decisions/${ingredientIndex}`, {
      method: 'DELETE',
      token
    }),

  clearDecisions: (token: string, id: string) =>
    request<{ deleted: number }>(`/recipes/${id}/decisions`, {
      method: 'DELETE',
      token
    })
};

// Avoided Ingredients API
export type AvoidanceType = 'ingredient' | 'category' | 'allergen' | 'animal';

export interface CanonicalIngredientRef {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
}

export interface AvoidedIngredient {
  id: string;
  display_name: string;
  avoidance_type: AvoidanceType;
  inserted_at: string;
  // For ingredient avoidance
  canonical_name?: string;
  canonical_ingredient_id?: string;
  canonical_ingredient?: CanonicalIngredientRef;
  // For category avoidance
  category?: string;
  // For allergen avoidance
  allergen_group?: string;
  // For animal avoidance
  animal_type?: string;
  // For category/allergen/animal avoidance - list of allowed exceptions
  exceptions?: string[];
  exception_count?: number;
}

export interface AvoidanceIngredientItem {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
  is_exception: boolean;
}

export interface AvoidanceIngredientsResponse {
  avoidance_id: string;
  avoidance_type: AvoidanceType;
  display_name: string;
  ingredients: AvoidanceIngredientItem[];
  total_count: number;
  exception_count: number;
}

export interface AvoidanceOptions {
  avoidance_types: AvoidanceType[];
  categories: string[];
  allergen_groups: string[];
  animal_types: string[];
}

export const avoidedIngredients = {
  list: (token: string) =>
    request<{ data: AvoidedIngredient[] }>('/avoided-ingredients', { token }),

  // Get available options for avoidance types, categories, and allergen groups
  options: (token: string) =>
    request<AvoidanceOptions>('/avoided-ingredients/options', { token }),

  // Create text-based ingredient avoidance (legacy)
  create: (token: string, displayName: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: { avoided_ingredient: { display_name: displayName } }
    }),

  // Create avoided ingredient by canonical ingredient ID (precise)
  createByIngredient: (token: string, canonicalIngredientId: string, displayName: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: {
        avoided_ingredient: {
          avoidance_type: 'ingredient',
          canonical_ingredient_id: canonicalIngredientId,
          display_name: displayName
        }
      }
    }),

  // Create avoided category
  createByCategory: (token: string, category: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: {
        avoided_ingredient: {
          avoidance_type: 'category',
          category
        }
      }
    }),

  // Create avoided allergen group
  createByAllergen: (token: string, allergenGroup: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: {
        avoided_ingredient: {
          avoidance_type: 'allergen',
          allergen_group: allergenGroup
        }
      }
    }),

  // Create avoided animal type
  createByAnimal: (token: string, animalType: string) =>
    request<{ data: AvoidedIngredient }>('/avoided-ingredients', {
      method: 'POST',
      token,
      body: {
        avoided_ingredient: {
          avoidance_type: 'animal',
          animal_type: animalType
        }
      }
    }),

  delete: (token: string, id: string) =>
    request<null>(`/avoided-ingredients/${id}`, {
      method: 'DELETE',
      token
    }),

  // Get ingredients included in a category or allergen avoidance
  getIngredients: (token: string, avoidanceId: string) =>
    request<{ data: AvoidanceIngredientsResponse }>(`/avoided-ingredients/${avoidanceId}/ingredients`, { token }),

  // Add an exception (allow an ingredient despite category/allergen avoidance)
  addException: (token: string, avoidanceId: string, canonicalIngredientId: string) =>
    request<{ data: AvoidedIngredient }>(`/avoided-ingredients/${avoidanceId}/exceptions`, {
      method: 'POST',
      token,
      body: { canonical_ingredient_id: canonicalIngredientId }
    }),

  // Remove an exception (avoid the ingredient again as part of category/allergen)
  removeException: (token: string, avoidanceId: string, canonicalIngredientId: string) =>
    request<{ data: AvoidedIngredient }>(`/avoided-ingredients/${avoidanceId}/exceptions/${canonicalIngredientId}`, {
      method: 'DELETE',
      token
    }),

  // Bulk create avoided ingredients (for onboarding wizard)
  bulkCreate: (token: string, avoidances: Array<{ type: string; value: string }>) =>
    request<{ data: { created_count: number } }>('/avoided-ingredients/bulk', {
      method: 'POST',
      token,
      body: { avoidances }
    })
};

// Settings API
export interface UserPreferences {
  hide_avoided_ingredients: boolean;
  is_admin?: boolean;
}

export const settings = {
  getPreferences: (token: string) =>
    request<{ data: UserPreferences }>('/settings/preferences', { token }),

  updatePreferences: (token: string, preferences: Partial<UserPreferences>) =>
    request<{ data: UserPreferences }>('/settings/preferences', {
      method: 'PUT',
      token,
      body: { preferences }
    }),

  completeOnboarding: (token: string) =>
    request<{ data: { onboarding_completed: boolean } }>('/settings/complete-onboarding', {
      method: 'POST',
      token
    })
};

// Dashboard API
export interface DashboardRecipe {
  id: string;
  title: string;
  description: string | null;
  source_url: string | null;
  source_domain: string | null;
  image_url: string | null;
  total_time_minutes: number | null;
  servings: string | null;
  tags: Tag[];
  inserted_at: string;
  is_owned: boolean;
  contains_avoided?: boolean;
  avoided_ingredients?: AvoidedIngredientMatch[];
}

export interface DashboardData {
  dinner_ideas: DashboardRecipe[];
  recently_added: DashboardRecipe[];
  this_time_last_year: DashboardRecipe[];
  maybe_count: number;
}

export const dashboard = {
  get: (token: string) =>
    request<{ data: DashboardData }>('/dashboard', { token })
};

// Quicklist API
export const quicklist = {
  batch: (token: string, count: number = 10, tag?: string) => {
    const params = new URLSearchParams({ count: count.toString() });
    if (tag) params.set('tag', tag);
    return request<{ data: DashboardRecipe[] }>(`/quicklist/batch?${params}`, { token });
  },

  maybeList: (token: string) =>
    request<{ data: DashboardRecipe[] }>('/quicklist/maybe', { token }),

  swipe: (token: string, recipeId: string, action: 'maybe' | 'skip') =>
    request<{ data: { id: string; action: string; recipe_id: string } }>('/quicklist/swipe', {
      method: 'POST',
      token,
      body: { recipe_id: recipeId, action }
    }),

  removeMaybe: (token: string, recipeId: string) =>
    request<null>(`/quicklist/maybe/${recipeId}`, {
      method: 'DELETE',
      token
    })
};

// Browse API
export interface DomainInfo {
  domain: string;
  count: number;
  has_screenshot: boolean;
  favicon_url: string | null;
}

// Helper to get screenshot URL for a domain
export function getDomainScreenshotUrl(domain: string): string {
  const apiBase = import.meta.env.VITE_API_URL ||
    (typeof window !== 'undefined'
      ? `http://${window.location.hostname}:4000/api`
      : 'http://localhost:4000/api');
  return `${apiBase}/browse/domains/${encodeURIComponent(domain)}/screenshot`;
}

// Helper to get Google favicon URL for a domain
export function getDomainFaviconUrl(domain: string): string {
  return `https://www.google.com/s2/favicons?domain=${encodeURIComponent(domain)}&sz=64`;
}

export const browse = {
  domains: (token: string) =>
    request<{ data: DomainInfo[] }>('/browse/domains', { token }),

  recipesByDomain: (token: string, domain: string, params?: { q?: string; limit?: number; offset?: number; hide_avoided?: boolean }) => {
    const searchParams = new URLSearchParams();
    if (params?.q) searchParams.set('q', params.q);
    if (params?.limit) searchParams.set('limit', params.limit.toString());
    if (params?.offset) searchParams.set('offset', params.offset.toString());
    if (params?.hide_avoided !== undefined) searchParams.set('hide_avoided', params.hide_avoided.toString());
    const query = searchParams.toString();
    return request<{ data: Recipe[]; total: number }>(`/browse/domains/${encodeURIComponent(domain)}${query ? `?${query}` : ''}`, { token });
  },

  getRecipe: (token: string, domain: string, id: string) =>
    request<{ data: Recipe }>(`/browse/domains/${encodeURIComponent(domain)}/recipes/${id}`, { token }),

  nutrition: (token: string, domain: string, id: string, params?: { servings?: number; source?: NutritionSource }) => {
    const searchParams = new URLSearchParams();
    if (params?.servings) searchParams.set('servings', params.servings.toString());
    if (params?.source) searchParams.set('source', params.source);
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

// Admin API types
export interface MatchingRules {
  boost_words?: string[];
  anti_patterns?: string[];
  required_words?: string[];
  exclude_patterns?: string[];
  boost_amount?: number;
  anti_penalty?: number;
}

export interface AdminIngredient {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
  subcategory: string | null;
  animal_type: string | null;
  similarity_name: string | null;
  tags: string[];
  usage_count: number;
  matching_rules: MatchingRules | null;
  aliases: string[];
  skip_nutrition: boolean;
}

export interface AdminPreparation {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
  verb: string | null;
  metadata: Record<string, unknown>;
  aliases: string[];
}

export interface AdminPreparationOptions {
  categories: string[];
}

export interface AdminKitchenTool {
  id: string;
  name: string;
  display_name: string;
  category: string | null;
  metadata: Record<string, unknown>;
  aliases: string[];
}

export interface AdminKitchenToolOptions {
  categories: string[];
}

export interface AdminIngredientOptions {
  categories: string[];
  animal_types: string[];
}

export interface ScoringDetails {
  rules_applied: boolean;
  excluded?: boolean;
  reason?: string;
  boost_count?: number;
  anti_count?: number;
  boost_adjustment?: number;
  anti_adjustment?: number;
  base_score?: number;
}

export interface TestScorerResult {
  input: string;
  match: {
    name: string;
    canonical_name: string | null;
    canonical_id: string | null;
    confidence: number;
    scoring_details: ScoringDetails | null;
  };
  alternatives: Array<{
    canonical_name: string;
    canonical_id: string;
    score: number;
    matched: boolean;
    has_rules: boolean;
    details: ScoringDetails;
  }>;
}

// Admin API
export const admin = {
  ingredients: {
    list: (token: string, params?: { category?: string; animal_type?: string; missing_animal_type?: boolean; search?: string }) => {
      const searchParams = new URLSearchParams();
      if (params?.category) searchParams.set('category', params.category);
      if (params?.animal_type) searchParams.set('animal_type', params.animal_type);
      if (params?.missing_animal_type) searchParams.set('missing_animal_type', 'true');
      if (params?.search) searchParams.set('search', params.search);
      const query = searchParams.toString();
      return request<{ data: AdminIngredient[] }>(`/admin/ingredients${query ? `?${query}` : ''}`, { token });
    },

    get: (token: string, id: string) =>
      request<{ data: AdminIngredient }>(`/admin/ingredients/${id}`, { token }),

    update: (token: string, id: string, attrs: { animal_type?: string | null; category?: string; subcategory?: string; tags?: string[]; matching_rules?: MatchingRules | null; similarity_name?: string | null; skip_nutrition?: boolean }) =>
      request<{ data: AdminIngredient }>(`/admin/ingredients/${id}`, {
        method: 'PUT',
        token,
        body: { ingredient: attrs }
      }),

    setSkipNutrition: (token: string, id: string, skipNutrition: boolean) =>
      request<{ data: AdminIngredient }>(`/admin/ingredients/${id}`, {
        method: 'PUT',
        token,
        body: { ingredient: { skip_nutrition: skipNutrition } }
      }),

    options: (token: string) =>
      request<AdminIngredientOptions>('/admin/ingredients/options', { token }),

    testScorer: (token: string, input: string) =>
      request<{ data: TestScorerResult }>('/admin/ingredients/test-scorer', {
        method: 'POST',
        token,
        body: { input }
      })
  },

  preparations: {
    list: (token: string, params?: { category?: string; search?: string }) => {
      const searchParams = new URLSearchParams();
      if (params?.category) searchParams.set('category', params.category);
      if (params?.search) searchParams.set('search', params.search);
      const query = searchParams.toString();
      return request<{ data: AdminPreparation[] }>(`/admin/preparations${query ? `?${query}` : ''}`, { token });
    },

    get: (token: string, id: string) =>
      request<{ data: AdminPreparation }>(`/admin/preparations/${id}`, { token }),

    create: (token: string, attrs: { name: string; display_name: string; category?: string; verb?: string; aliases?: string[]; metadata?: Record<string, unknown> }) =>
      request<{ data: AdminPreparation }>('/admin/preparations', {
        method: 'POST',
        token,
        body: { preparation: attrs }
      }),

    update: (token: string, id: string, attrs: { name?: string; display_name?: string; category?: string; verb?: string; aliases?: string[]; metadata?: Record<string, unknown> }) =>
      request<{ data: AdminPreparation }>(`/admin/preparations/${id}`, {
        method: 'PUT',
        token,
        body: { preparation: attrs }
      }),

    delete: (token: string, id: string) =>
      request<null>(`/admin/preparations/${id}`, {
        method: 'DELETE',
        token
      }),

    options: (token: string) =>
      request<AdminPreparationOptions>('/admin/preparations/options', { token })
  },

  kitchenTools: {
    list: (token: string, params?: { category?: string; search?: string }) => {
      const searchParams = new URLSearchParams();
      if (params?.category) searchParams.set('category', params.category);
      if (params?.search) searchParams.set('search', params.search);
      const query = searchParams.toString();
      return request<{ data: AdminKitchenTool[] }>(`/admin/kitchen-tools${query ? `?${query}` : ''}`, { token });
    },

    get: (token: string, id: string) =>
      request<{ data: AdminKitchenTool }>(`/admin/kitchen-tools/${id}`, { token }),

    create: (token: string, attrs: { name: string; display_name: string; category?: string; aliases?: string[]; metadata?: Record<string, unknown> }) =>
      request<{ data: AdminKitchenTool }>('/admin/kitchen-tools', {
        method: 'POST',
        token,
        body: { kitchen_tool: attrs }
      }),

    update: (token: string, id: string, attrs: { name?: string; display_name?: string; category?: string; aliases?: string[]; metadata?: Record<string, unknown> }) =>
      request<{ data: AdminKitchenTool }>(`/admin/kitchen-tools/${id}`, {
        method: 'PUT',
        token,
        body: { kitchen_tool: attrs }
      }),

    delete: (token: string, id: string) =>
      request<null>(`/admin/kitchen-tools/${id}`, {
        method: 'DELETE',
        token
      }),

    options: (token: string) =>
      request<AdminKitchenToolOptions>('/admin/kitchen-tools/options', { token })
  },

  pendingIngredients: {
    list: (token: string, params?: { status?: string; limit?: number; offset?: number }) => {
      const searchParams = new URLSearchParams();
      if (params?.status) searchParams.set('status', params.status);
      if (params?.limit) searchParams.set('limit', params.limit.toString());
      if (params?.offset) searchParams.set('offset', params.offset.toString());
      const query = searchParams.toString();
      return request<{ data: PendingIngredient[]; stats: PendingIngredientStats; pagination?: { offset: number; limit: number; total: number } }>(`/admin/pending-ingredients${query ? `?${query}` : ''}`, { token });
    },

    get: (token: string, id: string) =>
      request<{ data: PendingIngredient }>(`/admin/pending-ingredients/${id}`, { token }),

    stats: (token: string) =>
      request<{ data: PendingIngredientStats }>('/admin/pending-ingredients/stats', { token }),

    update: (token: string, id: string, attrs: { suggested_display_name?: string; suggested_category?: string; suggested_aliases?: string[] }) =>
      request<{ data: PendingIngredient }>(`/admin/pending-ingredients/${id}`, {
        method: 'PUT',
        token,
        body: attrs
      }),

    approve: (token: string, id: string, attrs: { display_name?: string; category?: string; aliases?: string[] }) =>
      request<{ message: string; data: { id: string; name: string; display_name: string } }>(`/admin/pending-ingredients/${id}/approve`, {
        method: 'POST',
        token,
        body: attrs
      }),

    reject: (token: string, id: string) =>
      request<{ message: string; data: PendingIngredient }>(`/admin/pending-ingredients/${id}/reject`, {
        method: 'POST',
        token
      }),

    merge: (token: string, id: string, canonicalId: string) =>
      request<{ message: string; data: { id: string; name: string; aliases: string[] } }>(`/admin/pending-ingredients/${id}/merge`, {
        method: 'POST',
        token,
        body: { canonical_id: canonicalId }
      }),

    markAsPreparation: (token: string, id: string) =>
      request<{ message: string; data: PendingIngredient }>(`/admin/pending-ingredients/${id}/preparation`, {
        method: 'POST',
        token
      }),

    markAsTool: (token: string, id: string) =>
      request<{ message: string; data: PendingIngredient }>(`/admin/pending-ingredients/${id}/tool`, {
        method: 'POST',
        token
      }),

    scan: (token: string) =>
      request<{ message: string; job_id: number; cleared_count?: number }>('/admin/pending-ingredients/scan', {
        method: 'POST',
        token
      })
  }
};

// Pending Ingredient types
export interface PendingIngredient {
  id: string;
  name: string;
  occurrence_count: number;
  sample_texts: string[];
  status: 'pending' | 'approved' | 'rejected' | 'merged' | 'tool';
  fatsecret_id: string | null;
  fatsecret_name: string | null;
  suggested_display_name: string | null;
  suggested_category: string | null;
  suggested_aliases: string[];
  reviewed_at: string | null;
  inserted_at: string;
}

export interface PendingIngredientStats {
  pending: number;
  approved: number;
  rejected: number;
  merged: number;
  tool: number;
  preparation: number;
  total: number;
}

export { ApiError };
