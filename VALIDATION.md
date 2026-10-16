# Validation

Local Windows R 4.4.0, mseapca 2.2.1 / loadings 0.6.1 / ellmer 0.5.0 / pinned mcptools:

- PASS: installed mseapca and XML; executed the real package functions.
- PASS: first ORA MVP matched official numerical output before other analyses were added.
- PASS: all five ORA modes, four range modes, quantitative MSEA and SSEA compared directly against official functions.
- PASS: real full fasting metabolome -> filtered Reactome ORA demo.
- PASS: official MCP HTTP client initialization, listing all nine tools, calls to every tool and all four analysis families; JSON precision round-trip, excluded/invalid input rejection.
- PASS: complete filtered catalog string/key audit (4,741 records), count/provenance checks; worker timeout and recovery.
- Website and Linux/Docker CI: results updated after execution.

Not verified: Cloud Run deployment, cloud cost/memory profiling, actual ChatGPT or Claude sessions, public remote endpoint. No deployment, billing, API enablement or public IAM changes have been performed for this new service. Planned site URL is not proof of publication.

Scientific scope: exact namespace matching only; no species conversion or classifier validation. The real-data ORA demo applies human snapshot sets to mouse metabolites for software illustration, not validated cross-species inference. Pathway licenses are separate; commercial clearance is unresolved for some sources. See DATA_SOURCES.md.
