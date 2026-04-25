"""
engine.py
---------
The main recommendation engine.  Combines three scoring signals:

  1. Content-based score  (60%)
     Cosine similarity between the restaurant's feature vector and the
     user's preference vector.  Pure "does this restaurant match what
     you asked for?"

  2. History score  (25%)
     Derived from the user's own star ratings and thumbs up/down on
     past restaurants of the same cuisine.  "Have YOU liked this
     kind of food before?"

  3. Collaborative score  (15%)
     Cuisine affinity boosts from similar users via the collaborative
     filter.  "Have people with your taste profile liked this cuisine?"

Hard constraints (applied before scoring):
  - Restaurants beyond max_drive_min are excluded entirely.
  - Restaurants outside the user's price range incur a score penalty
    rather than a hard cut, so borderline cases still surface.

Scoring formula per restaurant:
  raw_score = (0.60 * content) + (0.25 * history) + (0.15 * collab)
  final_score = max(0, raw_score - price_penalty)
"""

import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

from feature_builder import (
    build_restaurant_vector,
    build_preference_vector,
    PRICE_MAP,
    FEATURE_DIM,
)
from user_history import UserHistory
from collaborative_filter import CollaborativeFilter


# Weight of each signal in the final score
W_CONTENT = 0.60
W_HISTORY = 0.25
W_COLLAB  = 0.15


def _content_score(rest_vec: np.ndarray, pref_vec: np.ndarray) -> float:
    """Cosine similarity between restaurant vector and preference vector."""
    return float(cosine_similarity(rest_vec.reshape(1, -1), pref_vec.reshape(1, -1))[0][0])


def _history_score(restaurant: dict, history: UserHistory) -> float:
    """
    Derive a 0–1 score from the user's own past feedback on this cuisine.

    Combines:
      - Normalized average star rating for this cuisine  (weight 0.6)
      - Thumbs-up rate for this cuisine                 (weight 0.4)
    Falls back to 0.5 (neutral) when no data is available.
    """
    cuisine = restaurant.get("cuisine", "other").lower()
    summary = history.to_summary()

    avg_rating = summary["cuisine_avg_rating"].get(cuisine)
    thumbs_rate = summary["cuisine_thumbs_rate"].get(cuisine)

    norm_rating = (avg_rating / 5.0) if avg_rating is not None else None
    score_parts = []

    if norm_rating is not None:
        score_parts.append(norm_rating * 0.6)
    if thumbs_rate is not None:
        score_parts.append(thumbs_rate * 0.4)

    if not score_parts:
        return 0.5  # neutral — no data yet

    # If only one signal is present, rescale to 0–1
    if norm_rating is not None and thumbs_rate is not None:
        return sum(score_parts)
    elif norm_rating is not None:
        return norm_rating
    else:
        return thumbs_rate


def _collab_score(restaurant: dict, cuisine_boosts: dict[str, float]) -> float:
    """
    Convert a collaborative-filter cuisine boost into a 0–1 score.
    Boost is in [-0.2, +0.2]; we shift to [0.3, 0.7] around a neutral 0.5.
    """
    cuisine = restaurant.get("cuisine", "other").lower()
    boost = cuisine_boosts.get(cuisine, 0.0)
    return max(0.0, min(1.0, 0.5 + boost))


def _price_penalty(restaurant: dict, preferences: dict) -> float:
    """
    Return a score penalty if the restaurant's price is outside the user's range.
    One tier out → 0.15 penalty; two or more tiers out → 0.30 penalty.
    """
    price_range = preferences.get("price_range", [1, 4])
    rest_price = PRICE_MAP.get(restaurant.get("price_level", "$$"), 2)
    lo, hi = price_range[0], price_range[1]

    if rest_price < lo:
        tiers_out = lo - rest_price
    elif rest_price > hi:
        tiers_out = rest_price - hi
    else:
        return 0.0  # within range

    return min(0.30, tiers_out * 0.15)


