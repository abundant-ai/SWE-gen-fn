Two related user-facing problems need fixing.

1) `stack new` fails when the template argument is an HTTP/HTTPS URL.

Reproduction:

```bash
stack new foobar https://github.com/commercialhaskell/stack-templates/blob/master/simple.hsfiles
```

Current behavior: Stack downloads the URL into the templates cache and then crashes when attempting to use the downloaded template, ending with an error of the form:

```
Error: [S-9490]
       Stack failed to use the template <url>, as
       InvalidInput ""
```

Expected behavior: `stack new` should successfully create and initialize the new project from a template provided via an `http://` or `https://` URL, as documented. The downloaded template should be treated as a valid template source and parsed/processed the same way as other supported template inputs.

2) The warning about attempting to upgrade/downgrade the `base` package is no longer appropriate post-GHC 9.10 and needs updating, including a way to mute it.

Current behavior: Stack emits a warning along the lines of “You are trying to upgrade or downgrade the base package…” which was previously appropriate when `base` was treated as a special “magic” package. After GHC 9.10 this framing is no longer accurate, but users still need some notification when their build plan requires an unattainable `base` version or when behavior differs for older GHC versions.

Expected behavior:
- When a build requires an unattainable version of `base` (relative to the selected GHC toolchain/boot packages), Stack should emit a warning containing the message fragment:
  
  `Build requires unattainable version of`
- For scenarios involving older toolchains (specifically “Before GHC 9.12.1”), Stack should emit a warning containing the message fragment:
  
  `Before GHC 9.12.1, the base package is`
- Add a new configuration option `notify-if-base-not-boot` that allows users to mute the updated warning(s) (similar in spirit to other `notify-if-*` options). When this option disables notification, the above warnings should not be emitted.

Both fixes should work together in normal Stack usage without requiring users to change their workflows.