"""
feature_builder.py
------------------
Converts raw restaurant dicts and user preference dicts into
fixed-length numeric vectors that the recommendation engine can work with.

Feature vector layout (length = 20):
  [0:15]  cuisine one-hot  (15 cuisine types)
  [15]    normalized price (0.0–1.0)
  [16]    normalized distance (0.0–1.0, capped at 30 km)
  [17]    normalized drive time (0.0–1.0, capped at 60 min)
  [18]    avg star rating from past visits to this cuisine (0.0–1.0)
  [19]    thumbs-up rate from past feedback on this cuisine (0.0–1.0)
"""

import numpy as np

CUISINE_TYPES = [
    "italian", "mexican", "chinese", "japanese", "american",
    "indian", "thai", "mediterranean", "french", "korean",
    "vietnamese", "greek", "spanish", "middle_eastern", "other",
]

PRICE_MAP = {"$": 1, "$$": 2, "$$$": 3, "$$$$": 4}
FEATURE_DIM = len(CUISINE_TYPES) + 5  # 20 total


def _cuisine_index(cuisine: str) -> int:
    key = cuisine.lower().replace(" ", "_")
    return CUISINE_TYPES.index(key) if key in CUISINE_TYPES else len(CUISINE_TYPES) - 1


def build_restaurant_vector(restaurant: dict, user_history: dict | None = None) -> np.ndarray:
    """
    Build a feature vector for a single restaurant.

    Args:
        restaurant: dict with keys name, cuisine, price_level, distance_km, drive_time_min
        user_history: optional dict summarizing a user's past feedback, shape:
            {
              "cuisine_avg_rating": {"italian": 4.2, ...},   # 1–5 scale
              "cuisine_thumbs_rate": {"italian": 0.8, ...},  # 0.0–1.0
            }
    Returns:
        np.ndarray of shape (FEATURE_DIM,)
    """
    vec = np.zeros(FEATURE_DIM, dtype=np.float32)

    # Cuisine one-hot
    idx = _cuisine_index(restaurant.get("cuisine", "other"))
    vec[idx] = 1.0

    # Normalized price (maps $→0.25, $$→0.5, $$$→0.75, $$$$→1.0)
    price_raw = restaurant.get("price_level", "$$")
    vec[15] = PRICE_MAP.get(price_raw, 2) / 4.0

    # Normalized distance (cap 30 km)
    vec[16] = min(restaurant.get("distance_km", 5.0), 30.0) / 30.0

    # Normalized drive time (cap 60 min)
    vec[17] = min(restaurant.get("drive_time_min", 10.0), 60.0) / 60.0

    # User history signals (default to neutral 0.5 if no data)
    cuisine_key = restaurant.get("cuisine", "other").lower()
    if user_history:
        avg_rating = user_history.get("cuisine_avg_rating", {}).get(cuisine_key)
        thumbs_rate = user_history.get("cuisine_thumbs_rate", {}).get(cuisine_key)
        vec[18] = (avg_rating / 5.0) if avg_rating is not None else 0.5
        vec[19] = thumbs_rate if thumbs_rate is not None else 0.5
    else:
        vec[18] = 0.5
        vec[19] = 0.5

    return vec


def build_preference_vector(preferences: dict) -> np.ndarray:
    """
    Build a target vector representing what the user wants.

    Args:
        preferences: {
            "cuisine_rankings": {"italian": 1, "mexican": 2, ...},  # 1 = most preferred
            "price_range": [1, 3],      # min/max on 1–4 scale
            "max_drive_min": 20,
            "max_distance_km": 10,
        }
    Returns:
        np.ndarray of shape (FEATURE_DIM,)
    """
    vec = np.zeros(FEATURE_DIM, dtype=np.float32)

    rankings = preferences.get("cuisine_rankings", {})
    max_rank = max(rankings.values(), default=1) if rankings else 1

    # Cuisine preferences: rank 1 → 1.0, last rank → 0.0, unranked → 0.3
    for cuisine, rank in rankings.items():
        idx = _cuisine_index(cuisine)
        score = 1.0 - ((rank - 1) / max(max_rank - 1, 1))
        vec[idx] = score
    # Fill unranked cuisines with a low-but-nonzero value
    for i, c in enumerate(CUISINE_TYPES):
        if vec[i] == 0.0 and c not in rankings:
            vec[i] = 0.3

    # Preferred price: midpoint of range, normalized
    price_range = preferences.get("price_range", [1, 3])
    vec[15] = ((price_range[0] + price_range[1]) / 2) / 4.0

    # Drive & distance tolerances — represent as ideal midpoint (half of max)
    max_drive = preferences.get("max_drive_min", 20)
    max_dist = preferences.get("max_distance_km", 10)
    vec[16] = (max_dist / 2) / 30.0
    vec[17] = (max_drive / 2) / 60.0

    # Preference vector has no history signals — neutral
    vec[18] = 0.5
    vec[19] = 0.5

    return vec
