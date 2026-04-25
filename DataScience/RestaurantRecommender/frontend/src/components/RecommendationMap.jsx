import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";

export default function RecommendationMap({ restaurants, userLocation }) {
  return (
    <MapContainer center={userLocation} zoom={13} style={{ height: "400px" }}>
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org">OSM</a>'
      />
      {restaurants.map((r, i) => (
        <Marker key={r.osm_id} position={[r.lat, r.lon]}>
          <Popup>
            <strong>#{i + 1} {r.name}</strong><br />
            🍽 {r.cuisine} | {r.price_level || "$$"}<br />
            🚗 {r.drive_time_min} min | ⭐ Score: {r.recommendation_score}
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
