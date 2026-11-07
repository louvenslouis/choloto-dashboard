import { useEffect, useId, useRef, useState, type PointerEvent } from "react";
export default function LineChart({
  values,
  start,
  height: initialHeight = 180,
  valueLabel = "membres",
  monthlyAxis = false,
  comparison,
  ariaLabel = "Évolution sur la période",
}: {
  values: number[];
  start: number;
  height?: number;
  valueLabel?: string;
  monthlyAxis?: boolean;
  comparison?: { values: number[]; label: string; color: string };
  ariaLabel?: string;
}) {
  const ref = useRef<SVGSVGElement>(null);
  const gradient = useId();
  const tooltipId = useId();
  const [{ width, height }, setSize] = useState({
    width: 310,
    height: initialHeight,
  });
  const [active, setActive] = useState<number | null>(null);
  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    const observer = new ResizeObserver(([{ contentRect }]) => {
      if (contentRect.width && contentRect.height)
        setSize({ width: contentRect.width, height: contentRect.height });
    });
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  const step = Math.ceil(
    Math.max(1, ...values, ...(comparison?.values ?? [])) / 3,
  );
  const maximum = step * 3;
  const left = String(maximum).length * 6 + 10;
  const right = width - 8,
    top = 8,
    bottom = height - 24;
  const primary = { values, label: valueLabel, color: "var(--chart-color)" };
  const lines = (comparison ? [primary, comparison] : [primary]).map(
    (series) => {
      const samples =
        series.values.length === 1
          ? [series.values[0], series.values[0]]
          : series.values;
      const points = samples.map((value, i) => ({
        x: left + (i * (right - left)) / (samples.length - 1),
        y: bottom - (value / maximum) * (bottom - top),
      }));
      const path = points
        .map((point, i) => {
          if (!i) return `M${point.x},${point.y}`;
          const previous = points[i - 1];
          const middle = (previous.x + point.x) / 2;
          return `C${middle},${previous.y} ${middle},${point.y} ${point.x},${point.y}`;
        })
        .join(" ");
      return { ...series, points, path, last: points.at(-1) };
    },
  );
  const selected =
    active !== null && active < values.length ? lines[0].points[active] : null;
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
  function selectDay(event: PointerEvent<SVGSVGElement>) {
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
  }
  return (
    <div
      className="interactive-chart"
      onPointerLeave={(event) => {
        if (event.pointerType !== "touch") setActive(null);
      }}
    >
      <svg
        ref={ref}
        viewBox={`0 0 ${width} ${height}`}
        role="img"
        aria-label={ariaLabel}
        aria-describedby={selected ? tooltipId : undefined}
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
        onPointerMove={selectDay}
        onPointerDown={(event) => {
          event.currentTarget.focus({ preventScroll: true });
          selectDay(event);
        }}
        onPointerCancel={() => setActive(null)}
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
        {lines.map(
          ({ label, path, last, color }, index) =>
            last && (
              <g key={label}>
                {index === 0 && (
                  <path
                    d={`${path} L${right},${bottom} L${left},${bottom} Z`}
                    fill={`url(#${gradient})`}
                  />
                )}
                <path
                  d={path}
                  fill="none"
                  stroke={color}
                  strokeWidth="2.5"
                  strokeDasharray={index ? "4 4" : undefined}
                  strokeLinecap="round"
                />
                <circle
                  cx={last.x}
                  cy={last.y}
                  r="7"
                  fill={color}
                  opacity=".2"
                />
                <circle
                  cx={last.x}
                  cy={last.y}
                  r={index ? 3 : 4}
                  fill={color}
                  stroke="#ffffffb3"
                  strokeWidth="1.5"
                />
              </g>
            ),
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
        {selected && active !== null && (
          <g className="chart-highlight" pointerEvents="none">
            <path
              d={`M${selected.x},${top} V${bottom}`}
              stroke="var(--chart-color)"
              strokeDasharray="3 4"
              opacity=".7"
            />
            {lines.map(({ points, color, label }, index) => {
              const point = points[active];
              return (
                <g key={label}>
                  <circle
                    cx={point.x}
                    cy={point.y}
                    r="10"
                    fill={color}
                    opacity=".2"
                  />
                  <circle
                    cx={point.x}
                    cy={point.y}
                    r={index ? 3 : 4.5}
                    fill={color}
                    stroke="white"
                    strokeWidth="2"
                  />
                </g>
              );
            })}
          </g>
        )}
      </svg>
      {selected && active !== null && (
        <div
          id={tooltipId}
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
          {lines.map(({ label, color, values: samples }) => (
            <strong key={label} style={comparison ? { color } : undefined}>
              {comparison
                ? `${label} · ${samples[active].toLocaleString("fr-FR")}`
                : `${samples[active].toLocaleString("fr-FR")} ${label}`}
            </strong>
          ))}
        </div>
      )}
    </div>
  );
}
