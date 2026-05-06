#!/bin/bash
set -e

# Confidential CVM CLI installer
# Downloads ccvm CLI and attestation-cli to /usr/local/bin/

VERSION="${CCVM_VERSION:-${CC_VERSION:-${CONFIDENTIAL_CVM_CLI_VERSION:-v1.5.8}}}"
ATTEST_VERSION="${ATTESTATION_CLI_VERSION:-v0.4.1}"

echo "Installing Confidential CVM CLI ${VERSION}..."

curl -fsSL "https://github.com/lunal-dev/confidential-cvm-cli/releases/download/${VERSION}/ccvm" \
  -o /usr/local/bin/ccvm

curl -fsSL "https://github.com/lunal-dev/attestation-rs/releases/download/${ATTEST_VERSION}/attestation-cli" \
  -o /usr/local/bin/attestation-cli

chmod +x /usr/local/bin/ccvm /usr/local/bin/attestation-cli

echo "Installed:"
echo "  /usr/local/bin/ccvm (${VERSION})"
echo "  /usr/local/bin/attestation-cli (${ATTEST_VERSION})"
