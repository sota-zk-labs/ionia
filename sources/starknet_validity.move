module starknet_addr::starknet_validity {

    use std::bcs;
    use std::vector;
    use starknet_addr::onchain_data_fact;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;
    use starknet_addr::starknet_state;
    use starknet_addr::starknet_storage;
    use starknet_addr::fact_registry;
    use starknet_addr::helper;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event;

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

    public fun update_state(
        program_output: &vector<u256>,
        onchain_data_hash: u256,
        onchain_data_size: u256,
    ) {
        // Reentrancy protection: read the block number at the beginning
        let initial_block_number = state_block_number();

        // Validate program output
        assert!(
            vector::length(program_output) > starknet_output::get_header_size(),
            starknet_err::err_invalid_config_hash()
        );

        // Validate KZG DA flag
        assert!(
            *vector::borrow(program_output, starknet_output::get_use_kzg_da_offset()) == 0,
            starknet_err::err_unexpected_kzg_da_flag()
        );

        let fact_data = onchain_data_fact::init_fact_data(onchain_data_hash, onchain_data_size);

        let state_transition_fact = onchain_data_fact::encode_fact_with_onchain_data(
            *program_output,
            fact_data
        );
        update_state_internal(program_output, state_transition_fact);

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
        helper::append_vector(&mut state_transition_fact, &helper::u256_to_bytes(program_hash));
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

}