# okfbundles

A collection of [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
(OKF) bundles: small wikis written as markdown with YAML frontmatter.

Each bundle sits in [okf/](okf/) as a `<name>.okf.zip` file.

## Add a bundle

1. Build the bundle as a single folder. Its root holds `index.md`, which
   declares `okf_version`, and [`.okflintrc.json`](https://github.com/thisismydesign/okf-lint#configuration), which sets the [`okf-lint`](https://github.com/thisismydesign/okf-lint) lint rules.
   Every other `.md` file needs frontmatter with a non-empty `type`.

2. Zip the folder itself, so the archive holds one root directory:

   ```sh
   zip -r okf/MyBundle.okf.zip MyBundle
   ```

3. Run the checks (they need `pnpm`):

   ```sh
   make check-okf
   ```

4. Commit on a branch and open a pull request. CI runs the same checks again.