def score_restaurant(
    restaurant: dict,
    preferences: dict,
    history: UserHistory,
    cuisine_boosts: dict[str, float],
) -> dict:
    """
    Compute the final recommendation score for a single restaurant.

    Returns a dict with the score and a breakdown of each signal —
    useful for explainability in the UI.
    """
    user_summary = history.to_summary()
    rest_vec = build_restaurant_vector(restaurant, user_summary)
    pref_vec = build_preference_vector(preferences)

    content  = _content_score(rest_vec, pref_vec)
    hist     = _history_score(restaurant, history)
    collab   = _collab_score(restaurant, cuisine_boosts)
    penalty  = _price_penalty(restaurant, preferences)

    raw   = W_CONTENT * content + W_HISTORY * hist + W_COLLAB * collab
    final = max(0.0, raw - penalty)

    return {
        "score":          round(final, 4),
        "score_pct":      round(final * 100, 1),
        "_breakdown": {
            "content_score":  round(content, 4),
            "history_score":  round(hist, 4),
            "collab_score":   round(collab, 4),
            "price_penalty":  round(penalty, 4),
        },
    }


def recommend(
    restaurants: list[dict],
    preferences: dict,
    history: UserHistory,
    collab_filter: CollaborativeFilter,
    pref_vector: np.ndarray | None = None,
    top_n: int = 10,
) -> list[dict]:
    """
    Main entry point.  Score all candidate restaurants and return the top N.

    Args:
        restaurants:    list of restaurant dicts from OSM (already enriched
                        with distance_km and drive_time_min)
        preferences:    user preference dict from the wizard
        history:        UserHistory for this session/user
        collab_filter:  trained CollaborativeFilter (may be unfitted for new users)
        pref_vector:    pre-built preference vector (optional, avoids recomputing)
        top_n:          number of results to return

    Returns:
        list of restaurant dicts, each augmented with scoring fields,
        sorted descending by score.
    """
    max_drive = preferences.get("max_drive_min", 30)

    # Hard filter: drop restaurants that exceed drive time limit
    candidates = [r for r in restaurants if r.get("drive_time_min", 0) <= max_drive]

    if not candidates:
        return []

    # Compute collaborative boosts once (shared across all restaurants)
    if pref_vector is None:
        pref_vector = build_preference_vector(preferences)
    cuisine_boosts = collab_filter.get_cuisine_boosts(pref_vector) if collab_filter.is_ready() else {}

    # Score every candidate
    scored = []
    for restaurant in candidates:
        result = score_restaurant(restaurant, preferences, history, cuisine_boosts)
        scored.append({
            **restaurant,
            "recommendation_score":     result["score"],
            "recommendation_score_pct": result["score_pct"],
            "_score_breakdown":         result["_breakdown"],
        })

    scored.sort(key=lambda r: r["recommendation_score"], reverse=True)
    return scored[:top_n]


def explain_recommendation(restaurant: dict) -> str:
    """
    Generate a human-readable explanation of why a restaurant was recommended.
    Useful for a "Why this?" tooltip in the frontend.
    """
    breakdown = restaurant.get("_score_breakdown", {})
    lines = []

    content = breakdown.get("content_score", 0)
    if content > 0.7:
        lines.append("strongly matches your cuisine and price preferences")
    elif content > 0.4:
        lines.append("is a reasonable match for your preferences")

    hist = breakdown.get("history_score", 0.5)
    if hist > 0.65:
        lines.append("you've rated similar cuisine highly before")
    elif hist < 0.35:
        lines.append("you've given mixed reviews to this cuisine type")

    collab = breakdown.get("collab_score", 0.5)
    if collab > 0.6:
        lines.append("users with similar taste have enjoyed this cuisine")

    penalty = breakdown.get("price_penalty", 0)
    if penalty > 0:
        lines.append(f"slight price mismatch ({penalty:.0%} penalty applied)")

    if not lines:
        return "Matched based on your overall preferences."

    return "Recommended because: " + "; ".join(lines) + "."
