import React, { useState, useMemo } from "react";
import { ComposableMap, Geographies, Geography } from "react-simple-maps";
import countries from "world-countries";

const geoUrl =
"https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json";
/* Example users per country */
const usersData = {
  USA: 5508,
  GBR: 5122,
  RUS: 4750,
  CHN: 4300,
  AUS: 4018,
  IND: 3200,
  BRA: 2100,
  CAN: 1800,
};

/* Heatmap color scale */
function getColor(users) {
  if (!users) return "#1e293b";
  if (users > 5000) return "#6D28D9";
  if (users > 4000) return "#7C3AED";
  if (users > 3000) return "#8B5CF6";
  if (users > 2000) return "#A78BFA";
  return "#C4B5FD";
}

export default function WorldDashboard() {
  const [tooltip, setTooltip] = useState("");

  /* Top countries */
  const topCountries = useMemo(() => {
    return Object.entries(usersData)
      .map(([code, users]) => ({ code, users }))
      .sort((a, b) => b.users - a.users)
      .slice(0, 5);
  }, []);

  /* Users by continent */
  const continentStats = useMemo(() => {
    const result = {};

    countries.forEach((c) => {
      const code = c.cca3;
      const region = c.region;

      if (usersData[code]) {
        result[region] = (result[region] || 0) + usersData[code];
      }
    });

    return result;
  }, []);

  return (
    <div className="space-y-6">

      {/* Map + sidebar */}
      <div className="grid md:grid-cols-3 gap-6">

        {/* World Map */}
        <div className="md:col-span-2 bg-slate-900 p-6 rounded-xl relative">
          <ComposableMap width={800} height={400}>
            <Geographies geography={geoUrl}>
              {({ geographies }) =>
                geographies.map((geo) => {
                  const code = geo.properties.ISO_A3;
                  const users = usersData[code];

                  return (
                    <Geography
                      key={geo.rsmKey}
                      geography={geo}
                      fill={getColor(users)}
                      stroke="#0f172a"
                      onMouseEnter={() =>
                        setTooltip(
                          `${geo.properties.NAME}: ${users || 0} users`
                        )
                      }
                      onMouseLeave={() => setTooltip("")}
                    />
                  );
                })
              }
            </Geographies>
          </ComposableMap>

          {tooltip && (
            <div className="absolute bottom-2 left-2 bg-black text-white text-xs px-3 py-1 rounded">
              {tooltip}
            </div>
          )}
        </div>

        {/* Top Countries */}
        <div className="bg-slate-900 p-6 rounded-xl text-white">
          <h2 className="text-lg font-semibold mb-4">Top Countries</h2>

          {topCountries.map((c) => (
            <div key={c.code} className="mb-3">
              <div className="flex justify-between text-sm">
                <span>{c.code}</span>
                <span>{c.users}</span>
              </div>

              <div className="w-full bg-slate-700 h-2 rounded">
                <div
                  className="bg-purple-500 h-2 rounded"
                  style={{ width: `${(c.users / 6000) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Continent Stats */}
      <div className="grid md:grid-cols-4 gap-4 text-white">

        {Object.entries(continentStats).map(([continent, users]) => (
          <div
            key={continent}
            className="bg-slate-900 p-4 rounded-lg text-center"
          >
            <p className="text-sm text-slate-400">{continent}</p>
            <p className="text-xl font-bold">{users}</p>
          </div>
        ))}

      </div>
    </div>
  );
}

