When PostgREST is started with a configuration file that contains UTF-8 characters (for example, non-ASCII characters in comments), it can fail to load the config correctly if the process locale is set to an ASCII/C locale (e.g., `LC_ALL=C`). This happens on systems where the environment has `LC_ALL=C` and/or other `LC_*` variables that result in an ASCII default encoding.

Reproduction example:
- Set the environment to an ASCII locale, e.g. `LC_ALL=C`.
- Create a config file that includes UTF-8 characters, such as a comment line containing characters like `Commènt utf-8 chàrs`, and a valid setting like `log-level = "crit"`.
- Start PostgREST pointing at that config file.

Actual behavior:
- Loading/parsing the configuration fails (or the config is not read reliably) due to decoding the file using the system’s ASCII locale rather than UTF-8. Users observe that changing the system locale (notably `LC_ALL`) to a UTF-8 locale makes the problem disappear.

Expected behavior:
- PostgREST should be able to read configuration files containing UTF-8 content regardless of the process locale. In particular, non-ASCII characters in comments must not prevent parsing, and valid settings (e.g., `log-level = "crit"`) should be applied.
- Given a UTF-8 config file containing only a subset of settings, the loaded configuration should match the normal defaults for all other settings while preserving the explicitly provided values (e.g., `log-level` remains set to `"crit"`).

Fix the configuration loading so that config files are decoded/handled as UTF-8 independent of `LC_ALL`/`LC_CTYPE` settings, avoiding failures when the locale is ASCII.