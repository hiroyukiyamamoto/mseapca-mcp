# Deployment and operations

## Current status

- Site: https://hiroyukiyamamoto.github.io/mseapca-mcp/ — published through GitHub Actions.
- Project / region: `stable-century-479407-m7` / `asia-northeast1`.
- Service / revision: `mseapca-mcp` / `mseapca-mcp-00001-td9`, ready, 100% traffic.
- Endpoint: https://mseapca-mcp-121643671058.asia-northeast1.run.app/mcp .
- Access: **private, Google Cloud IAM required**. No allUsers/allAuthenticatedUsers bindings; anonymous initialize returns 403. Public access awaits separate approval.
- Runtime: existing role-free `loadings-mcp-runtime@stable-century-479407-m7.iam.gserviceaccount.com`; permissions were not changed.
- Resources: 1 CPU, 512 MiB, request CPU billing, startup CPU boost; min0/max1 at service/revision levels, concurrency1, timeout30s.

The user approved Pages publication, private image build/deployment and increasing the existing shared Cloud Run spend cap to **JPY1,000/month**. No other service or service IAM was changed. No APIs or additional paid monitoring services were enabled.

## Cost protection

The existing spend-cap budget `fe0177db-e81e-494f-a512-4b1e7343ec0f` under billing account `01CD48-09CB81-E1885D` was increased from JPY400 to JPY1,000, retaining project `121643671058`, Cloud Run service `152E-C115-5142`, monthly period and EXCLUDE_ALL_CREDITS. Output state was re-read as CONFIGURED. The update asserted the prior state was CONFIGURED/not reconciling and used etag to prevent a concurrent state change; no enforced cap was lifted. The separate JPY500 project alert remains unchanged as an early warning; account-wide alerts were untouched.

**JPY1,000 is a shared Cloud Run stop threshold, not a guaranteed total invoice ceiling.** It is not an additional allowance for each MCP. Reporting/enforcement can lag and in-flight work can finish. Cloud Build, Artifact Registry, retained source objects, network/taxes or other bill items are not guaranteed covered. Other services sharing the cap can be paused when it is reached. Do not automatically lift an enforced cap.

Reverify before any deployment:

```sh
GOOGLE_CLOUD_PROJECT=stable-century-479407-m7 \
APPROVE_SHARED_PROJECT=stable-century-479407-m7 \
BILLING_ACCOUNT_ID=01CD48-09CB81-E1885D \
Rscript --vanilla scripts/spend-cap.R verify
```

## Build and deployment

Standalone build: `docker build -t mseapca-mcp .`.
The optional `Dockerfile.cached` reuses a previously verified immutable R dependency image, installs mseapca 2.2.1, checks package versions, and copies this project's R/data/gateway. It does not call or modify the loadings-mcp service. Both paths use the same pinned analysis packages.

Cloud Build `6ec46089-cc0f-4882-840c-cc939d7a233a` succeeded with a 300-second deadline and no API/IAM changes. Deployed image:

```text
asia-northeast1-docker.pkg.dev/stable-century-479407-m7/cloud-run-source-deploy/mseapca-mcp@sha256:781fa6a6e2ad0a3a81285c2b5ffa228f1000f4a21add71e5d0b3800c02332ec6
```

`scripts/deploy.sh` remains private by default, verifies the configured <=JPY1,000 cap and asks before deployment. Specify GOOGLE_CLOUD_PROJECT, IMAGE, RUNTIME_SERVICE_ACCOUNT, BILLING_ACCOUNT_ID and APPROVE_SHARED_PROJECT. It targets only mseapca-mcp in asia-northeast1. New builds or deployments need authorization; unrelated services must not be changed.

## Private endpoint tests

For an authorized Google Cloud user, PowerShell:

```powershell
$env:MCP_ENDPOINT='https://mseapca-mcp-121643671058.asia-northeast1.run.app/mcp'
$env:CLOUD_RUN_ID_TOKEN=(gcloud auth print-identity-token --quiet)
try {
  Rscript --vanilla tests/http.R
  Rscript --vanilla scripts/check-remote-http.R
  Rscript --vanilla scripts/check-limits.R
} finally { Remove-Item Env:CLOUD_RUN_ID_TOKEN }
```

The token stays in process environment and is never printed, committed or written into MCP config files. IAM identity tokens are not an OAuth service for end-user MCP clients. Manual ChatGPT/Claude connections remain unverified.

Authenticated official R MCP tests passed for initialization, nine-tool listing, every tool, all four analysis families, precision and invalid inputs. Actual endpoint checks passed: anonymous403, malformed JSON400, unknown method -32601, initialize recovery, body413, rate429 and recovery. Gateway limits: 2MiB, shared60/minute with burst10, worker20s, proxy25s. Per-instance throttling is not comprehensive distributed DoS protection.

Built-in Cloud Run memory distributions during the demo tests had two points, with maximum sample mean 56.91% (~291.4 MiB of 512MiB). These are sample means, not instantaneous peaks or worst-case capacity guarantees. No out-of-memory failure occurred in the demo suite; upper-bound workloads and actual invoice totals remain unverified. Keep 512MiB until broader measurements justify a change.

## Monitoring and emergency stop

Use existing Cloud Run metrics for this service's requests, response classes, latency and memory, plus Billing reports filtered by project/service. No custom paid monitoring was added. Cap notifications occur at 50%, 80%, 100%; the early project alert is separate. Avoid repeated automated health checks that prevent scaling to zero.

The service is currently private. If anonymous access is approved later, stop it by removing only its allUsers invoker binding and verifying anonymous403. If invoker IAM checking was disabled, re-enable it as well. For an emergency full stop, delete only this service after approval:

```sh
gcloud run services delete mseapca-mcp --project stable-century-479407-m7 --region asia-northeast1
```

Deletion does not remove retained images/source archives or already incurred charges. Never disable shared project billing to stop one service.

## Pages

`.github/workflows/pages.yml` publishes docs by manual dispatch. Pages source is GitHub Actions (workflow). After approved site changes, push and run `gh workflow run pages.yml --repo hiroyukiyamamoto/mseapca-mcp`. Keep endpoint/access/authentication in docs/config.json consistent with actual IAM, and update setup text. The private URL must never be advertised as anonymously accessible.

## Prepared public-access proposal (not executed)

After separate final approval, grant anonymous invocation on this service only:

```sh
gcloud run services add-iam-policy-binding mseapca-mcp \
  --project stable-century-479407-m7 --region asia-northeast1 \
  --member=allUsers --role=roles/run.invoker
```

This does not change project-wide IAM or another service. Invoker IAM checking remains enabled. No extra paid product is required. After granting access, rerun tests/http.R, scripts/check-remote-http.R and scripts/check-limits.R without CLOUD_RUN_ID_TOKEN, then change docs/config.json access/authentication and setup text only if anonymous tests pass.

Residual risks to accept before this action: shared per-instance throttling is not distributed DoS protection; unregistered users can consume the shared cap; the JPY1,000 limit applies to all Cloud Run services in the project and can pause existing services; reporting delays and non-Run costs can exceed the target. Statistical and source-license limits still apply. Manual ChatGPT/Claude compatibility is not claimed until actually tested.

Rollback for anonymous access:

```sh
gcloud run services remove-iam-policy-binding mseapca-mcp \
  --project stable-century-479407-m7 --region asia-northeast1 \
  --member=allUsers --role=roles/run.invoker
```

Verify anonymous403 afterward. Do not lift the shared spend cap to keep the service online.
