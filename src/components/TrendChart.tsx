import { useEffect, useId, useRef, useState } from "react";
export default function LineChart({
  values,
  start,
}: {
  values: number[];
  start: number;
}) {
  const ref = useRef<SVGSVGElement>(null);
  const gradient = useId();
  const [width, setWidth] = useState(310);
  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    const observer = new ResizeObserver(([entry]) =>
      setWidth(entry.contentRect.width),
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  const step = Math.ceil(Math.max(1, ...values) / 3);
  const maximum = step * 3;
  const left = String(maximum).length * 6 + 10;
  const right = width - 8,
    top = 8,
    bottom = 156;
  const series = values.length === 1 ? [values[0], values[0]] : values;
  const points = series.map((value, i) => ({
    x: left + (i * (right - left)) / (series.length - 1),
    y: bottom - (value / maximum) * (bottom - top),
  }));
  const path = points
    .map((point, i) => {
      if (!i) return `M${point.x},${point.y}`;
      const previous = points[i - 1],
        middle = (previous.x + point.x) / 2;
      return `C${middle},${previous.y} ${middle},${point.y} ${point.x},${point.y}`;
    })
    .join(" ");
  const last = points.at(-1);
  const indices = [
    ...new Set([
      0,
      ...(right - left >= 180 ? [Math.floor((values.length - 1) / 2)] : []),
      values.length - 1,
    ]),
  ];
  return (
    <svg
      ref={ref}
      viewBox={`0 0 ${width} 180`}
      role="img"
      aria-label="Évolution sur la période"
    >
      <defs>
        <linearGradient
          id={gradient}
          x1="0"
          y1={top}
          x2="0"
          y2={bottom}
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="var(--chart-color)" stopOpacity=".28" />
          <stop offset="1" stopColor="var(--chart-color)" stopOpacity=".01" />
        </linearGradient>
      </defs>
      {[0, 1, 2, 3].map((i) => {
        const y = bottom - ((bottom - top) * i) / 3;
        return (
          <g key={i}>
            <path d={`M${left},${y} H${right}`} stroke="#ffffff14" />
            <path d={`M${left - 4},${y} H${left}`} stroke="#ffffff47" />
            <text
              x={left - 9}
              y={y}
              textAnchor="end"
              dominantBaseline="central"
            >
              {i * step}
            </text>
          </g>
        );
      })}
      <path
        d={`M${left},${top} V${bottom} H${right}`}
        stroke="#ffffff47"
        fill="none"
      />
      {last && (
        <>
          <path
            d={`${path} L${right},${bottom} L${left},${bottom} Z`}
            fill={`url(#${gradient})`}
          />
          <path
            d={path}
            fill="none"
            stroke="var(--chart-color)"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
          <circle
            cx={last.x}
            cy={last.y}
            r="7"
            fill="var(--chart-color)"
            opacity=".2"
          />
          <circle
            cx={last.x}
            cy={last.y}
            r="4"
            fill="var(--chart-color)"
            stroke="#ffffffb3"
            strokeWidth="1.5"
          />
        </>
      )}
      {values.length > 0 &&
        indices.map((i) => {
          const x =
            values.length === 1
              ? left
              : left + ((right - left) * i) / (values.length - 1);
          const date = new Date(start);
          date.setDate(date.getDate() + i);
          return (
            <g key={i}>
              <path d={`M${x},${bottom} v4`} stroke="#ffffff47" />
              <text
                x={Math.max(14, Math.min(width - 14, x))}
                y={bottom + 10}
                dominantBaseline="hanging"
                textAnchor="middle"
              >
                {date.toLocaleDateString("fr-FR", {
                  day: "2-digit",
                  month: "2-digit",
                })}
              </text>
            </g>
          );
        })}
    </svg>
  );
}
