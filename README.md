# confidential-cvm-cli

TEE verification and management CLI for confidential compute VMs.

This CLI lets you cryptographically confirm that a CVM is running in a genuine TEE and inspect its state. It is derived from the PrivateClaw CLI and currently keeps the same on-VM evidence paths for compatibility with existing cloud-init.

For background on TEEs and remote attestation, see [confidential.ai/docs](https://confidential.ai/docs).

## Install

```bash
curl -fsSL https://github.com/lunal-dev/confidential-cvm-cli/releases/latest/download/install.sh | bash
```

This installs two binaries to `/usr/local/bin/`:

- `ccvm` - the CLI shell script (this repo)
- `attestation-cli` - pre-built binary from [lunal-dev/attestation-rs](https://github.com/lunal-dev/attestation-rs) that performs the cryptographic SEV-SNP and TPM attestation

## Commands

```bash
ccvm <command> [flags]
```

| Command | Description |
|---|---|
| `ccvm verify [-v\|--verbose]` | Run the full 5-check TEE verification |
| `ccvm info` | Print component versions, hostname, gateway IP, install date |
| `ccvm attest` | Generate attestation evidence (boot-time; run by cloud-init) |
| `ccvm assign` | Apply user configuration from IMDS (internal; run by systemd) |

### `ccvm verify`

User-facing command. Runs five checks and prints a pass/fail summary:

1. **SEV-SNP Hardware** - requests a fresh AMD SEV-SNP attestation report bound to the current SSH host key hash and validates the full cert chain via `attestation-cli`.
2. **TPM Attestation** - validates the vTPM quote and AK cert chain.
3. **Host Key Binding** - confirms the live SSH host key matches the key baked into the attestation evidence.
4. **Inference Provider** - shows the configured confidential inference endpoint.
5. **External Access Lockout** - audits `authorized_keys`, firewall rules, and cloud-provider access paths to confirm no operator backdoor.

Add `-v` / `--verbose` for full cert-chain, VCEK, and endpoint diagnostics.

### `ccvm info`

Prints a compact status block useful for bug reports and quick sanity checks:

```text
ccvm:              v1.5.8
attestation-cli:   v0.4.1
openclaw:          <version>
Hostname:          <fqdn>
Gateway IP:        <gateway>
Installed:         <date>
```

### `ccvm attest`

Boot-time command invoked by cloud-init. Generates SEV-SNP + TPM attestation evidence binding the SSH host key to the TEE hardware and writes it to `/etc/privateclaw/evidence.json` for current compatibility.

### `ccvm assign`

Internal command invoked by a systemd timer. Polls Azure IMDS for user configuration and applies it to the CVM.

## Independent Verification

You can verify a CVM's attestation evidence from any machine. You do not need to trust this CLI:

```bash
# Copy evidence off the CVM
scp user@cvm:/etc/privateclaw/evidence.json .

# Verify locally with attestation-cli
attestation-cli verify -e evidence.json --expected-report-data <host_key_hash_hex>
```

## Cloud-Init Follow-Up

Confidential Agents cloud-init has not been changed yet. Once this repo has a published release, update cloud-init to download:

```text
https://github.com/lunal-dev/confidential-cvm-cli/releases/latest/download/install.sh
```

Then update boot/runtime invocations from `privateclaw attest`, `privateclaw assign`, and `privateclaw verify` to `ccvm attest`, `ccvm assign`, and `ccvm verify`.

## Auditing

Everything that runs on your CVM lives in this repo. `ccvm` is a single bash script. The only binary dependency is [`attestation-cli`](https://github.com/lunal-dev/attestation-rs), which is also open source.

## License

[MIT](./LICENSE)
