import { CircularProgressbar, buildStyles } from "react-circular-progressbar";
import "react-circular-progressbar/dist/styles.css";

const data = [
  { label: "food", value: 57, color: "#3b82f6", change: "+3.4%", up: true },
  { label: "house", value: 76, color: "#f59e0b", change: "-1.10%", up: false },
  { label: "car", value: 21, color: "#a855f7", change: "-15.75%", up: false },
  { label: "gaiety", value: 34, color: "#22c55e", change: "+10.1%", up: true },
  { label: "holiday", value: 10, color: "#f97316", change: "+23.1%", up: true },
    { label: "holiday", value: 10, color: "#f97316", change: "+23.1%", up: true },
];

export default function Dashboard() {
  return (
        <div className="bg-white/80 dark:bg-slate-900 backdrop-blur-xl rounded-b-2xl p-3 border border-slate-200/50 dark:border-slate-700/50">
      <div className="grid grid-cols-2 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {data.map((item, index) => (
          <div key={index} className="text-center">
            
            <div className="w-24 h-24">
              <CircularProgressbar
                value={item.value}
                text={`${item.value}%`}
                styles={buildStyles({
                  pathColor: item.color,
                  textColor: "#fff",
                  trailColor: "#1e293b",
                })}
              />
            </div>

            <p className="mt-3 text-gray-400">{item.label}</p>

            <p
              className={`text-sm ${
                item.up ? "text-green-500" : "text-red-500"
              }`}
            >
              {item.change}
            </p>

          </div>
        ))}
      </div>
    </div>
  );
}