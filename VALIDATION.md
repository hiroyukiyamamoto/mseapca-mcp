# Validation

Local Windows R 4.4.0, mseapca 2.2.1 / loadings 0.6.1 / ellmer 0.5.0 / pinned mcptools:

- PASS: installed mseapca and XML; executed the real package functions.
- PASS: first ORA MVP matched official numerical output before other analyses were added.
- PASS: all five ORA modes, four range modes, quantitative MSEA and SSEA compared directly against official functions.
- PASS: real full fasting metabolome -> filtered Reactome ORA and quantitative MSEA; input/compute/output bounds and correction-before-truncation checks.
- PASS: official MCP HTTP client initialization, listing all nine tools, calls to every tool and all four analysis families; JSON precision round-trip, excluded/invalid input rejection.
- PASS: complete filtered catalog string/key audit (4,741 records), count/provenance checks; worker timeout and recovery.
- PASS: local Edge browser, desktop 1440x1000 and mobile 390x844; image loading, internal anchors, pending endpoint text and no horizontal overflow. Static link/asset and actual example JSON checks passed.
- PASS: Linux R 4.5.2 and Docker CI on implementation commit 8b029de: https://github.com/hiroyukiyamamoto/mseapca-mcp/actions/runs/38930283826 . Docker built successfully, started on PORT=8081, passed official MCP client tests for all tools/analysis families, rejected oversized bodies (413), throttled bursts (429), and recovered.

At initial implementation, cloud deployment and public Pages were unverified. The authorized deployment results below supersede that initial state; public MCP IAM remains unchanged.

Scientific scope: exact namespace matching only; no species conversion or classifier validation. The real-data ORA demo applies human snapshot sets to mouse metabolites for software illustration, not validated cross-species inference. Pathway licenses are separate; commercial clearance is unresolved for some sources. See DATA_SOURCES.md.
- PASS: read-only Google Cloud preflight: current project identified, no same-name service, existing shared JPY400 Cloud Run spend cap verified before the later authorized update recorded below.

## Cloud validation after authorized private deployment

- PASS: Pages publication through GitHub Actions; actual public site checked in Edge at desktop1440x1000 and mobile390x844, including image loading, internal anchors and horizontal layout.
- PASS: Cloud Build 6ec46089-cc0f-4882-840c-cc939d7a233a; immutable image deployed to private Cloud Run revision mseapca-mcp-00001-td9.
- PASS: authenticated official R MCP client on the actual Cloud Run endpoint: initialize, nine tools, all tool calls, ORA/range/MSEA/SSEA, exact JSON precision and invalid/excluded identifiers.
- PASS: real endpoint anonymous403, malformed JSON400, unknown method -32601, recovery initialize; body413, rate429 and cooldown recovery.
- PASS: existing shared Cloud Run spend cap increased to JPY1,000 with approval and verified CONFIGURED; scope unchanged. Amount is not a total invoice guarantee.
- OBSERVED: built-in memory distribution sample means up to 56.91% (~291.4MiB), two points during demo tests. Not peak/worst-case capacity. No new monitoring service was configured.

Remaining unverified: anonymous public MCP service (not authorized/published), actual ChatGPT/Claude sessions, worst-case capacity, actual invoice totals and spend-cap enforcement under exhaustion. See DEPLOYMENT.md for exact state, costs and emergency stop.
- PASS: latest deployed Pages content displays the actual private endpoint on both viewports; the browser test now bypasses its cache and can assert EXPECTED_ENDPOINT to avoid accepting an old deployment.
- Latest follow-up CI: https://github.com/hiroyukiyamamoto/mseapca-mcp/actions/runs/38932888676 . Docker job PASS (including all tools through the gateway). Linux standalone job was still preparing R at the reporting point and is not claimed as completed; the prior implementation's Linux job passed as recorded above. Actual private Cloud Run tests independently passed on the deployed Linux image.
