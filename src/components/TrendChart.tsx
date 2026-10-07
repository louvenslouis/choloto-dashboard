import { useEffect, useId, useRef, useState } from "react";
export default function LineChart({
  values,
  start,
  height = 180,
  valueLabel = "membres",
  monthlyAxis = false,
}: {
  values: number[];
  start: number;
  height?: number;
  valueLabel?: string;
  monthlyAxis?: boolean;
}) {
  const ref = useRef<SVGSVGElement>(null);
  const gradient = useId();
  const [width, setWidth] = useState(310);
  const [active, setActive] = useState<number | null>(null);
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
    bottom = height - 24;
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
  const selected =
    active !== null && active < values.length ? points[active] : null;
  const selectedDate = new Date(start);
  selectedDate.setDate(selectedDate.getDate() + (active ?? 0));
  const dailyIndices = [
    ...new Set([
      0,
      ...(right - left >= 180 ? [Math.floor((values.length - 1) / 2)] : []),
      values.length - 1,
    ]),
  ];
  const monthIndices: number[] = [];
  if (monthlyAxis && values.length > 0) {
    const first = new Date(start);
    const date = new Date(first.getFullYear(), first.getMonth() + 1, 1);
    const minimumGap = 64;
    monthIndices.push(0);
    while (true) {
      const index = Math.round(
        (Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) -
          Date.UTC(first.getFullYear(), first.getMonth(), first.getDate())) /
          86400000,
      );
      if (index >= values.length - 1) break;
      const x = (index / (values.length - 1)) * (right - left);
      const previousX =
        (monthIndices[monthIndices.length - 1] / (values.length - 1)) *
        (right - left);
      if (x - previousX >= minimumGap && right - left - x >= minimumGap)
        monthIndices.push(index);
      date.setMonth(date.getMonth() + 1);
    }
    if (values.length > 1) monthIndices.push(values.length - 1);
  }
  const indices = monthlyAxis ? monthIndices : dailyIndices;
  return (
    <div className="interactive-chart" onPointerLeave={() => setActive(null)}>
      <svg
        ref={ref}
        viewBox={`0 0 ${width} ${height}`}
        role="img"
        aria-label="Évolution sur la période"
        tabIndex={values.length ? 0 : undefined}
        onFocus={() => setActive(0)}
        onBlur={() => setActive(null)}
        onKeyDown={(event) => {
          if (event.key === "Escape") setActive(null);
          if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
            event.preventDefault();
            setActive((index) =>
              Math.max(
                0,
                Math.min(
                  values.length - 1,
                  (index ?? 0) + (event.key === "ArrowRight" ? 1 : -1),
                ),
              ),
            );
          }
        }}
        onPointerMove={(event) => {
          if (!values.length) return;
          const position = event.currentTarget.createSVGPoint();
          position.x = event.clientX;
          position.y = event.clientY;
          const matrix = event.currentTarget.getScreenCTM();
          if (!matrix) return;
          const x = position.matrixTransform(matrix.inverse()).x;
          setActive(
            Math.max(
              0,
              Math.min(
                values.length - 1,
                Math.round(((x - left) / (right - left)) * (values.length - 1)),
              ),
            ),
          );
        }}
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
                  x={monthlyAxis ? x : Math.max(14, Math.min(width - 14, x))}
                  y={bottom + 10}
                  dominantBaseline="hanging"
                  textAnchor={
                    monthlyAxis && i === 0
                      ? "start"
                      : monthlyAxis && i === values.length - 1
                        ? "end"
                        : "middle"
                  }
                >
                  {date.toLocaleDateString(
                    "fr-FR",
                    monthlyAxis
                      ? {
                          month: "short",
                          year: "2-digit",
                        }
                      : {
                          day: "2-digit",
                          month: "2-digit",
                        },
                  )}
                </text>
              </g>
            );
          })}
        {selected && (
          <g className="chart-highlight" pointerEvents="none">
            <path
              d={`M${selected.x},${top} V${bottom}`}
              stroke="var(--chart-color)"
              strokeDasharray="3 4"
              opacity=".7"
            />
            <circle
              cx={selected.x}
              cy={selected.y}
              r="10"
              fill="var(--chart-color)"
              opacity=".2"
            />
            <circle
              cx={selected.x}
              cy={selected.y}
              r="4.5"
              fill="var(--chart-color)"
              stroke="white"
              strokeWidth="2"
            />
          </g>
        )}
      </svg>
      {selected && active !== null && (
        <div
          className="chart-tooltip"
          role="tooltip"
          style={{
            left: `clamp(0px, calc(${(selected.x / width) * 100}% - 85px), calc(100% - 170px))`,
          }}
        >
          <span>
            {selectedDate.toLocaleDateString("fr-FR", {
              day: "numeric",
              month: "long",
              year: "numeric",
            })}
          </span>
          <strong>
            {values[active].toLocaleString("fr-FR")} {valueLabel}
          </strong>
        </div>
      )}
    </div>
  );
}
