module starknet_addr::blob_submission {
    struct Sidecar has copy, drop, store {
        sidecar_blob: vector<vector<u8>>,
        sidecar_commitment: vector<vector<u8>>,
        sidecar_proof: vector<vector<u8>>,
    }

    public fun new(
        sidecar_blob: vector<vector<u8>>,
        sidecar_commitment: vector<vector<u8>>,
        sidecar_proof: vector<vector<u8>>
    ): Sidecar {
        return Sidecar {
            sidecar_blob,
            sidecar_commitment,
            sidecar_proof
        }
    }

    public fun set_sidecar_blob(sidecar: &mut Sidecar, sidecar_blob: vector<vector<u8>>) {
        sidecar.sidecar_blob = sidecar_blob;
    }

    public fun set_sidecar_commitment(sidecar: &mut Sidecar, sidecar_commitment: vector<vector<u8>>) {
        sidecar.sidecar_commitment = sidecar_commitment;
    }

    public fun set_sidecar_proof(sidecar: &mut Sidecar, sidecar_proof: vector<vector<u8>>) {
        sidecar.sidecar_proof = sidecar_proof;
    }

    public fun get_sidecar_blob(sidecar: Sidecar): vector<vector<u8>> {
        return sidecar.sidecar_blob
    }

    public fun get_sidecar_commitment(sidecar: Sidecar): vector<vector<u8>> {
        return sidecar.sidecar_commitment
    }

    public fun get_sidecar_proof(sidecar: Sidecar): vector<vector<u8>> {
        return sidecar.sidecar_proof
    }

    public fun default(): Sidecar {
        return new(vector[x"00"], vector[x"00"], vector[x"00"])
    }
}