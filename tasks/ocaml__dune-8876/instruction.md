When downloading package tarballs via the package fetch API, checksum verification is currently incorrect in some cases: a download can be accepted when it should fail, or it can fail with a misleading error because the checksum being verified is not the actual content that was fetched/unpacked.

The function `Dune_pkg.Fetch.fetch` takes parameters including `~unpack`, `~checksum`, `~target`, and a URL. When `~checksum` is provided, `Fetch.fetch` must verify that the downloaded content matches the expected checksum, and it must do so against the exact bytes that were fetched (i.e., the downloaded tarball/file), not against some other representation.

Expected behavior:
- If `Fetch.fetch ~checksum:<expected>` downloads content whose hash does not match `<expected>`, it must return `Error (Checksum_mismatch actual_checksum)` where `actual_checksum` corresponds to the checksum of the downloaded content.
- If the downloaded content matches the expected checksum, it must return `Ok ()`.
- The mismatch case must be reproducible: for the same downloaded bytes, the returned `actual_checksum` must be stable and reflect the true content.

Observed problematic behavior:
- Supplying an intentionally wrong checksum can fail to produce `Checksum_mismatch` for the downloaded tarball/file, or it can produce an `actual_checksum` that does not correspond to the downloaded bytes.

Reproduction scenario (conceptual):
- Serve a file over HTTP and call `Fetch.fetch` to download it to a local `~target`.
- Compute an expected checksum from known content (or provide a deliberately incorrect checksum).
- Call `Fetch.fetch ~unpack:false ~checksum:<wrong> ~target url`.
- It should return `Error (Checksum_mismatch actual)` and `actual` should equal the checksum of the served file’s bytes.

This must work consistently for both plain downloads (`~unpack:false`) and tarball downloads where unpacking may be requested (`~unpack:true`), with checksum verification always applying to the downloaded artifact corresponding to the URL (the tarball/file itself).