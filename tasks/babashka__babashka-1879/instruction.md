On newer JVMs with stricter security defaults, some cryptographic operations that previously worked in babashka fail because certain deprecated/legacy Cipher suites are no longer available (or are effectively disabled by the active security policy). As a result, code that uses standard JCA/JCE APIs can error at runtime when creating or using cryptographic primitives that depend on those suites.

The problem shows up when babashka is used to run common Java crypto flows (for example, EC key generation / ECDH key agreement, message digests, and symmetric encryption steps that rely on Cipher/KeyAgreement/KeyFactory usage). In affected environments, attempting to initialize crypto components may throw exceptions such as:

- java.security.NoSuchAlgorithmException
- javax.crypto.NoSuchPaddingException
- java.security.InvalidKeyException
- java.security.InvalidAlgorithmParameterException

Babashka should recover compatibility by ensuring that the JVM security configuration used by the embedded runtime does not unintentionally remove Cipher suites that were previously available and are still needed for typical interop scenarios. After the fix, running babashka code that imports and uses JCA/JCE classes like java.security.KeyPairGenerator, java.security.spec.ECGenParameterSpec, javax.crypto.KeyAgreement, javax.crypto.spec.SecretKeySpec, and related crypto APIs should work without throwing the above errors in environments where it used to work.

Expected behavior: Java crypto interop code (including ECDH-based key agreement workflows and related certificate/crypto operations) executes successfully under babashka on supported JVM versions.

Actual behavior: The same code fails on certain JVM/security configurations because deprecated Cipher suites are not available, causing runtime exceptions during algorithm/provider lookup or initialization.