import { authorizeAnalytics, getAnalyticsToken } from "./firebase";
export type AnalyticsOverview = {
  realtime: number;
  today: number;
  newUsers: number;
  duration: number;
  week: number;
  month: number;
  daily: { date: string; active: number }[];
  screens: { name: string; views: number; users: number }[];
};
export async function loadAnalytics(
  reauthorize = false,
): Promise<AnalyticsOverview> {
  if (reauthorize || !getAnalyticsToken()) await authorizeAnalytics();
  async function post(method: string, body: unknown) {
    const response = await fetch(
      `https://analyticsdata.googleapis.com/v1beta/properties/503828194:${method}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${getAnalyticsToken()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(20000),
      },
    );
    const data = await response.json();
    if (!response.ok)
      throw new Error(data.error?.message || "Analytics indisponible.");
    return data;
  }
  const range = (startDate: string) => [{ startDate, endDate: "today" }],
    metrics = (...names: string[]) => names.map((name) => ({ name }));
  const [batch, realtime] = await Promise.all([
    post("batchRunReports", {
      requests: [
        {
          dateRanges: range("today"),
          metrics: metrics("activeUsers", "newUsers", "averageSessionDuration"),
        },
        { dateRanges: range("6daysAgo"), metrics: metrics("activeUsers") },
        { dateRanges: range("29daysAgo"), metrics: metrics("activeUsers") },
        {
          dateRanges: range("29daysAgo"),
          dimensions: [{ name: "date" }],
          metrics: metrics("activeUsers"),
          orderBys: [{ dimension: { dimensionName: "date" } }],
        },
        {
          dateRanges: range("29daysAgo"),
          dimensions: [{ name: "unifiedScreenName" }],
          metrics: metrics("screenPageViews", "activeUsers"),
          orderBys: [{ metric: { metricName: "screenPageViews" }, desc: true }],
          limit: "5",
        },
      ],
    }),
    post("runRealtimeReport", { metrics: metrics("activeUsers") }),
  ]);
  const reports = batch.reports || [],
    value = (i: number, j = 0) =>
      Number(reports[i]?.rows?.[0]?.metricValues?.[j]?.value || 0);
  type ReportRow = {
    dimensionValues: { value: string }[];
    metricValues: { value: string }[];
  };
  return {
    realtime: Number(realtime.rows?.[0]?.metricValues?.[0]?.value || 0),
    today: value(0),
    newUsers: value(0, 1),
    duration: value(0, 2),
    week: value(1),
    month: value(2),
    daily: (reports[3]?.rows || []).map((r: ReportRow) => ({
      date: r.dimensionValues[0].value,
      active: Number(r.metricValues[0].value),
    })),
    screens: (reports[4]?.rows || []).map((r: ReportRow) => ({
      name: r.dimensionValues[0].value,
      views: Number(r.metricValues[0].value),
      users: Number(r.metricValues[1].value),
    })),
  };
}
