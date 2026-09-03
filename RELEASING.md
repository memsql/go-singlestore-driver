# Releasing

Production releases use **semver tags** on `master` (for example `v2.0.0`, `v2.0.1`). Go resolves versions from these tags; update [CHANGELOG.md](CHANGELOG.md) and related docs, then push a tag.

## Steps

### 1. Update Changelog

- Confirm CI is green on the commit you will tag ([Test workflow](.github/workflows/test.yml)).
- List commits since the latest release tag (skips `ci:`, `chore:`, and `test:`):

```bash
.github/scripts/list-release-changes.sh
```

- Turn the relevant items into user-facing bullets and add a new `## vX.Y.Z (YYYY-MM-DD)` section at the top of [CHANGELOG.md](CHANGELOG.md). Try to match the style of prior entries.
- Update [README.md](README.md) if needed.
- Open a PR with a commit such as `chore: prepare for release X.Y.Z`.

### 2. Sync with master

After the PR is merged, make sure you are on the latest commit in `master`:

```bash
git checkout master
git pull origin master
```

### 3. Tag and push

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

Pushing `v*.*.*` triggers [.github/workflows/release.yml](.github/workflows/release.yml): run tests, then create a GitHub release (initially marked as a **pre-release**).

### 4. Finalize on GitHub

You will need write access to **Releases** to complete this step.

1. Open **Actions -> Release** and wait for the workflow to succeed.
2. Open the new release under **Releases**.
3. Edit the release body: summarize user-facing changes, link to the CHANGELOG section, drop `chore:` / CI noise from the auto-generated notes. Note that the auto-generated notes come from GitHub's release-notes generator and are independent of `list-release-changes.sh` — the script is only an aid for writing CHANGELOG.md in step 1.
4. Uncheck **Set as a pre-release** and mark it as the latest release.

### 5. Verify the release is resolvable

Confirm the proxy has picked up the new tag:

```bash
go list -m github.com/singlestore-labs/go-singlestore-driver@vX.Y.Z
```

It may take a few minutes for [pkg.go.dev](https://pkg.go.dev/github.com/singlestore-labs/go-singlestore-driver) to index the new version.

## Driver-Server Version Compatibility Matrix

After each release, add a row for the new version rather than copying an older row's engine list. For each tag, take the list from the [EOL policy](https://docs.singlestore.com/db/v9.1/support/singlestore-software-end-of-life-eol-policy/) as of its release date and include any engine RC available by then.

| Driver Version | Release date | Supported engine versions |
| --- | --- | --- |
| 2.0.1 | 2026-06-08 | 8.9, 9.0, 9.1 RC |
| 2.0.0 | 2026-06-03 | 8.9, 9.0, 9.1 RC |
| 1.9.3-p0 | 2026-04-03 | 8.7, 8.9, 9.0, 9.1 RC |
| 1.9.2-p2 | 2026-02-11 | 8.7, 8.9, 9.0 |
| 1.9.2-p1 | 2026-02-03 | 8.7, 8.9, 9.0 |

## If something goes wrong

- **Tests failed after tagging:** fix `master`, delete the tag on GitHub and locally, then tag again. The release.yml workflow always publishes as a pre-release first (see step 4), so the failed run will also leave a pre-release that needs to be deleted.
- **Wrong tag or bad release:** delete the tag and the (pre-)release on GitHub, then create a new semver tag. Do not force-push or reuse a tag that was already published.

Users install a release with:

```bash
go get github.com/singlestore-labs/go-singlestore-driver@vX.Y.Z
```

## Background: legacy `-pN` tags

Older tags like `v1.9.3-p0` used a fork-specific `-pN` suffix. Do **not** use that pattern for new production releases.
