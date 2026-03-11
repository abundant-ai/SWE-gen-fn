When Stack fails to construct a build plan due to a dependency not being present in the selected snapshot and not listed in extra-deps, the current error message is confusing to new users because it says the “Stack configuration has no specified version”. This wording incorrectly suggests that the user failed to specify a version somewhere in configuration, rather than explaining that the package is simply not available from the chosen snapshot/extra-deps set.

Reproduction scenario: Create a project that depends on a package that is not included in the resolver snapshot and is not listed under extra-deps. Then run a build/install so that Stack attempts to construct a build plan. Example of the current confusing style of output:

In the dependencies for <project>:
    <pkg> needed, but the Stack configuration has no specified
    version (latest matching version is <v>)
needed since <project> is a build target.

Expected behavior: The error should clearly state that no version for the dependency is present in the specified snapshot or extra-deps, while preserving the helpful “latest matching version is …” hint. For example, the message should read along these lines:

In the dependencies for <project>:
    <pkg> needed, but no version is in the specified snapshot
    or extra-deps (latest matching version is <v>)
needed since <project> is a build target.

Additionally, when build plan construction fails for other known plan-construction failure modes (such as cases involving pruned GHC boot packages), the stderr output should include the improved, more specific explanatory text (e.g., containing the phrase “but this GHC boot package has been pruned”). For cases where Stack can recommend a remediation related to constraints (for example, suggesting ignoring version constraints), the failure output should include a recommendation sentence containing the phrase “To ignore all version constraints”.

The change should ensure these messages appear consistently in stderr in the relevant failure paths so that users see the clearer explanation and recommendations during `stack build`/`stack install` when a plan cannot be constructed.