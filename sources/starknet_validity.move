module starknet_addr::starknet_validity {

    use std::bcs;
    use std::vector;
    use starknet_addr::onchain_data_fact;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;
    use starknet_addr::starknet_state;
    use starknet_addr::starknet_storage;
    use starknet_addr::pre_compile;
    use starknet_addr::fact_registry;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event;
    use starknet_addr::helper;

    #[event]
    struct ConfigHashChanged {
        changed_by: address,
        old_config_hash: u256,
        new_config_hash: u256
    }

    #[event]
    struct ProgramHashChanged {
        changed_by: address,
        old_program_hash: u256,
        new_program_hash: u256
    }

    #[event]
    struct LogStateUpdate has store, drop {
        global_root: u256,
        block_number: u256,
        block_hash: u256
    }

    #[event]
    struct LogStateTransitionFact has store, drop {
        state_transition_fact: vector<u8>
    }

    // Random storage slot tags
    const PROGRAM_HASH_TAG: vector<u8> = b"STARKNET_1.0_INIT_PROGRAM_HASH_UINT";
    const VERIFIER_ADDRESS_TAG: vector<u8> = b"STARKNET_1.0_INIT_VERIFIER_ADDRESS";
    const STATE_STRUCT_TAG: vector<u8> = b"STARKNET_1.0_INIT_STARKNET_STATE_STRUCT";

    // The hash of the StarkNet config
    const CONFIG_HASH_TAG: vector<u8> = b"STARKNET_1.0_STARKNET_CONFIG_HASH";

    const POINT_EVALUATION_PRECOMPILE_ADDRESS: address = @0x0A;
    const POINT_EVALUATION_PRECOMPILE_OUTPUT: vector<u8> = x"b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c";
    const PROOF_BYTES_LENGTH: u256 = 48;


    const MAX_UINT192: u256 = 6277101735386680763835789423207666416102355444464034512895; // 2 ^ 192 - 1
    const MAX_UINT128: u256 = 340282366920938463463374607431768211455; // 2 ^ 128 - 1

    #[view]
    public fun get_config_hash(): u256 {
        starknet_storage::get_config_hash(@starknet_addr)
    }

    #[view]
    public fun get_program_hash(): u256 {
        starknet_storage::get_program_hash(@starknet_addr)
    }

    #[view]
    public fun state_block_number(): u256 {
        starknet_state::get_block_number(starknet_storage::get_state(@starknet_addr))
    }

    public entry fun update_state(
        program_output: vector<u256>,
        onchain_data_hash: u256,
        onchain_data_size: u256,
    ) {
        // Reentrancy protection: read the block number at the beginning
        let initial_block_number = state_block_number();

        // Validate program output
        assert!(
            vector::length(&program_output) > starknet_output::get_header_size(),
            starknet_err::err_starknet_output_too_short()
        );

        // Validate KZG DA flag
        assert!(
            *vector::borrow(&program_output, starknet_output::get_use_kzg_da_offset()) == 0,
            starknet_err::err_unexpected_kzg_da_flag()
        );

        let fact_data = onchain_data_fact::init_fact_data(onchain_data_hash, onchain_data_size);

        let state_transition_fact = onchain_data_fact::encode_fact_with_onchain_data(
            program_output,
            fact_data
        );
        update_state_internal(&program_output, state_transition_fact);

        // Reentrancy protection: validate final block number
        assert!(
            state_block_number() == initial_block_number + 1,
            starknet_err::err_invalid_final_block_number()
        );
    }

    public fun update_state_internal(
        program_output: &vector<u256>,
        state_transition_fact: vector<u8>,
    ) {
        // Validate config hash.
        assert!(
            *vector::borrow(program_output, starknet_output::get_use_kzg_da_offset()) == get_config_hash(),
            starknet_err::err_invalid_config_hash()
        );

        let program_hash = get_program_hash();
        vector::append(&mut state_transition_fact, bcs::to_bytes(&program_hash));
        let sharp_fact = keccak256(bcs::to_bytes(&state_transition_fact));

        assert!(
            fact_registry::is_valid(sharp_fact),
            starknet_err::err_no_state_transition_proof()
        );

        event::emit(LogStateTransitionFact {
            state_transition_fact
        });

        // Perform state update.
        starknet_storage::update_state(@starknet_addr, *program_output);

        // TODO: process message

        let state = starknet_storage::get_state(@starknet_addr);
        event::emit(LogStateUpdate {
            global_root: starknet_state::get_global_root(state),
            block_number: starknet_state::get_block_number(state),
            block_hash: starknet_state::get_block_hash(state)
        })
    }

    public entry fun update_state_kzg_da(
        program_output: vector<u256>,
        kzg_proof: vector<u8>
    ) {
        let initial_block_number = state_block_number();

        assert!(
            vector::length(&program_output) > starknet_output::get_header_size() + starknet_output::get_kzg_segment_size(),
            starknet_err::err_starknet_output_too_short()
        );

        assert!(
            *vector::borrow(&program_output, starknet_output::get_use_kzg_da_offset()) == 1,
            starknet_err::err_unexpected_kzg_da_flag()
        );
        let kzg_segment = vector::slice(&program_output, starknet_output::get_header_size(), starknet_output::get_kzg_segment_size());
        verify_kzg_proof(&kzg_segment, &kzg_proof);

        let state_transition_fact = keccak256(bcs::to_bytes(&program_output));
        update_state_internal(&program_output, state_transition_fact);

        // Re-entrancy protection: validate final block number
        assert!(
            state_block_number() == initial_block_number + 1,
            starknet_err::err_invalid_final_block_number()
        );
    }

    public fun verify_kzg_proof(
        kzg_segment: &vector<u256>,
        kzg_proof: &vector<u8>
    ) {
        assert!(
            vector::length(kzg_segment) == starknet_output::get_kzg_segment_size(),
            starknet_err::err_invalid_kzg_segment_size()
        );
        assert!(
            (vector::length(kzg_proof) as u256) == PROOF_BYTES_LENGTH,
            starknet_err::err_invalid_kzg_proof_size()
        );

        let blob_hash: vector<u8> = vector::empty<u8>();
        vector::append(&mut blob_hash, x"01");
        assert!(
            vector::slice(&blob_hash, (0 as u64), (31 as u64)) == helper::get_versioned_hash_version_kzg(),
            starknet_err::err_unexpected_blob_hash_version()
        );

        let y;
        let kzg_commitment;
        {
            let kzg_commitment_low: u256 = *vector::borrow(kzg_segment, 0);
            let kzg_commitment_high: u256 = *vector::borrow(kzg_segment, 1);
            let y_low: u256 = *vector::borrow(kzg_segment, 3);
            let y_high: u256 = *vector::borrow(kzg_segment, 4);
            assert!(
                kzg_commitment_low <= MAX_UINT192,
                starknet_err::err_invalid_kzg_commitment()
            );
            assert!(
                kzg_commitment_high <= MAX_UINT192,
                starknet_err::err_invalid_kzg_commitment()
            );
            assert!(
                y_low <= MAX_UINT128,
                starknet_err::err_invalid_y_value()
            );
            assert!(
                y_high <= MAX_UINT128,
                starknet_err::err_invalid_y_value()
            );

            kzg_commitment = vector::empty<u8>();
            vector::append(&mut kzg_commitment, bcs::to_bytes(&kzg_commitment_high));
            vector::append(&mut kzg_commitment, bcs::to_bytes(&kzg_commitment_low));

            y = bcs::to_bytes(&((y_high << 128) + y_low));
        };
        let z = *vector::borrow(kzg_segment, 2);

        let precompile_input: vector<u8> = vector::empty<u8>();
        vector::append(&mut precompile_input, blob_hash);
        vector::append(&mut precompile_input, bcs::to_bytes(&z));
        vector::append(&mut precompile_input, y);
        vector::append(&mut precompile_input, kzg_commitment);
        vector::append(&mut precompile_input, *kzg_proof);

        let (precompile_output, ok) = pre_compile::point_evaluation_precompile(precompile_input);

        assert!(ok, starknet_err::err_point_evaluation_precompile_call_failed());

        assert!(
            keccak256(precompile_output) == POINT_EVALUATION_PRECOMPILE_OUTPUT,
            starknet_err::err_unexpected_point_evaluation_precompile_output()
        );
    }
}