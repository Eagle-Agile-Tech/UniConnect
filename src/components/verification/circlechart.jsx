import { CircularProgressbar, buildStyles } from "react-circular-progressbar";
import "react-circular-progressbar/dist/styles.css";

const data = [
  {
    label: "ID Verification",
    value: 80,
    color: "#3b82f6",
  },
  {
    label: "Email Verification",
    value: 100,
    color: "#22c55e",
  },
  {
    label: "Institution Verification",
    value: 60,
    color: "#f59e0b",
  },
];

export default function Dashboard() {
  return (
    <div className="bg-white/80 dark:bg-slate-900 h-[570px] backdrop-blur-xl rounded-b-2xl p-6 border border-slate-200/50 dark:border-slate-700/50">

      <div className="grid grid-cols-1  gap-8">
        {data.map((item, index) => (
          <div key={index} className="flex flex-col items-center">

            {/* Circle */}
            <div className="w-28 h-18 mb-6">
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

            {/* Label */}
            <p className="mt-4  text-sm font-medium text-gray-700 dark:text-gray-300 text-center">
              {item.label}
            </p>

            {/* Status */}
            <p
              className={`text-xs mt-1 ${
                item.value === 100
                  ? "text-green-500"
                  : item.value > 50
                  ? "text-yellow-500"
                  : "text-red-500"
              }`}
            >
              {item.value === 100
                ? "Verified"
                : item.value > 50
                ? "In Progress"
                : "Not Verified"}
            </p>

          </div>
        ))}
      </div>
    </div>
  );
}