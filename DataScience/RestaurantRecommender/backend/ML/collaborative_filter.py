"""
collaborative_filter.py
------------------------
Memory-based collaborative filtering using cosine similarity between user
preference vectors.

How it works:
  1. Each known user is represented as a preference vector (same shape as
     feature_builder.build_preference_vector outputs).
  2. When a new user arrives, we compute cosine similarity between their
     vector and every stored user vector.
  3. We take the top-K most similar users ("neighbors").
  4. We aggregate their thumbs-up signals to produce a cuisine affinity
     boost for each cuisine type.

This is a user-user collaborative filter — classic, explainable, and
interview-friendly. It complements the content-based engine in engine.py.

In production:
  - User vectors would be loaded from the Django DB (e.g. a UserProfile table).
  - You'd retrain/update the matrix periodically or on each new feedback event.
  - For scale, switch from brute-force cosine to approximate nearest neighbor
    (e.g. Annoy, FAISS).
"""

import numpy as np
from sklearn.metrics.pairwise import cosine_similarity


class CollaborativeFilter:
    """
    Memory-based user-user collaborative filter.

    Attributes:
        user_vectors:   np.ndarray of shape (n_users, FEATURE_DIM)
        user_histories: list of UserHistory summary dicts, one per user
        user_ids:       list of identifiers (session keys, user IDs, etc.)
    """

    def __init__(self):
        self.user_vectors: np.ndarray | None = None   # (n_users, FEATURE_DIM)
        self.user_histories: list[dict] = []
        self.user_ids: list[str] = []

    # ------------------------------------------------------------------ #
    # Building the user matrix                                            #
    # ------------------------------------------------------------------ #

    def fit(self, user_records: list[dict]):
        """
        Load known users into the filter.

        Args:
            user_records: list of dicts, each with:
                {
                  "user_id":    str,
                  "pref_vector": np.ndarray (FEATURE_DIM,),
                  "history":    UserHistory.to_summary() dict
                }
        """
        if not user_records:
            return

        self.user_ids = [r["user_id"] for r in user_records]
        self.user_vectors = np.stack([r["pref_vector"] for r in user_records])
        self.user_histories = [r["history"] for r in user_records]

    def is_ready(self) -> bool:
        """True if the filter has at least one stored user."""
        return self.user_vectors is not None and len(self.user_ids) > 0

    # ------------------------------------------------------------------ #
    # Generating cuisine affinity boosts                                  #
    # ------------------------------------------------------------------ #

    def get_cuisine_boosts(
        self,
        current_user_vector: np.ndarray,
        top_k: int = 5,
        min_similarity: float = 0.6,
    ) -> dict[str, float]:
        """
        Compute per-cuisine affinity boosts from the K nearest neighbors.

        The boost for a cuisine is the similarity-weighted average thumbs-up
        rate that neighbors have for that cuisine.  A boost of 0.0 means
        neutral; positive means neighbors liked it; negative means they didn't.

        Args:
            current_user_vector: preference vector for the active user
            top_k:               number of neighbors to consider
            min_similarity:      minimum cosine similarity to include a neighbor

        Returns:
            dict mapping cuisine name → float boost in roughly [-0.3, +0.3]
        """
        if not self.is_ready():
            return {}

        # Cosine similarity between current user and all stored users
        query = current_user_vector.reshape(1, -1)
        similarities = cosine_similarity(query, self.user_vectors)[0]  # (n_users,)

        # Pick top-K neighbors above the similarity threshold
        ranked_indices = np.argsort(similarities)[::-1]
        neighbors = [
            (i, similarities[i])
            for i in ranked_indices[:top_k]
            if similarities[i] >= min_similarity
        ]

        if not neighbors:
            return {}

        # Weighted average of neighbor thumbs-up rates per cuisine
        boosts: dict[str, list] = {}
        for idx, sim in neighbors:
            thumbs_rates = self.user_histories[idx].get("cuisine_thumbs_rate", {})
            for cuisine, rate in thumbs_rates.items():
                if cuisine not in boosts:
                    boosts[cuisine] = []
                # Weight contribution by similarity
                boosts[cuisine].append((rate, sim))

        # Convert to a single boost value: (weighted_avg_rate - 0.5) * scale
        # 0.5 is the neutral thumbs rate; we scale to keep boosts modest
        result = {}
        for cuisine, weighted_vals in boosts.items():
            total_sim = sum(s for _, s in weighted_vals)
            if total_sim == 0:
                continue
            weighted_rate = sum(r * s for r, s in weighted_vals) / total_sim
            result[cuisine] = (weighted_rate - 0.5) * 0.4  # maps to [-0.2, +0.2]

        return result

    # ------------------------------------------------------------------ #
    # Explanation helper (useful for portfolio demos)                     #
    # ------------------------------------------------------------------ #

    def explain_neighbors(
        self,
        current_user_vector: np.ndarray,
        top_k: int = 3,
    ) -> list[dict]:
        """
        Return human-readable info about the nearest neighbors.
        Great for showing interviewers how the collaborative filter works.

        Returns:
            [{"user_id": ..., "similarity": 0.87, "top_cuisines": [...]}, ...]
        """
        if not self.is_ready():
            return []

        query = current_user_vector.reshape(1, -1)
        similarities = cosine_similarity(query, self.user_vectors)[0]
        ranked_indices = np.argsort(similarities)[::-1][:top_k]

        explanation = []
        for idx in ranked_indices:
            thumbs = self.user_histories[idx].get("cuisine_thumbs_rate", {})
            top_cuisines = sorted(thumbs.items(), key=lambda x: x[1], reverse=True)[:3]
            explanation.append({
                "user_id": self.user_ids[idx],
                "similarity": round(float(similarities[idx]), 3),
                "top_cuisines": [c for c, _ in top_cuisines],
            })
        return explanation
