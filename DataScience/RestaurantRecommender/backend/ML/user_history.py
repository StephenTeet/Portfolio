"""
user_history.py
---------------
Manages per-user feedback signals that feed back into the recommendation engine.

Two signal types:
  1. Star ratings  — collected from "places you've been" in the preference wizard
  2. Thumbs up/down — collected after recommendations are served

Both signals are aggregated per cuisine type and stored as a UserHistory object.
In production this would serialize to/from the Django database; here it's a
plain dataclass so the ML logic stays framework-agnostic.
"""

from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class UserHistory:
    """
    Accumulates a user's explicit feedback over time.

    Attributes:
        star_ratings:  list of (cuisine, rating) tuples, rating on 1–5 scale
        thumbs:        list of (cuisine, positive) tuples, positive is bool
    """
    star_ratings: list = field(default_factory=list)   # [(cuisine, 1–5), ...]
    thumbs: list = field(default_factory=list)          # [(cuisine, True/False), ...]

    # ------------------------------------------------------------------ #
    # Ingestion helpers                                                    #
    # ------------------------------------------------------------------ #

    def add_star_rating(self, cuisine: str, rating: int):
        """Record a star rating (1–5) for a cuisine after a past visit."""
        if not 1 <= rating <= 5:
            raise ValueError(f"Rating must be 1–5, got {rating}")
        self.star_ratings.append((cuisine.lower(), rating))

    def add_thumbs(self, cuisine: str, positive: bool):
        """Record a thumbs up (True) or thumbs down (False) on a recommendation."""
        self.thumbs.append((cuisine.lower(), positive))

    def load_from_wizard(self, past_restaurants: list[dict]):
        """
        Bulk-load star ratings collected in the preference wizard.

        Args:
            past_restaurants: [{"name": "...", "cuisine": "...", "rating": 4}, ...]
        """
        for r in past_restaurants:
            cuisine = r.get("cuisine", "other")
            rating = r.get("rating", 3)
            self.add_star_rating(cuisine, rating)

    # ------------------------------------------------------------------ #
    # Aggregation                                                          #
    # ------------------------------------------------------------------ #

    def cuisine_avg_rating(self) -> dict[str, float]:
        """
        Average star rating per cuisine.
        Returns a dict: {"italian": 4.2, "mexican": 3.0, ...}
        """
        totals = defaultdict(list)
        for cuisine, rating in self.star_ratings:
            totals[cuisine].append(rating)
        return {c: sum(v) / len(v) for c, v in totals.items()}

    def cuisine_thumbs_rate(self) -> dict[str, float]:
        """
        Thumbs-up rate per cuisine (0.0 = all thumbs down, 1.0 = all thumbs up).
        Returns a dict: {"italian": 0.8, "mexican": 0.5, ...}
        """
        totals = defaultdict(list)
        for cuisine, positive in self.thumbs:
            totals[cuisine].append(1.0 if positive else 0.0)
        return {c: sum(v) / len(v) for c, v in totals.items()}

    def to_summary(self) -> dict:
        """
        Return a summary dict compatible with feature_builder.build_restaurant_vector().
        """
        return {
            "cuisine_avg_rating": self.cuisine_avg_rating(),
            "cuisine_thumbs_rate": self.cuisine_thumbs_rate(),
        }

    def feedback_count(self) -> int:
        """Total number of feedback signals collected."""
        return len(self.star_ratings) + len(self.thumbs)
