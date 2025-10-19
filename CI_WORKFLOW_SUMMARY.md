# CI Workflow Summary for Fork

This document explains which CI workflows are active and why.

## ✅ Active on Feature Branches

### 1. **fork-ci.yml** - Basic Unit Tests
- **Triggers:** Push to `feature/**` branches, Pull Requests
- **Duration:** ~5-10 minutes
- **What it does:**
  - Runs unit tests for REST API
  - Clippy linting
  - Code formatting checks
- **Why:** Fast feedback on code quality

### 2. **snapshot-rebuild-test.yml** - Snapshot Rebuild Verification
- **Triggers:** Push to `feature/**` branches, Manual
- **Duration:** ~20-25 minutes
- **What it does:**
  - Builds all binaries
  - Pre-pulls Docker images
  - Attempts to run integration tests with deployer
- **Why:** Verifies snapshot rebuild functionality
- **Note:** May fail on resource-constrained runners

### 3. **pr-commitlint.yml** - Commit Message Linting
- **Triggers:** Pull Requests, Push to staging and `feature/**`
- **Duration:** <1 minute
- **What it does:**
  - Validates commit messages follow conventional format
  - Checks for duplicate commits
- **Why:** Ensures clean git history for upstream PR

### 4. **pr-submodule-branch.yml** - Submodule Validation
- **Triggers:** Pull Requests, Push to develop, release, staging, `feature/**`
- **Duration:** <2 minutes
- **What it does:**
  - Verifies submodules point to correct branches
  - Checks submodule HEAD alignment
- **Why:** Prevents submodule branch mismatches
- **Note:** May warn about missing `ORG_CI_GITHUB` secret (expected in forks)

## 📋 Manual Trigger Only

### 5. **fork-quick-integration.yml** - Quick Integration Test
- **Triggers:** Manual (`workflow_dispatch`)
- **Duration:** ~10 minutes
- **What it does:**
  - Starts minimal cluster without io-engine
  - Tests metrics endpoint
  - Runs unit tests
- **Why:** Quick sanity check without full integration

### 6. **fork-integration-tests.yml** - Full Integration Tests
- **Triggers:** Manual with options
- **Duration:** 60-90 minutes (if building io-engine)
- **What it does:**
  - Optionally builds io-engine from source
  - Runs full integration test suite
- **Why:** Deep testing when needed
- **When to use:** Before major PR submission

## ❌ Disabled (Won't Work in Fork)

### 7. **pr-ci.yml** - Bors CI (Upstream)
- **Why disabled:** Requires `oracle-vm-16cpu-64gb-x86-64` self-hosted runners
- **What it does:** Runs full upstream CI suite (lint, unit, integration, BDD, image builds)
- **Alternative:** Will run automatically when PR is submitted to upstream

### 8. **nightly-ci.yml** - Nightly CI (Upstream)
- **Why disabled:** Wrapper for pr-ci.yml, same resource requirements
- **Alternative:** Upstream will run their nightly tests

### 9. **unit-int.yml** - Integration CI (Upstream)
- **Why disabled:** Called by pr-ci.yml, needs self-hosted runners
- **Alternative:** Use fork-integration-tests.yml for local testing

### 10. **bdd.yml**, **image.yml**, **image-pr.yml** - Build/Test Workflows
- **Why disabled:** Part of upstream CI infrastructure
- **Alternative:** Will run when PR is merged upstream

## Workflow Decision Tree

```
┌─────────────────────────────────┐
│   Push to feature/** branch     │
└────────────┬────────────────────┘
             │
             ├──> fork-ci.yml (unit tests, linting)
             ├──> snapshot-rebuild-test.yml (build + integration attempt)
             ├──> pr-commitlint.yml (commit message validation)
             └──> pr-submodule-branch.yml (submodule check)

                  All complete in ~25 minutes

┌─────────────────────────────────┐
│   Need deeper testing?          │
└────────────┬────────────────────┘
             │
             └──> Manual: fork-integration-tests.yml
                  (full integration, 60-90 min)

┌─────────────────────────────────┐
│   Submit PR to upstream?        │
└────────────┬────────────────────┘
             │
             └──> Upstream CI runs automatically
                  (pr-ci.yml, nightly-ci.yml, etc.)
```

## GitHub Actions Usage

Approximate minutes per push to feature branch:
- fork-ci: 5-10 min
- snapshot-rebuild-test: 20-25 min
- pr-commitlint: <1 min
- pr-submodule-branch: <2 min
- **Total: ~25-40 minutes per push**

GitHub Actions free tier: 2,000 minutes/month
Estimated pushes per month: ~50-80 pushes

## Best Practices

1. **Before each push:**
   - Run `cargo test` locally
   - Run `cargo clippy` locally
   - Run `cargo fmt` locally
   - Check commit messages follow conventions

2. **Before PR submission:**
   - Ensure all automated workflows pass
   - Consider running `fork-integration-tests.yml` manually
   - Review CI logs for any warnings

3. **Resource management:**
   - Automated workflows only on feature branches
   - Manual workflows for deep testing
   - Let upstream CI handle final validation

## Troubleshooting

### "ORG_CI_GITHUB secret not found"
- **Expected in forks** - This secret is only in upstream org
- Workflow will fall back to default GITHUB_TOKEN
- No action needed

### "Test failed due to timeout"
- **Common on standard GitHub runners** - Limited resources
- Check if build succeeded (primary goal)
- For full integration tests, use fork-integration-tests.yml manually

### "Submodule branch mismatch"
- Run `./scripts/git/set-submodule-branches.sh --branch develop`
- Commit .gitmodules changes
- Push again

## Summary

Your CI setup strikes a good balance:
- ✅ Fast feedback on code quality (fork-ci)
- ✅ Build verification (snapshot-rebuild-test)
- ✅ Git hygiene (pr-commitlint, pr-submodule-branch)
- ✅ Optional deep testing (manual workflows)
- ✅ Efficient resource usage
- ✅ Ready for upstream PR submission
