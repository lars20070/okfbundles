# okfbundles

A collection of [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
(OKF) bundles: small wikis written as markdown with YAML frontmatter.

Each bundle sits in [okf/](okf/) as a `<name>.okf.zip` file and targets
[OKF v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md).

## Add a bundle

1. Build the bundle as a single folder. Its root holds `index.md`, whose
   frontmatter declares `okf_version: "0.2"`. Every other `.md` file needs
   frontmatter with a non-empty `type`. Don't add a `.okflintrc.json`; the
   checks reject it.

2. Zip the folder itself, so the archive holds one root directory:

   ```sh
   zip -r okf/MyBundle.okf.zip MyBundle
   ```

3. Run the checks (they need [`okfctl`](https://github.com/cwest/okfctl),
   e.g. `go install github.com/cwest/okfctl@v0.4.0`):

   ```sh
   make check-okf
   ```

4. Commit on a branch and open a pull request. CI runs the same checks again.

## Cut a release

1. Set the new version in `VERSION` and add a matching
   `## [X.Y.Z] - YYYY-MM-DD` section at the top of `CHANGELOG.md`.
   `make check-version` confirms the two agree.

2. Merge to `main`, then tag and push:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

   The release workflow reruns CI, checks the tag against `VERSION` and
   `CHANGELOG.md`, and creates a GitHub Release whose notes are that
   version's changelog section.
