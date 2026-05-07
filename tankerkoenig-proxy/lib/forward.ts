// Shared helper for the three Tankerkönig Edge Functions in api/json/.
// Verifies the request method, attaches the API key from Vercel's encrypted
// environment, forwards to creativecommons.tankerkoenig.de, and pipes the
// upstream response straight back to the client. No caching, no body buffering
// — Tankerkönig's terms only allow on-demand pass-through, never a mass mirror
// (see docs/TANKERKOENIG_CACHING.md in the FuelNow repo).

const TARGET = "https://creativecommons.tankerkoenig.de";

export type TankerkoenigEndpoint = "list.php" | "prices.php" | "detail.php";

export async function forward(req: Request, file: TankerkoenigEndpoint): Promise<Response> {
    if (req.method !== "GET") {
        return new Response("Method not allowed", { status: 405 });
    }

    const apiKey = process.env.TANKERKOENIG_API_KEY;
    if (!apiKey) {
        return new Response("Proxy misconfigured: TANKERKOENIG_API_KEY missing", { status: 500 });
    }

    const incoming = new URL(req.url);
    const upstream = new URL(`${TARGET}/json/${file}${incoming.search}`);
    upstream.searchParams.set("apikey", apiKey);

    const upstreamResponse = await fetch(upstream, {
        method: "GET",
        headers: { accept: "application/json" },
    });

    return new Response(upstreamResponse.body, {
        status: upstreamResponse.status,
        headers: {
            "content-type": upstreamResponse.headers.get("content-type") ?? "application/json",
            "cache-control": "no-store",
        },
    });
}
