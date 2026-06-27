#!/usr/bin/env python3
"""
seal_proofpacket.py — TransformFit Harness proof-packet sealer.

Mirrors rig-gtm-studio-v2/v10/proof/seal_proofpacket.py (deterministic hash,
canonical JSON, sha256 over a stable projection, byte-for-byte reproducible
on-disk packets) adapted to the TransformFit FISH field set.

FISH fields (mirrored from the RIG proof chain):
    File      — the artifact path sealed (basename + resolved path)
    Identity  — who/what sealed the packet (default: transformfit-harness)
    Signature — deterministic binding of Identity -> Hash (sha256 over
                identity + content hash; no secret material — this is a
                tamper-evident binding, not a cryptographic signature)
    Hash      — sha256 over the artifact's raw bytes (content is HASHED,
                never embedded — VAL-CROSS-014 no-secrets invariant)

Determinism contract (VAL-HAR-020):
    - No real time / no random / no environment-dependent value inside the
      hash or the packet body. Identical input bytes + identity produce
      byte-identical packets across runs.
    - Hash = sha256(file_bytes) — pure content hash, stable across runs.
    - proof_id = sha256 over a canonical JSON projection of (file, identity,
      hash) — deterministic.

Immutability / tamper-evidence (VAL-HAR-021):
    - Modified input -> different Hash -> different proof_id -> a NEW packet
      file is written; the original packet remains as evidence.
    - An existing packet CANNOT be silently overwritten: if a packet file
      already exists at the target path and its stored Hash does not match
      the freshly computed Hash, the sealer REFUSES (exit non-zero) — this
      catches both accidental collision and manual tampering of a sealed
      packet. If the stored Hash matches (idempotent re-seal of identical
      input), the write is a no-op (same bytes).

No-secrets invariant (VAL-CROSS-014):
    - The packet contains FISH metadata ONLY. The artifact content is hashed,
      never copied into the packet. No secret material is read or embedded.

Usage:
    python3 seal_proofpacket.py <file> [--identity <name>] [--packets-dir <dir>]

Exit codes:
    0 = packet sealed (or idempotent re-seal of identical content)
    1 = tamper detected (existing packet's hash mismatch) — refused
    2 = error (file missing / unreadable / args)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any, Dict

SCHEMA_VERSION = "1.0.0"
STUDIO = "transformfit-harness"
DEFAULT_IDENTITY = "transformfit-harness"

# Packets land here, relative to this module, so the writer is path-stable
# regardless of the caller's working directory.
PACKETS_DIR = pathlib.Path(__file__).resolve().parent / "packets"


def _canonical_json(payload: Any) -> str:
    """Stable JSON string: sorted keys, no insignificant whitespace.

    Used both for hashing (proof_id / signature) and for the on-disk packet
    so byte-for-byte reproducibility holds for identical inputs.
    """
    return json.dumps(
        payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    )


def _content_hash(path: pathlib.Path) -> str:
    """sha256 over the raw bytes of the artifact (content is hashed, not embedded)."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _signature(identity: str, content_hash: str) -> str:
    """Deterministic binding of Identity -> Hash.

    sha256 over (identity + ":" + content_hash). No secret material — this is
    a tamper-evident binding: changing either the identity or the content
    yields a different signature. It is NOT a cryptographic signature (there
    is no private key); it proves the packet was sealed by <identity> over
    exactly the bytes that hash to <content_hash>.
    """
    seed = f"{identity}:{content_hash}".encode("utf-8")
    return hashlib.sha256(seed).hexdigest()


def _derive_proof_id(file_name: str, identity: str, content_hash: str) -> str:
    """Deterministic proof id: ``pp_<12-hex-digest>``.

    The digest covers file name + identity + content hash, so any change to
    the artifact content, identity, or target file yields a distinct id
    (and therefore a distinct on-disk packet file).
    """
    seed = _canonical_json(
        {
            "schema_version": SCHEMA_VERSION,
            "studio": STUDIO,
            "file": file_name,
            "identity": identity,
            "hash": content_hash,
        }
    )
    digest = hashlib.sha256(seed.encode("utf-8")).hexdigest()[:12]
    return f"pp_{digest}"


def _build_packet(
    path: pathlib.Path, identity: str, content_hash: str
) -> Dict[str, Any]:
    """Build the FISH ProofPacket dict (deterministic, no time/random)."""
    proof_id = _derive_proof_id(path.name, identity, content_hash)
    return {
        "schema_version": SCHEMA_VERSION,
        "studio": STUDIO,
        "proof_id": proof_id,
        "fish": {
            "File": str(path),
            "Identity": identity,
            "Signature": _signature(identity, content_hash),
            "Hash": content_hash,
        },
    }


def seal(
    path: pathlib.Path,
    identity: str = DEFAULT_IDENTITY,
    packets_dir: pathlib.Path = PACKETS_DIR,
) -> Dict[str, Any]:
    """Seal a ProofPacket to disk and return it.

    Immutability: if the target packet file already exists, its stored Hash
    is compared to the freshly computed Hash. A mismatch is a tamper /
    collision and is REFUSED (raises FileExistsError). A match is an
    idempotent re-seal of identical content — the write is a no-op.

    Raises:
        FileNotFoundError: if the input file does not exist.
        FileExistsError:  if an existing packet's Hash mismatches the new one.
    """
    if not path.is_file():
        raise FileNotFoundError(f"seal: input file not found: {path}")
    if not identity or not identity.strip():
        raise ValueError("seal: identity must be a non-empty string")

    content_hash = _content_hash(path)
    packet = _build_packet(path, identity, content_hash)

    out_dir = pathlib.Path(packets_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{packet['proof_id']}.json"

    # Immutability / tamper-evidence guard.
    if out_path.exists():
        try:
            existing = json.loads(out_path.read_text(encoding="utf-8"))
        except Exception as e:
            raise FileExistsError(
                f"seal: existing packet at {out_path} is corrupt and cannot be "
                f"verified (refusing silent overwrite): {e}"
            )
        existing_hash = existing.get("fish", {}).get("Hash")
        if existing_hash != content_hash:
            raise FileExistsError(
                f"seal: TAMPER DETECTED — existing packet at {out_path} has Hash "
                f"{existing_hash} but the input now hashes to {content_hash}. "
                f"An existing packet cannot be silently overwritten. Refusing."
            )
        # Idempotent re-seal of identical content — no-op (same bytes).
        return packet

    # Canonical, deterministic bytes on disk.
    out_path.write_text(_canonical_json(packet) + "\n", encoding="utf-8")
    return packet


def main() -> None:
    ap = argparse.ArgumentParser(
        description="TransformFit ProofPacket sealer (deterministic, immutable, FISH fields)"
    )
    ap.add_argument("file", type=pathlib.Path, help="artifact file to seal")
    ap.add_argument(
        "--identity",
        default=DEFAULT_IDENTITY,
        help=f"sealing identity (default: {DEFAULT_IDENTITY})",
    )
    ap.add_argument(
        "--packets-dir",
        type=pathlib.Path,
        default=PACKETS_DIR,
        help="output directory for packets (default: co-located packets/)",
    )
    args = ap.parse_args()

    try:
        packet = seal(args.file, args.identity, args.packets_dir)
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)
    except FileExistsError as e:
        # Tamper / collision — refused (VAL-HAR-021 immutability).
        print(f"REFUSED: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)

    out_path = args.packets_dir / f"{packet['proof_id']}.json"
    print(_canonical_json(packet))
    print(f"# wrote: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
