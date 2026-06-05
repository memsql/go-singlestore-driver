# Releasing

Production releases use **semver tags** on `master` (for example `v2.0.0`, `v2.0.1`). Go resolves
versions from these tags; update [CHANGELOG.md](CHANGELOG.md) and related docs, then push a tag.

Older tags like `v1.9.3-p0` used a fork-specific `-pN` suffix. Do **not** use that pattern for new **production**
releases.

## Steps

### 0. Update Changelog:

- Confirm CI is green on the commit you will tag ([Test workflow](.github/workflows/test.yml)).
- Move [CHANGELOG.md](CHANGELOG.md) notes from `## Unreleased` into a new section:

```markdown
## Unreleased

## vX.Y.Z (YYYY-MM-DD)

- user-facing change (#123)
```

- Update [README.md](README.md) if this release requires it.
- Open a Pull Request to `master` with a commit such as `chore: prepare for release X.Y.Z`.

### 1. After the PR with update is merged, make sure you are on the latest commit in `master`:

```bash
git checkout master
git pull origin master
```

### 2. Tag and push:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

Pushing `v*.*.*` triggers [.github/workflows/release.yml](.github/workflows/release.yml): run tests,
then create a GitHub release (initially marked as a **pre-release**).

### 3. Finalize on GitHub

1. Open **Actions → Release** and wait for the workflow to succeed.
2. Open the new release under **Releases**.
3. Edit the release body: summarize user-facing changes, link to the CHANGELOG section, drop
   `chore:` / CI noise from the auto-generated notes.
4. Uncheck **Set as a pre-release** and mark it as the latest release.

## If something goes wrong

- **Tests failed after tagging:** fix `master`, delete the tag on GitHub and locally, then tag again.
- **Wrong tag or bad release:** delete the tag and GitHub release, then create a new semver tag.
  Do not force-push or reuse a tag that was already published.

Users install a release with:

```bash
go get github.com/singlestore-labs/go-singlestore-driver@vX.Y.Z
```
