import requests
from geopy.distance import geodesic

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
ORS_URL = "https://api.openrouteservice.org/v2/directions/driving-car"

def fetch_restaurants_near(lat, lon, radius_meters=10000, cuisine=None):
    """Fetch restaurants from OpenStreetMap Overpass API."""
    cuisine_filter = f'["cuisine"="{cuisine}"]' if cuisine else ""
    query = f"""
    [out:json];
    node["amenity"="restaurant"]{cuisine_filter}
      (around:{radius_meters},{lat},{lon});
    out body;
    """
    resp = requests.post(OVERPASS_URL, data={"data": query})
    resp.raise_for_status()
    elements = resp.json().get("elements", [])
    
    restaurants = []
    for el in elements:
        tags = el.get("tags", {})
        restaurants.append({
            "osm_id": el["id"],
            "name": tags.get("name", "Unknown"),
            "cuisine": tags.get("cuisine", "unknown"),
            "lat": el["lat"],
            "lon": el["lon"],
            "price_level": tags.get("price_level"),  # $ $$ $$$ etc
            "opening_hours": tags.get("opening_hours"),
            "distance_km": geodesic((lat, lon), (el["lat"], el["lon"])).km
        })
    return restaurants


def get_drive_time_minutes(origin_lat, origin_lon, dest_lat, dest_lon, api_key):
    """Get drive time via OpenRouteService (free, OSM-based)."""
    headers = {"Authorization": api_key, "Content-Type": "application/json"}
    body = {
        "coordinates": [[origin_lon, origin_lat], [dest_lon, dest_lat]]
    }
    resp = requests.post(ORS_URL, json=body, headers=headers)
    resp.raise_for_status()
    duration_sec = resp.json()["routes"][0]["summary"]["duration"]
    return round(duration_sec / 60, 1)
