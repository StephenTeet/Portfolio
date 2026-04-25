from rest_framework.views import APIView
from rest_framework.response import Response
from .osm_service import fetch_restaurants_near, get_drive_time_minutes
from ml.engine import get_recommendations
import os

class RecommendationView(APIView):
    def post(self, request):
        data = request.data
        lat = data["lat"]
        lon = data["lon"]
        prefs = data["preferences"]
        
        max_drive = prefs.get("max_drive_min", 30)
        # Rough radius: assume ~1km/min driving
        radius_meters = max_drive * 1000
        
        # Fetch from OSM
        restaurants = fetch_restaurants_near(lat, lon, radius_meters)
        
        # Enrich with drive times (sample top 30 by distance to save API calls)
        ors_key = os.getenv("ORS_API_KEY", "")
        restaurants = sorted(restaurants, key=lambda r: r["distance_km"])[:30]
        
        for r in restaurants:
            try:
                r["drive_time_min"] = get_drive_time_minutes(
                    lat, lon, r["lat"], r["lon"], ors_key
                )
            except Exception:
                # Fallback: estimate from distance
                r["drive_time_min"] = r["distance_km"] * 2
        
        # Run ML recommendation engine
        recommendations = get_recommendations(restaurants, prefs, top_n=10)
        
        return Response({"recommendations": recommendations})
