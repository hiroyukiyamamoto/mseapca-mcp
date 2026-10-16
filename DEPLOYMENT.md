# Deployment (not yet executed)

## GitHub Pages

The workflow `.github/workflows/pages.yml` publishes the existing `docs/` directory on manual dispatch. After approval, set repository Settings > Pages > Build and deployment > Source to **GitHub Actions**, then Actions > Publish GitHub Pages > Run workflow. Expected URL: https://hiroyukiyamamoto.github.io/mseapca-mcp/ . No domain change is needed. Endpoint is null until a verified hosted service exists.

## Cloud Run

Do not modify loadings-mcp or any existing service. The deployment script names only **mseapca-mcp**, region asia-northeast1. A new deployment incurs build/image storage charges and requires approval. The current project's previously configured spend cap must be reverified, not assumed to guarantee JPY500 total expenditure. It covers shared Cloud Run usage, not builds, registry storage or all bill items, and enforcement may lag.

1. Review current account/project, billing cap, service-name collision, least-privilege runtime identity and APIs. Do not enable APIs or change IAM/billing without approval.
2. Build/push an immutable image only after cost approval. Local: `docker build -t mseapca-mcp .`.
3. Set GOOGLE_CLOUD_PROJECT, IMAGE (prefer digest), RUNTIME_SERVICE_ACCOUNT, BILLING_ACCOUNT_ID and, for the current shared project, APPROVE_SHARED_PROJECT. Run `bash scripts/deploy.sh`. It checks the cap and asks before a **private** deployment.
4. Settings: 1 CPU/512 MiB initially (not measured yet), min0/max1, concurrency1, request billing, timeout30. Measure cold start, memory, execution time and HTTP tests before selecting final resources.
5. Run the official MCP client against the actual /mcp endpoint with authorized private access. Verify all nine tools, invalid inputs and limits.
6. Anonymous public IAM access needs separate final approval after costs and security protections are checked. No public authorization has been changed by this implementation.
7. Set docs/config.json endpoint and authentication only after verified deployment, update setup text and VALIDATION.md, then publish Pages.

The gateway is a lightweight shared rate limit, not comprehensive distributed DoS protection. Per-instance throttling and max1 are not monetary caps. Billing controls may affect every service sharing the cap. This script does not create or modify budgets.

Emergency stop for this service only: remove anonymous access if present and disable its public invoker setting as applicable, or delete **only** the mseapca-mcp service after approval: `gcloud run services delete mseapca-mcp --project PROJECT --region asia-northeast1`. Removing allUsers alone is insufficient if invoker IAM checking was disabled. Deletion does not remove retained images or already incurred charges. Never disable shared project billing to stop this one service.
