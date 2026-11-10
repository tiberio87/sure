# Italian Sure fork: upstream synchronization and private releases

This repository is a **fork** of [we-promise/sure](https://github.com/we-promise/sure).
The fork exists to run the Italian localization while work is proposed upstream.

## Branches

- `main`: tracks the original Sure code, with only fork-specific CI maintenance files.
- `i18n/italian-complete`: tested Italian deployment branch. It also retains the
  existing draft fork PR #1 for translation review.
- `bot/sure-upstream-main`: temporary bot-owned PR branch targeting `main`.
- `bot/sure-main-to-italian`: temporary bot-owned PR branch targeting
  `i18n/italian-complete`.

**Do not force-push or commit by hand to the two `bot/` branches.** The
maintenance workflow rebuilds them with `--force-with-lease`.

## Weekly flow

`.github/workflows/fork-maintenance.yml` runs Mondays at 04:17 UTC and
supports manual dispatch. It compares upstream `main` with the fork and
proposes a merge to the fork's `main` through a **draft PR**. No automatic
conflict resolution, PR merge or cluster deployment is performed.

The same workflow runs on pushes to fork `main` and proposes a second
**draft PR** to merge the latest fork `main` into
`i18n/italian-complete`. The first job is independent of the second:
merge upstream into `main` first, then merge `main` into Italian.

If a merge has conflicts, the job fails and prints Git errors; manually
resolve conflicts and test the changes instead of overwriting translations.

## GitHub setup and CI

- Enable GitHub Actions on this fork if currently disabled.
- In repository **Settings > Actions > General**, allow workflows to create
  pull requests. The workflow's `GITHUB_TOKEN` requests
  `contents: write` and `pull-requests: write` only for maintenance.
  If repository policy does not permit automated PR creation, keep it
  restricted and create PRs manually from the pushed `bot/` branches.
- PRs created by `GITHUB_TOKEN` do **not** normally trigger
  `pull_request` workflows. Before merging a bot PR, manually dispatch
  the upstream `Pull Request` workflow on its branch, e.g.:

```bash
gh workflow run pr.yml --repo tiberio87/sure --ref bot/sure-upstream-main
gh workflow run pr.yml --repo tiberio87/sure --ref bot/sure-main-to-italian
```

Wait for success and review the diff. A workflow started by hand is a
validation aid, not a substitute for code review.

To ask the maintenance workflow to check both branches right now:

```bash
gh workflow run fork-maintenance.yml --repo tiberio87/sure --ref main
```

The original Sure repository contains its own `publish.yml` that may
run on pushes to fork `main` and on its schedule when Actions are enabled.
The inherited `Publish Docker image` workflow has a repository guard:
its `prepare` job runs **only** for `we-promise/sure`. All release jobs depend
on it, so even scheduled and `main` push events in the fork are skipped.
Do not remove this fork guard when merging upstream changes; it prevents
unlocalized builds and unrelated upstream releases. Our independent
Italian publisher below uses a separate GHCR package.

## Italian image publishing

`.github/workflows/publish-italian.yml` runs on each push to the Italian
branch and can be dispatched manually. It requires locale validation and
the existing upstream Sure CI before building and pushing one
`linux/amd64` OCI image to:

```text
ghcr.io/tiberio87/sure-italian:sha-<full-commit-sha>
```

The workflow publishes the resulting immutable digest in its GitHub Actions
summary. The initial package may be private: make it **public** under
GitHub Packages or configure a Kubernetes imagePullSecret before deployment.

For Flux GitOps in `tiberio87/r0cks-home-ops`, pin the **digest** from the
successful build. Update production only through a separate reviewed
GitOps PR. Build completion alone never rolls out the application.

Use the **same** digest for the Sure web and Sidekiq worker workloads.
Back up Postgres and persistent uploads, configure explicit Active Record
encryption keys, and verify DB migration compatibility before upgrades.
Store encryption keys outside Git (e.g. via 1Password and External Secrets).

## Translation contributions upstream

The existing upstream [#3683](https://github.com/we-promise/sure/pull/3683)
also adds Italian strings. Coordinate with its author and submit only
well-attributed, non-duplicate translations in a separate contribution
branch. The deployment branch is not automatically suitable as an
upstream PR because it contains fork-specific workflows.
