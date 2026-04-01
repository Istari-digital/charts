# Copilot Review Instructions

## FIPS 140-3 Compliance

This repository has a FIPS 140-3 compliance guide at `FIPS.md`. When reviewing pull requests:

- If this PR introduces new cryptographic usage (new imports of crypto libraries, new hashing, encryption, signing, or key management), flag it as requiring FIPS 140-3 compliance review.
- If this PR changes existing cryptographic usage in a way that disagrees with `FIPS.md`, flag it as an issue.
- If this PR adds new dependencies that perform cryptographic operations (including TLS, hashing, or encryption), or changes TLS configuration (minimum versions, cipher suites, certificate verification), note that `FIPS.md` may need to be updated.
