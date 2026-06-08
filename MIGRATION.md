# Migration guide

This driver registers with `database/sql` as **`singlestore`**, package name is now `singlestore`. Earlier releases — and the upstream [Go-MySQL-Driver](https://github.com/go-sql-driver/mysql) — register as `mysql`. Migrating means renaming both the driver string and the package name.

## Core changes


1. **Module** — pin the new module path (optional; `goimports` / `go build` can add it once imports exist):
   ```bash
   # Pin a released semver tag:
   go get github.com/singlestore-labs/go-singlestore-driver@v2.0.1
   # or pin a specific commit (Go produces a v0.0.0-<date>-<sha> pseudo-version):
   go get github.com/singlestore-labs/go-singlestore-driver@abcdef1234567890
   ```

2. **Blank import** registers the driver. Replace `github.com/go-sql-driver/mysql` or `github.com/memsql/go-singlestore-driver` with
   ```go
   _ "github.com/singlestore-labs/go-singlestore-driver/v2"
   ```
   The blank import does not bind the package name, so it does **not** conflict with a named import of the same module elsewhere in the file (see point 4 and the package-name collision note below).

3. **`sql.Open`** — change the driver name for SingleStore call sites:
   ```go
   sql.Open("singlestore", dsn)
   ```

4. **Named imports** — rename the package prefix on symbols from this module:
   ```go
   import "github.com/singlestore-labs/go-singlestore-driver/v2" // package singlestore

   singlestore.ParseDSN(dsn)
   singlestore.NewConnector(cfg)
   // *singlestore.MySQLError, singlestore.Config, singlestore.Result, ...
   ```
   Most of the identifiers are unchanged from upstream — only the prefix moves. The notable exception is `MySQLDriver` -> `SingleStoreDriver`.

   **Package-name collision.** If your own code lives in a package named `singlestore` (common in repos that wrap this driver), the bare `singlestore.X` form is ambiguous. Use an import alias instead:
   ```go
   import (
       _ "github.com/singlestore-labs/go-singlestore-driver/v2" // register driver
       s2driver "github.com/singlestore-labs/go-singlestore-driver/v2"
   )

   cfg, err := s2driver.ParseDSN(dsn)
   ```
   The blank import and the aliased import can coexist in the same file.

5. **Reconcile `go.mod`** — after steps 2–4 (and any mechanical rewrites / `goimports` below):
   ```bash
   go mod tidy
   go build ./...
   ```
   This drops the old driver module from `go.mod` once nothing imports it, and keeps the new module because your code now references it.

6. **Operational tooling** — driver name in metrics is now `singlestore`; default log prefix is `[singlestore]`; some client-side error strings use a `singlestore:` prefix.

7. **DSN review** — consider SingleStore-specific flags (e.g. `ctxCancellationEnabled=true`); avoid MySQL-only knobs that are no-ops here (`rejectReadOnly`, `serverPubKey`,...). See [README](README.md).

8. **ORMs/frameworks** - Point ORMs/frameworks that hardcode `"mysql"` at `"singlestore"` or inject a pre-built `*sql.DB`. For example, if you are using `github.com/jmoiron/sqlx`:
   ```go
   // before
   db, err := sqlx.Open("mysql", connString)
   // after
   db, err := sqlx.Open("singlestore", connString)
   ```
   The same rename applies to `sqlx.MustOpen`, `sqlx.Connect`, and `sqlx.MustConnect`.

### Mechanical rewrites

For larger codebases, the package-prefix rename can be automated. `gofmt -r` is safe (AST-aware) and preferred over `sed`:

```bash
# Rewrite all mysql.X references from this driver to singlestore.X.
# Repeat per identifier, or script a loop over the lists in the Verify section.
gofmt -r 'mysql.ErrNoTLS -> singlestore.ErrNoTLS' -w .
gofmt -r 'mysql.MySQLError -> singlestore.MySQLError' -w .
gofmt -r 'mysql.ParseDSN(a) -> singlestore.ParseDSN(a)' -w .
# etc.
```

After any rewrite, run `goimports -w .` to fix up imports, then step 5 (`go mod tidy` and `go build ./...`).

### Verify

Check that the necessary changes have been applied.
```bash
git grep 'go-sql-driver/mysql' '*.go'  # SingleStore call sites should be gone
# Catches sql.Open, sqlx.Open, sqlx.MustOpen, sqlx.Connect, sqlx.MustConnect, and similar wrappers:
git grep -E '\.(Open|MustOpen|Connect|MustConnect)\("mysql"' '*.go'
git grep 'github\.com/memsql/go-singlestore-driver'  # old module name should be gone
git grep -E 'mysql\.(BeforeConnect|Charset|DeregisterDialContext|DeregisterLocalFile|DeregisterReaderHandler|DeregisterServerPubKey|DeregisterTLSConfig|EnableCompression|NewConfig|NewConnector|ParseDSN|RegisterDial|RegisterDialContext|RegisterLocalFile|RegisterReaderHandler|RegisterServerPubKey|RegisterTLSConfig|SetLogger|TimeTruncate)([^[:alnum:]_]|$)' '*.go'  # old package prefix on functions should be gone
git grep -E 'mysql\.(Config|DialContextFunc|DialFunc|Logger|MySQLError|NopLogger|NullTime|Option|Result|MySQLDriver)([^[:alnum:]_]|$)' '*.go'  # old package prefix on types should be gone
git grep -E 'mysql\.(ErrBusyBuffer|ErrCleartextPassword|ErrInvalidConn|ErrMalformPkt|ErrNativePassword|ErrNoTLS|ErrOldPassword|ErrOldProtocol|ErrPktSync|ErrPktSyncMul|ErrPktTooLarge|ErrUnknownPlugin)([^[:alnum:]_]|$)' '*.go'  # old package prefix on exported errors should be gone
```

Also audit any indirection through a variable or constant — these won't be caught by the grep above:

```bash
git grep -nE '"mysql"' '*.go'                               # any remaining string literal
git grep -nE '(driverName|driver)\s*[:=]\s*"mysql"' '*.go'  # constants/vars holding the old name
```

### `go.sum` and indirect dependencies

After step 5 you may still see `github.com/go-sql-driver/mysql` listed as an **indirect** dependency in `go.mod` / `go.sum` — for example, pulled in by `github.com/jmoiron/sqlx`'s test code or by another module you depend on. This is harmless: the indirect entry only records that some transitive dependency references the package, and because nothing in your application registers it as a `database/sql` driver, there is no init-time conflict with `singlestore`. If `go-sql-driver/mysql` remains after `go mod tidy`, you can leave it in place.

### Getting help

Open an issue on [go-singlestore-driver](https://github.com/singlestore-labs/go-singlestore-driver).
