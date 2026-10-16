# Verified upstream APIs

Verified against CRAN mseapca 2.2.1 source and installed package, with loadings 0.6.1. See https://cran.r-project.org/package=mseapca and its reference manual.

| Function | Actual signature / behavior |
|---|---|
| msea_ora | SIG, DET=NULL, M, option="det", lambda=NULL; det/all/est_naive/est_weighted/est_shrink |
| msea_ora_range | SIG, DET=NULL, M, option="ora_full", probs=c(.025,.975), nsim=1000, lambda=5 |
| msea_sub | M, D, y, maxiter=1000; D has metabolite ID in first column, sample columns thereafter |
| ssea_ora | det_list, det_all, M; sample presence-list ORA, negative natural log p |

`analyze_msea` explicitly transposes samples-by-metabolites input into the official D layout. Its permutations randomize metabolite-set membership, not sample labels. Its q-values use the upstream permutation procedure; ORA uses Benjamini-Hochberg. Range outputs do not receive invented q-values. All correction families use the complete selected collection before output truncation.

Range methods: ora_full, bino_naive, bino_weighted, bino_shrink. Full enumeration reports upstream min/median/max; do not call these confidence bounds. Simulation uses upstream's fixed internal seed 1. Some inputs can trigger upstream invalid-contingency errors; these are returned as errors without replacing the algorithm.

Exported parsing helpers (csv2list, read_pathway, list2xml, pathbank2list) are not exposed because tools accept structured inputs and a fixed snapshot, not arbitrary files/XML/URLs. Upstream built-in pathway datasets are never used.

mcptools official `mcp_server(tools=...,type="http",host="0.0.0.0",port=PORT,session_tools=FALSE)` registers official `ellmer::tool` objects. Revision ff94da04ccb5e6e86a56537c9d2dcb0e0532067b provides these APIs: https://github.com/posit-dev/mcptools and https://posit-dev.github.io/mcptools/ . Tool results use official ellmer ContentText to preserve full JSON precision instead of mcptools' four-decimal structured-content serializer. The MCP protocol is not reimplemented.
