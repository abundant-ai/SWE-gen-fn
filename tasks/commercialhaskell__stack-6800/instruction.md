Stack supports project templates referenced by repository prefixes like "github:user/name", "bitbucket:user/name", and "gitlab:user/name". Users also host `stack-templates` on Codeberg, but currently Stack does not recognize the "codeberg:" prefix as a repository template source.

When calling `parseTemplateNameFromString "codeberg:user/name"`, it should parse as a repository-backed template path (similar to GitHub/Bitbucket/GitLab) and produce a `RepoPath (RepoTemplatePath Codeberg "user" "name.hsfiles")`. Right now, "codeberg:user/name" is not handled as a supported repo prefix, so it is treated incorrectly (eg as a relative path) or fails to parse, and template download from Codeberg cannot work.

Implement Codeberg as a supported `RepoHost` wherever repository template names are represented and resolved, so that:

- The string prefix "codeberg:" is recognized by `parseTemplateNameFromString`.
- The parsed template name is represented as `RepoTemplatePath Codeberg <user> <templateFile>` where the template file defaults to adding the `.hsfiles` suffix (so "name" becomes "name.hsfiles").
- Any logic that converts a `RepoTemplatePath` into a URL for downloading the template file must support the Codeberg host (in the same way as other supported hosts), so that templates can be fetched from Codeberg-hosted `stack-templates` repositories.

The existing behaviors for other inputs must remain unchanged (eg http/https URLs remain `UrlPath`, and bare names like "name" remain relative template paths with the `.hsfiles` suffix).