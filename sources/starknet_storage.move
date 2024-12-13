module starknet_addr::starknet_storage {
    use starknet_addr::blob_submission;
    use starknet_addr::blob_submission::{ Sidecar, default };
    use starknet_addr::starknet_state;
    use starknet_addr::starknet_state::State;

    // This line is used for generating constants DO NOT REMOVE!
    // 589825
    const EINVALID_STORAGE: u64 = 0x90001;
    // End of generating constants!

    struct Storage has copy, drop, store, key {
        program_hash: u256,
        config_hash: u256,
        verifier: address,
        state: State,
        sidecar: Sidecar
    }

    public fun initialize(s: &signer, program_hash: u256, verifier: address, config_hash: u256, state: State) {
        assert!(!is_initialized(verifier), EINVALID_STORAGE);

        let sidecar: Sidecar = default();
        move_to(s, Storage {
            program_hash,
            config_hash,
            verifier,
            state,
            sidecar
        });
    }

    public fun is_initialized(addr: address): bool {
        exists<Storage>(addr)
    }

    public fun update_sidecar(addr: address, new_sidecar: Sidecar) acquires Storage {
        let sidecar = &mut borrow_global_mut<Storage>(addr).sidecar;

        let blob = blob_submission::get_sidecar_blob(new_sidecar);
        blob_submission::set_sidecar_blob(sidecar, blob);

        let commitment = blob_submission::get_sidecar_commitment(new_sidecar);
        blob_submission::set_sidecar_commitment(sidecar, commitment);

        let proof = blob_submission::get_sidecar_proof(new_sidecar);
        blob_submission::set_sidecar_proof(sidecar, proof);
    }

    public fun get_sidecar(addr: address): Sidecar acquires Storage {
        borrow_global<Storage>(addr).sidecar
    }

    public(friend) fun set_program_hash(storage: &mut Storage, new_program_hash: u256) {
        storage.program_hash = new_program_hash;
    }

    public fun get_program_hash(addr: address): u256 acquires Storage {
        borrow_global<Storage>(addr).program_hash
    }

    public(friend) fun set_config_hash(storage: &mut Storage, new_config_hash: u256) {
        storage.config_hash = new_config_hash;
    }

    public fun get_config_hash(addr: address): u256 acquires Storage {
        borrow_global<Storage>(addr).config_hash
    }

    public(friend) fun set_verifier(storage: &mut Storage, addr: address) {
        storage.verifier = addr;
    }

    public fun get_verifier(addr: address): address acquires Storage {
        borrow_global<Storage>(addr).verifier
    }

    public fun update_state(addr: address, starknet_output: vector<u256>) acquires Storage {
        let state = &mut borrow_global_mut<Storage>(addr).state;
        starknet_state::update(state, starknet_output)
    }

    public fun get_state(addr: address): State acquires Storage {
        borrow_global<Storage>(addr).state
    }
}