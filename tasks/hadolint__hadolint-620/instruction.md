DL3060 ("`yarn cache clean` missing after `yarn install`") currently reports warnings in multi-stage Dockerfiles even when the offending `yarn install` happens in an intermediate build stage that is not part of the final image. This produces false positives: large caches in non-final stages only affect build cache size, not the resulting image.

When linting a multi-stage Dockerfile, DL3060 should only trigger if the final stage’s resulting filesystem includes the effects of a `RUN yarn install ...` that is not followed (in the same stage lineage) by `yarn cache clean`. In other words, the rule must be stage-aware and consider whether the stage containing the `yarn install` contributes to the final image.

Reproduction example (should NOT trigger DL3060):
```Dockerfile
FROM node:lts-alpine
RUN yarn install

FROM node:lts-alpine
RUN foo
```
Here, the `yarn install` happens in the first stage, but the final stage starts from a fresh base image and does not inherit from the first stage.

Example that SHOULD still trigger DL3060:
```Dockerfile
FROM node:lts-alpine as stage1
RUN yarn install

FROM stage1
RUN foo
```
Here, the final stage inherits from `stage1`, so the installed yarn cache remains in the final image unless explicitly cleaned.

More generally, DL3060 behavior should be:
- `RUN yarn install ...` without a subsequent `yarn cache clean` should trigger DL3060 when it occurs in the final stage.
- It should also trigger if the final stage is based on (inherits from) a previous stage that performed `yarn install` without cleaning.
- It should not trigger for a `yarn install` in a stage that is neither the final stage nor an ancestor/base of the final stage.
- If a stage performs `yarn install && yarn cache clean`, inheriting from that stage should not trigger DL3060.

Calling hadolint on Dockerfiles matching the above scenarios should produce warnings only in the cases where the final image contains an uncleaned yarn cache, and no warnings otherwise.