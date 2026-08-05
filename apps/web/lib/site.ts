// Public site origin, used for canonical/OpenGraph URLs, sitemap.xml and
// robots.txt. Set SITE_URL in production to the real domain
// (e.g. https://locadirect.cm) — defaults to the dev port used tonight.
export const SITE_URL = process.env.SITE_URL ?? "http://localhost:3002";

export const SITE_NAME = "LocaDirect CM";
