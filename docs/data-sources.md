# Database provenance and terms

The requested source is `hiroyukiyamamoto/AI/apps/mseapca-db-web/seed_data/default_pathways.json`, pinned to commit `1fa2e6b7a479429e2842c60c15208d105e8473db`, blob `e51a166b71647a1bcdaf9c3ac0a3e9e393620c24`. The source repository requires access. No application code, accounts, authentication files or monitoring jobs are copied.

The immutable normalized snapshot is `data/catalog.json.gz`; `data/manifest.json` records provenance and counts. From 5,046 records, 305 KEGG-origin sets are excluded. All KEGG cross-reference fields (75,117), restricted identifiers and incompatible metadata are removed; 35 metabolite records lacking independent usable identification are dropped. The build allowlists eight sources and retained fields; unknown sources are rejected. Tests scan every retained string and key. Raw source exports remain ignored and must not be committed. The audit is a technical exclusion check, not a legal determination about every upstream record.

| Source | Sets | Terms / status |
|---|---:|---|
| Reactome | 1,731 | Data CC0: https://reactome.org/license |
| WikiPathways | 599 | Content CC0: https://sandbox.wikipathways.org/terms.html |
| PathBank | 870 | Noncommercial terms; commercial permission required: https://pathbank.org/about/ |
| integMET | 932 | No general redistribution/commercial license verified in this audit |
| ILDMDB | 60 | No general redistribution/commercial license verified in this audit |
| MACdb | 17 | No general redistribution/commercial license verified in this audit |
| ProMENDA | 514 | No general redistribution/commercial license verified in this audit |
| MetSigDis | 18 | No general redistribution/commercial license verified in this audit |

Source attribution and supplied descriptions remain in the snapshot. Study metadata is not a verified chemical or disease-direction assertion. Exclusion of KEGG does not license other sources. The project's MIT license covers wrapper/site code, not these data. License clearance for unrestricted commercial redistribution remains unresolved for the sources indicated above; do not advertise this snapshot as universally unrestricted. Source-provider terms and relevant original-study rights continue to apply.

To rebuild with authorized source access, download the pinned JSON locally into `.reference/default_pathways.json`, then run `Rscript scripts/build-database.R`. Never use bundled mseapca `pathway` or `fasting_mseapca` pathways as a fallback. No live external identifier resolution or AI search is performed.
