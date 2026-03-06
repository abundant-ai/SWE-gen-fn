A new multi-token ERC-1155 contract is being introduced to manage multiple token IDs with per-token metadata and supply tracking, plus admin/minter controls and contract/token locking. The current implementation is incomplete/inconsistent with the expected on-chain behavior and API.

When deploying `MultiERC1155`, the deployer must start as `owner()`, `admin()`, and `minter()`, with `mintingEnabled()` set to `true` and `contractLocked()` set to `false`. Immediately after deployment, the contract must already have at least one token ID registered (token ID `1`) so that calling `getTokenIds()` returns an array of length 1 containing `[1]`.

The contract must support registering tokens via `addToken((string,bool,string,string,string,uint256))` (a single tuple argument). Calling this registration method should succeed via a low-level call using `abi.encodeWithSignature`, and it must create a new token entry with:
- a sequential token ID starting at 1
- `exists=true`
- per-token `locked=false` by default
- per-token `totalSupply` initialized to 0
- per-token enabled flag initialized from the provided `TokenInfo` (expected default: `enabled=true`)

The public `tokens(uint256)` getter must expose enough fields to allow reading back (at minimum) that the token exists, its current supply is 0 for newly-added tokens, and whether it is locked. After adding the first token, reading `tokens(1)` should indicate it exists, is not locked, and has supply 0.

Role/permission setters must work and update state:
- `setAdmin(address)` updates `admin()`.
- `setMinter(address)` updates `minter()`.
These are expected to be callable by the contract owner (and should not silently fail).

Minting enablement must be controllable:
- `toggleMinting(bool enabled)` must set `mintingEnabled()` to the provided value.
- Calling `toggleMinting` with the current value should behave consistently (it must not revert just because there is “no change”).

Overall, ensure the contract exposes the exact public methods and state accessors (`owner()`, `admin()`, `minter()`, `mintingEnabled()`, `contractLocked()`, `getTokenIds()`, `tokens(uint256)`, `addToken((...))`, `setAdmin(address)`, `setMinter(address)`, `toggleMinting(bool)`) and that they behave as described so external callers can manage token registration and minting state correctly.