"""
demo.py
-------
Runnable demo of the full ML pipeline.

Run with:  python demo.py

Shows:
  1. Building preference & restaurant feature vectors
  2. Seeding the collaborative filter with synthetic user history
  3. Scoring and ranking a set of mock restaurants
  4. Displaying score breakdowns + a "why this?" explanation per result
  5. Simulating thumbs up/down feedback and showing how scores shift
"""

import numpy as np
from feature_builder import build_preference_vector
from user_history import UserHistory
from collaborative_filter import CollaborativeFilter
from engine import recommend, explain_recommendation

# ------------------------------------------------------------------ #
# 1.  Current user preferences  (as collected by the React wizard)    #
# ------------------------------------------------------------------ #

USER_PREFERENCES = {
    "cuisine_rankings": {
        "italian": 1,
        "japanese": 2,
        "mediterranean": 3,
        "mexican": 4,
    },
    "price_range": [1, 3],       # $ to $$$
    "max_drive_min": 25,
    "max_distance_km": 15,
}

PAST_RESTAURANTS = [
    {"name": "Olive & Vine",    "cuisine": "italian",       "rating": 5},
    {"name": "Sushi Nami",      "cuisine": "japanese",      "rating": 4},
    {"name": "Casa Blanca",     "cuisine": "mexican",       "rating": 3},
    {"name": "The Curry House", "cuisine": "indian",        "rating": 2},
]

# ------------------------------------------------------------------ #
# 2.  Mock restaurant candidates  (normally from OSM Overpass API)    #
# ------------------------------------------------------------------ #

RESTAURANTS = [
    {"name": "Osteria Mia",         "cuisine": "italian",       "price_level": "$$",   "distance_km": 1.2,  "drive_time_min": 5},
    {"name": "Sakura Garden",       "cuisine": "japanese",      "price_level": "$$$",  "distance_km": 2.8,  "drive_time_min": 9},
    {"name": "El Rancho Grande",    "cuisine": "mexican",       "price_level": "$",    "distance_km": 1.9,  "drive_time_min": 7},
    {"name": "The Blue Bistro",     "cuisine": "french",        "price_level": "$$$",  "distance_km": 4.1,  "drive_time_min": 14},
    {"name": "Golden Dragon",       "cuisine": "chinese",       "price_level": "$$",   "distance_km": 3.3,  "drive_time_min": 11},
    {"name": "Spice Route",         "cuisine": "indian",        "rating": 2,           "price_level": "$$", "distance_km": 5.0, "drive_time_min": 17},
    {"name": "Mediterranean Sun",   "cuisine": "mediterranean", "price_level": "$$",   "distance_km": 6.2,  "drive_time_min": 20},
    {"name": "Seoul Kitchen",       "cuisine": "korean",        "price_level": "$$",   "distance_km": 7.4,  "drive_time_min": 24},
    {"name": "The Steak House",     "cuisine": "american",      "price_level": "$$$$", "distance_km": 3.0,  "drive_time_min": 10},
    {"name": "Pho Saigon",          "cuisine": "vietnamese",    "price_level": "$",    "distance_km": 8.1,  "drive_time_min": 27},  # over limit
]

# ------------------------------------------------------------------ #
# 3.  Synthetic user pool for collaborative filtering                 #
# ------------------------------------------------------------------ #
#
# In production these come from the Django DB (stored preference vectors
# and aggregated feedback for past sessions).

