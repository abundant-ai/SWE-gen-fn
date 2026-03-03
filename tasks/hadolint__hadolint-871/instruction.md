Hadolint currently supports inline ignore pragmas (e.g. `# hadolint ignore=DL3002`) that suppress specific rule violations only for the following instruction. There is no way to disable a rule for an entire Dockerfile.

Add support for a file-wide “global ignore” pragma comment of the form:

```dockerfile
# hadolint global ignore=DL3003,SC2035
```

When this comment appears anywhere in the Dockerfile, Hadolint should treat the listed rule codes as globally ignored for the whole file: any violation whose code matches one of the globally ignored codes must be suppressed regardless of line number or which instruction triggered it. All other rule violations must still be reported normally.

The parsing must accept multiple rule codes separated by commas and tolerate extra whitespace around tokens and the equals sign, for example:

```dockerfile
# hadolint global ignore = DL3023 , DL3021
```

This should suppress both `DL3023` and `DL3021` if they would otherwise be raised. Inline ignores must continue to work exactly as before (only affecting the immediately following instruction), and global ignores must not require being directly above any instruction.

Invalid rule names included in a pragma should not cause unrelated valid rules to be ignored; only recognized rule codes should be considered for suppression.