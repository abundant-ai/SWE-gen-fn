The public API for package dump parsing exposes a DumpPackage record whose field names currently use a "dp" prefix (for example, callers pattern-match with DumpPackage{dpLicense = ..., dpDepends = ...}). This prefix should be removed so that the record fields have unprefixed names (for example, license, depends, ghcOptions, etc.), while keeping the underlying behavior of parsing and dependency pruning the same.

After this change, code that consumes package dumps should be able to compile and run when using the new unprefixed DumpPackage fields. In particular, the functions that produce and process DumpPackage values must continue to work:

- conduitDumpPackage must still parse ghc-pkg dump output into DumpPackage values with all fields populated as before.
- ghcPkgDump must still return the same DumpPackage information as before.
- pruneDeps must still correctly prune dependency sets derived from DumpPackage values.

Expected behavior is that parsing a ghc-pkg dump for multiple GHC versions still yields correct package identifiers, dependencies, and metadata (such as license), and that existing consumers can pattern-match on DumpPackage using the new field names without needing the dp prefix.

Currently, attempting to update callers to use unprefixed field names fails because DumpPackage still defines dp-prefixed field selectors; consumers that switch to unprefixed names will not compile due to missing record fields. Update DumpPackage and all relevant producers/consumers so that the unprefixed field names are the supported interface, and ensure the dump parsing/pruning behavior remains unchanged.