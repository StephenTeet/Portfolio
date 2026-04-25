import pandas as pd
import numpy as np

CUISINE_TYPES = [
    "italian", "mexican", "chinese", "japanese", "american",
    "indian", "thai", "mediterranean", "french", "korean",
    "vietnamese", "greek", "spanish", "middle_eastern", "other"
]

PRICE_MAP = {"$": 1, "$$": 2, "$$$": 3, "$$$$": 4}

def build_restaurant_features(restaurant: dict) -> np.ndarray:
    """Convert restaurant dict to feature vector."""
    features = []
    
    # Cuisine one-hot encoding
    cuisine = restaurant.get("cuisine", "other").lower()
    for c in CUISINE_TYPES:
        features.append(1.0 if cuisine == c else 0.0)
    
    # Normalized price (1-4 scale → 0-1)
    price_raw = restaurant.get("price_level", "$$")
    price = PRICE_MAP.get(price_raw, 2) / 4.0
    features.append(price)
    
    # Normalized distance (assume max 30km)
    dist = min(restaurant.get("distance_km", 5.0), 30.0) / 30.0
    features.append(dist)
    
    # Drive time normalized (assume max 60 min)
    drive = min(restaurant.get("drive_time_min", 10.0), 60.0) / 60.0
    features.append(drive)
    
    return np.array(features, dtype=np.float32)


def build_user_preference_vector(prefs: dict) -> np.ndarray:
    """
    prefs = {
      "cuisine_rankings": {"italian": 1, "mexican": 2, ...},  # lower = preferred
      "price_range": [1, 3],     # min/max on 1-4 scale
      "max_drive_min": 20,
      "past_restaurants": [{"name": "...", "cuisine": "...", "rating": 5}]
    }
    """
    features = []
    
    total_cuisines = len(CUISINE_TYPES)
    rankings = prefs.get("cuisine_rankings", {})
    
    # Convert rank to preference score (1st place = 1.0, last = 0.0)
    max_rank = max(rankings.values(), default=1) if rankings else 1
    for c in CUISINE_TYPES:
        rank = rankings.get(c)
        if rank is not None:
            score = 1.0 - ((rank - 1) / max(max_rank - 1, 1))
        else:
            score = 0.5  # neutral
        features.append(score)
    
    # Preferred price midpoint normalized
    price_range = prefs.get("price_range", [1, 3])
    price_mid = (price_range[0] + price_range[1]) / 2 / 4.0
    features.append(price_mid)
    
    # Drive tolerance normalized
    max_drive = prefs.get("max_drive_min", 20) / 60.0
    features.append(max_drive)
    
    # Drive distance placeholder (matches restaurant vector length)
    features.append(max_drive)
    
    return np.array(features, dtype=np.float32)
