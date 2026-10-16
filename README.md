# mseapca MCP

Metabolite set enrichment for AI agents, using R, **mseapca 2.2.1** and the official **mcptools HTTP server**. Package algorithms are unchanged. No arbitrary R execution or remote AI/database calls are exposed.

Repository: https://github.com/hiroyukiyamamoto/mseapca-mcp

Site: https://hiroyukiyamamoto.github.io/mseapca-mcp/ (published with GitHub Actions).
Hosted MCP: https://mseapca-mcp-121643671058.asia-northeast1.run.app/mcp — **free public research access; no registration, API key or authentication required**. Anonymous tests passed for all nine tools. Best-effort service; rate limits and budget pauses apply.

## What is included

Nine tools: `catalog_info`, `search_sets`, `get_sets`, `lookup_metabolites`, `demo_data`, `analyze_ora`, `analyze_range`, `analyze_msea`, `analyze_ssea`.

- Five official ORA background modes, four uncertainty-range modes, quantitative MSEA and presence-list SSEA.
- A filtered snapshot of the requested `AI/apps/mseapca-db-web` database: **4,741 sets, eight sources**.
- KEGG-origin sets, cross-reference fields and compound identifiers are excluded. Built-in mseapca pathway datasets are never loaded. See [DATA_SOURCES.md](DATA_SOURCES.md).
- The default demo is the full real `loadings::fasting` metabolome (10 samples, 282 metabolites), with explicitly exploratory cross-species ORA. No invented experimental measurements.
- Website uses the same minimal sage/white design as loadings MCP.

## Local setup

Use R 4.5.2 for the pinned production build. System dependencies: libcurl, OpenSSL, libxml2, libuv, zlib, build tools and cmake (see Dockerfile).

```sh
Rscript --vanilla scripts/install.R
PORT=8080 Rscript --vanilla R/server.R
```

On PowerShell: `$env:PORT='8080'` then `Rscript --vanilla R/server.R`.
The official mcptools server binds `0.0.0.0`, serves `/mcp`, and disables session R tools. Direct R startup is for trusted local development; public hosting must use the Docker gateway with request/rate limits.

```sh
docker build -t mseapca-mcp .
docker run --rm -e PORT=8080 -p 8080:8080 mseapca-mcp
claude mcp add --transport http mseapca-mcp http://localhost:8080/mcp
```

This local command is supported by Claude Code's HTTP transport. A real Claude/ChatGPT session is not yet verified. Hosted connection (no authentication header required):

```sh
claude mcp add --transport http mseapca-mcp https://mseapca-mcp-121643671058.asia-northeast1.run.app/mcp
```

This follows the [official Claude Code HTTP syntax](https://code.claude.com/docs/en/mcp). See [example MCP configuration](examples/mcp-config.json). Official R MCP client tests passed; manual ChatGPT/Claude sessions remain unverified.

## Using the tools

1. Call `catalog_info` and `search_sets` to inspect available sources and organisms.
2. Choose at least two set IDs and a single identifier namespace. `get_sets` previews members (truncation is explicit).
3. Call `analyze_ora` with significant IDs, the measured background, and `set_ids`. For a reproducible example, use `demo_data()` and pass its significant, detected, set_ids and identifier.
4. Use `analyze_msea` for a quantitative samples-by-metabolites matrix and response; use `analyze_ssea` for sample presence lists.

Matching is literal: names are case-folded; other identifiers are uppercased. There is no synonym, species or identifier conversion. Custom sets use `{"sets":[{"name":"A","members":["a","b"]},...]}`. Do not mix namespaces.

Results are full-precision JSON in official MCP text content, including `ok`, conditions, warnings, truncation and errors. Nonfinite statistics use the string `not_finite`; never interpret these as zero. [Full API](docs/api.md).

## Validation

```sh
Rscript --vanilla tests/models.R
Rscript --vanilla tests/database.R
Rscript --vanilla tests/limits.R
Rscript --vanilla tests/http.R
Rscript --vanilla examples/generate.R
node tests/site.mjs
```

See [VALIDATION.md](VALIDATION.md) for actual results and limitations. GitHub Actions runs Linux R tests and builds/tests the Docker image. [DEPLOYMENT.md](DEPLOYMENT.md) describes approval-gated Cloud Run and Pages publication.

## Limits and costs

The gateway enforces 2 MiB/request and shared 60 requests/minute, burst 10. Each analysis runs in a disposable R worker with a 20-second wall-clock limit. Analyses restrict matrix dimensions, memberships, permutations and output. These controls do not establish a monetary ceiling or distributed DoS protection.

Deployment is private by default, with min instances 0, max 1, concurrency 1, request CPU billing and timeout 30 seconds. A verified spend cap and separate final approval are required before anonymous public access. The existing shared Cloud Run cap was increased from JPY400 to JPY1,000 with user approval; existing services and IAM were otherwise unchanged. The separate JPY500 project alert remains an early warning, not a cap. A shared Cloud Run cap can affect other services; build/storage charges are separate and caps may overshoot. Do not claim a guaranteed JPY1,000 total bill.

## License

Wrapper and website: MIT. mseapca/loadings: LGPL-3. Data is **not MIT-licensed**; source terms apply, including PathBank commercial restrictions and unresolved terms for some sources. Read [DATA_SOURCES.md](DATA_SOURCES.md) before redistribution or commercial use.

Developer: Hiroyuki Yamamoto.
