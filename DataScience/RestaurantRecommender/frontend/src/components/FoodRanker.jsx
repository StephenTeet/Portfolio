import { useState } from "react";

const CUISINES = [
  "Italian", "Mexican", "Chinese", "Japanese", "American",
  "Indian", "Thai", "Mediterranean", "French", "Korean"
];

export default function FoodRanker({ onChange }) {
  const [ranked, setRanked] = useState([]);
  const [available, setAvailable] = useState(CUISINES);

  const addToRanked = (cuisine) => {
    const next = [...ranked, cuisine];
    setRanked(next);
    setAvailable(available.filter(c => c !== cuisine));
    onChange(next.reduce((acc, c, i) => ({ ...acc, [c.toLowerCase()]: i + 1 }), {}));
  };

  const removeFromRanked = (cuisine) => {
    setRanked(ranked.filter(c => c !== cuisine));
    setAvailable([...available, cuisine]);
  };

  return (
    <div className="ranker">
      <h3>Drag cuisines into your preference order</h3>
      <div className="ranked-list">
        {ranked.map((c, i) => (
          <div key={c} className="rank-item" onClick={() => removeFromRanked(c)}>
            <span className="rank-num">{i + 1}</span> {c}
          </div>
        ))}
      </div>
      <div className="available-list">
        {available.map(c => (
          <button key={c} onClick={() => addToRanked(c)}>{c}</button>
        ))}
      </div>
    </div>
  );
}
