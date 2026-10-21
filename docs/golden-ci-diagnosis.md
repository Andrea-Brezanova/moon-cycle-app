# Golden screenshots on GitHub: diagnosis

Run: commit `37521e2`, job "Golden screenshots (macOS)", check run 118358588072
(annotations are public; logs and the artifact need a GitHub login).

| | Developer Mac | GitHub runner |
|---|---|---|
| macOS | 15.6.1 | 26.6.2 |
| CPU | arm64 | arm64 |
| Flutter | 3.47.7 | 3.47.7 |
| Fonts | the 15 committed files | the same 15 files |

Result: 2 of 135 passed. The reported differences are **tiny**: 10 to 33 pixels
per image, 0.00% to 0.02% (for example `dark_controls.png` 33 px, `dark_moons.png`
20 px). That is the signature of text and edge anti-aliasing differing between
two macOS versions, not of a layout, colour or font change. Every image
differs a little because every image has text. Fonts, Flutter version, device
pixel ratio and CPU architecture are identical, so the operating system's text
rasteriser is the only variable left.

## What not to do
Do not raise the comparison tolerance (it would also hide real changes) and do
not re-record on the Mac and hope.

## Recommended fix
Record the reference images in the same environment that checks them:
1. Add a manual workflow ("Update goldens", `workflow_dispatch`) that runs
   `flutter test --tags golden --update-goldens` on `macos-latest` and uploads the
   new PNGs as an artifact (or commits them to a branch for review).
2. Review the diff of those images (they should look identical to today's), then
   commit them. From then on the runner compares against its own renderings.
3. Developers regenerate through that workflow, not locally; local golden runs
   become a convenience, with the CI images as the source of truth.
Caveat: if GitHub moves `macos-latest` to a newer macOS the images may need
re-recording once; pinning an exact runner image (for example `macos-15`)
avoids surprises.

## Controlled update procedure (implemented, manual only)

* **Pinned runner:** `macos-15` (arm64), the same major version as the developer
  Mac (15.6.1). Both the golden check (`ci.yaml`) and the update workflow use it;
  neither uses `macos-latest` any more. The exact point release the image carries
  is printed in each run's summary ("Golden recording environment") and in the
  failure annotation "Golden environment".
* **Current differences** (run on `macos-latest` = macOS 26.6.2): every image
  differs by 10 to 33 pixels (0.00 to 0.02%); 2 of 135 passed. Expect these to
  disappear, or nearly, on `macos-15`. If some remain, the update workflow will
  list them.
* **To update references:** Actions › "Update goldens (manual)" › Run workflow
  (optionally write why). It records into a scratch copy, changes nothing in the
  repository, and uploads artifact `proposed-goldens` containing only images that
  differ, each next to its `.BEFORE.png`, plus `CHANGED.txt`.
* **To review:** download the artifact, open each pair (before/after) in any
  image viewer; on the run page the summary lists how many images changed and
  which. Accept only images that look the same or are an intended change.
* **To accept:** copy the reviewed PNGs into `test/goldens/...`, commit them in
  their own commit ("test: re-record goldens on macos-15"), and let the normal
  CI run confirm. Tolerance is never increased.
