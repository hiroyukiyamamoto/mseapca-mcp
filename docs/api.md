# MCP input and output specification

All nine tools return JSON text in an MCP text content block. Decode the text once. Success has `ok:true`, `schema_version`, `warnings`; errors have `ok:false`, `error.code`, `error.message`, `warnings`. Worker timeouts have code `computation_timeout`. Invalid scientific inputs return structured errors; malformed MCP/schema requests may instead return protocol errors from mcptools.

## Database tools

- `catalog_info()`: snapshot provenance, 4,741 sets and eight source counts.
- `search_sets(query="",source="",organism="",limit=25,offset=0)`: literal case-insensitive text search; optional exact source, organism substring; limit 1-100, offset 0-10000. Returns total, returned, offset, truncated and metadata.
- `get_sets(set_ids,identifier="name",max_members=100)`: 1-50 unique IDs, member limit 1-500 per set. Returns source metadata and truncation. Returned previews are not used internally to truncate analyses.
- `lookup_metabolites(query,exact=TRUE,limit=25)`: literal lookup of retained names/identifiers. No inferred synonyms. Up to 100 results.
- `demo_data(dataset="fasting")`: real 10-by-282 fasting matrix, PC1 response, significant/detected identifiers and selected set IDs. Membership option returns an explicitly synthetic selection from real Reactome members.

## Common analysis fields

`set_ids=[]` selects database sets; `custom_sets={"sets":[{"name":"setA","members":["a","b"]},...]}` adds custom sets. At least two and at most 200 total unique sets; each custom set at most 1,000 members, overall at most 25,000 memberships and 10,000 unique IDs. Duplicate custom memberships are canonicalized. Excluded identifiers and unknown set IDs are rejected, with no fallback source.

`identifier="name"` supports name/hmdb/chebi/inchikey/pubchem. Names are case-folded; other identifiers uppercased. One namespace per call, no conversion. Database sets without usable members in that namespace are rejected. SIG and DET must be unique after normalization. Query text up to 200 characters, identifier strings up to 1,024 characters. No KEGG identifiers are accepted even in custom sets.

- `analyze_ora(significant,detected=[],set_ids=[],custom_sets={},identifier="name",method="det",lambda=5,max_results=50)`: method det/all/est_naive/est_weighted/est_shrink. SIG subset of DET except all requires SIG within the selected-set universe. DET is required except all. Results include p.value, q.value, overlaps (at most 100 per result), 2x2 contingency tables, conditions and output counts.
- `analyze_range(significant,detected,...,method="bino_naive",nsim=100,lambda=5,probs=[0.025,0.975],max_results=50)`: method ora_full/bino_naive/bino_weighted/bino_shrink. Simulations 10-1000 and at most 100,000 set-simulation combinations. Full enumeration at most 10,000 configurations. Quantiles bracket 0.5. See upstream fixed-seed caveat in research.md.
- `analyze_msea(x,metabolite_ids,y,...,maxiter=100,seed=1,max_results=50)`: x={"rows":[[...],...]}, sample rows, 4-200 samples, 3-500 unique metabolite columns, at most 50,000 cells. Finite values, nonconstant features and response; aligned y. Nonoverlapping sets are explicitly dropped; at least two remaining sets, none covering every feature. 10-1000 permutations, at most five million feature-set-iteration combinations. Returns upstream NES, p, permutation q and leading-edge output.
- `analyze_ssea(samples,detected,... )`: samples={"samples":[{"name":"sample1","members":["a","b"]},...]}; 1-100 unique sample names, members must be subsets of common DET. At most 25,000 sample memberships and 10,000 output scores. Returns sample labels, set IDs and rows in sample-by-set order, negative natural log p.

For the first three analyses, max_results is 1-200; ordering and truncation happen after statistical correction. Positive lambda is bounded to 1,000. Nonfinite values are represented by `not_finite`, counted explicitly, never rounded to zero. Conditions identify actual method and statistical assumptions. Warnings from upstream are retained. Tool text serialization uses full precision.

Production gateway: 2 MiB HTTP body, 60 requests/minute shared per instance, burst 10; workers 20 seconds, gateway timeout 25 seconds, Cloud Run 30 seconds. These limits are resource safeguards, not a strict bill cap. Direct R startup omits gateway limits and is for trusted local use.