def make_synthetic_users() -> list[dict]:
    users = []

    # User A: very similar to our user — loves Italian & Japanese
    users.append({
        "user_id": "user_a",
        "pref_vector": build_preference_vector({
            "cuisine_rankings": {"italian": 1, "japanese": 2, "greek": 3},
            "price_range": [1, 3],
            "max_drive_min": 20,
            "max_distance_km": 12,
        }),
        "history": {
            "cuisine_avg_rating":  {"italian": 4.8, "japanese": 4.5, "greek": 4.0},
            "cuisine_thumbs_rate": {"italian": 0.9, "japanese": 0.85, "mediterranean": 0.75},
        },
    })

    # User B: somewhat similar — Mediterranean focus
    users.append({
        "user_id": "user_b",
        "pref_vector": build_preference_vector({
            "cuisine_rankings": {"mediterranean": 1, "italian": 2, "spanish": 3},
            "price_range": [2, 3],
            "max_drive_min": 30,
            "max_distance_km": 20,
        }),
        "history": {
            "cuisine_avg_rating":  {"mediterranean": 4.7, "italian": 4.2, "spanish": 3.8},
            "cuisine_thumbs_rate": {"mediterranean": 0.9, "italian": 0.7, "french": 0.6},
        },
    })

    # User C: dissimilar — Indian & Korean focus, high budget
    users.append({
        "user_id": "user_c",
        "pref_vector": build_preference_vector({
            "cuisine_rankings": {"indian": 1, "korean": 2, "thai": 3},
            "price_range": [3, 4],
            "max_drive_min": 40,
            "max_distance_km": 25,
        }),
        "history": {
            "cuisine_avg_rating":  {"indian": 4.9, "korean": 4.4, "thai": 4.1},
            "cuisine_thumbs_rate": {"indian": 0.95, "korean": 0.8, "thai": 0.75},
        },
    })

    return users


# ------------------------------------------------------------------ #
# 4.  Run the demo                                                     #
# ------------------------------------------------------------------ #

def run_demo():
    print("=" * 60)
    print("  Restaurant Recommendation Engine — Demo")
    print("=" * 60)

    # Build user history from wizard inputs
    history = UserHistory()
    history.load_from_wizard(PAST_RESTAURANTS)
    print(f"\nUser history loaded: {history.feedback_count()} star ratings")
    print(f"  Avg ratings by cuisine: {history.cuisine_avg_rating()}")

    # Set up collaborative filter
    cf = CollaborativeFilter()
    cf.fit(make_synthetic_users())
    pref_vec = build_preference_vector(USER_PREFERENCES)

    neighbors = cf.explain_neighbors(pref_vec, top_k=2)
    print(f"\nTop collaborative filter neighbors:")
    for n in neighbors:
        print(f"  {n['user_id']}  similarity={n['similarity']}  likes: {n['top_cuisines']}")

    # Get recommendations
    results = recommend(
        restaurants=RESTAURANTS,
        preferences=USER_PREFERENCES,
        history=history,
        collab_filter=cf,
        pref_vector=pref_vec,
        top_n=8,
    )

    print(f"\n{'Rank':<5} {'Restaurant':<25} {'Cuisine':<16} {'Price':<6} {'Drive':>5}  {'Score':>6}  Breakdown")
    print("-" * 90)
    for i, r in enumerate(results, 1):
        bd = r["_score_breakdown"]
        print(
            f"  {i:<4} {r['name']:<25} {r['cuisine']:<16} {r.get('price_level','??'):<6} "
            f"{r['drive_time_min']:>4}m  {r['recommendation_score_pct']:>5.1f}%  "
            f"[content={bd['content_score']:.2f} hist={bd['history_score']:.2f} "
            f"collab={bd['collab_score']:.2f} penalty={bd['price_penalty']:.2f}]"
        )

    print(f"\n--- Why these top 3? ---")
    for r in results[:3]:
        print(f"\n  {r['name']}: {explain_recommendation(r)}")

    # ------------------------------------------------------------------ #
    # 5.  Simulate feedback and show score shift                          #
    # ------------------------------------------------------------------ #
    print("\n--- Simulating feedback: thumbs DOWN on Korean ---")
    history.add_thumbs("korean", positive=False)
    history.add_thumbs("korean", positive=False)

    results_after = recommend(
        restaurants=RESTAURANTS,
        preferences=USER_PREFERENCES,
        history=history,
        collab_filter=cf,
        pref_vector=pref_vec,
        top_n=8,
    )

    print(f"\n{'Restaurant':<25} {'Before':>8} {'After':>8} {'Delta':>8}")
    print("-" * 55)
    before_map = {r["name"]: r["recommendation_score_pct"] for r in results}
    for r in results_after:
        before = before_map.get(r["name"], 0)
        after  = r["recommendation_score_pct"]
        delta  = after - before
        marker = " <-- shifted" if abs(delta) > 0.1 else ""
        print(f"  {r['name']:<23} {before:>7.1f}% {after:>7.1f}%  {delta:>+6.1f}%{marker}")


if __name__ == "__main__":
    run_demo()
