# Maintaining the Italian Sure fork

This fork intentionally tracks `we-promise/sure` upstream while retaining
Italian translations in `i18n/italian-complete`.

## Branches and ownership

- `main`: upstream application code, plus **fork-only automation** and
  a guard to disable the official image release publisher in this fork.
- `i18n/italian-complete`: `main` plus Italian locale changes.
- `sync/upstream-*` / `sync/italian-*`: temporary PR branches.
- No automatic merge and **no direct deployment** to the home Kubernetes cluster.

## Weekly updates

`Fork - upstream sync PRs` runs every Monday at 04:23 UTC and on demand.
It proposes a PR to merge `we-promise/sure:main` into this fork's `main`.
It also proposes a PR to merge this fork's current `main` into the Italian
branch. A merge conflict fails the sync job and requires manual resolution;
neither side is silently overwritten.

If the fork is already current, no PR is needed. The default `main` has
fork-specific workflow files so it will diverge slightly from upstream; this
is intentional, and upstream updates are **merged**, not force-pushed.

**One-time GitHub settings:** enable Actions in this fork, and under
Settings → Actions → General → Workflow permissions allow GitHub Actions
to create pull requests. Otherwise a sync job can reach `gh pr create`
and fail. PRs opened by `GITHUB_TOKEN` may not automatically trigger
other GitHub Actions checks; run and review checks manually as needed.

## Publishing the Italian image

After `main` is merged into `i18n/italian-complete`, its
`Fork - Italian Docker image` workflow is available on that branch.
On a push to the Italian branch, existing Sure CI and
`scripts/check-italian-locales.rb` must pass before an amd64 image is
published to GHCR:

`ghcr.io/tiberio87/sure:it-<full git SHA>`

The image job also prints `ghcr.io/tiberio87/sure@sha256:...`. Use that
**immutable digest** in the Flux GitOps repository. Publishing does not
modify `r0cks-home-ops` or deploy an image automatically. Both web and
worker must use the same digest.

Since all three home-cluster nodes are x86_64, the first build targets
`linux/amd64`. Add arm64 only when needed.

Production prerequisites are separate: create stable Rails encryption
secrets before user onboarding, set up PostgreSQL/pgvector and Redis,
persistent storage and backup/restore, and validate database migrations
for each upstream upgrade. Never reuse preview data or secret keys.

## Built-in upstream workflows

The existing `Publish Docker image` upstream workflow is guarded against
execution on the fork; it otherwise schedules nightly builds and would
publish non-Italian images from `main` using the same registry package.
Do not remove this guard while tracking upstream. Other upstream release
workflows should not be dispatched on this fork.

## Manual reconciliation

If automated PR creation is disabled or a merge conflict occurs, use a
local checkout and **create a PR** instead of pushing directly to a
protected or deployed branch:

```bash
git remote add upstream https://github.com/we-promise/sure.git # once
git fetch upstream main
git switch main
git merge upstream/main
git push origin main
git switch i18n/italian-complete
git merge main
```

The commands above describe the merge topology, not a preferred direct
push procedure. Use GitHub PRs for production-controlled changes.
