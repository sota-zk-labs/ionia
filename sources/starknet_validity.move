module starknet_addr::starknet_validity {

    use std::vector;
    use std::signer;
    use std::signer::address_of;
    use starknet_addr::onchain_data_fact;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;
    use starknet_addr::starknet_state;
    use starknet_addr::starknet_storage;

    #[view]
    public fun state_block_number(): u256 {
        starknet_state::get_block_number(starknet_storage::get_state(@starknet_addr))
    }

    public fun update_state(
        program_output: &vector<u64>,
        onchain_data_hash: u64,
        onchain_data_size: u64,
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

        let state_transition_fact = onchain_data_fact::encode_fact_with_onchain_data(
            program_output,
            onchain_data_hash,
            onchain_data_size
        );
        update_state_internal(program_output, state_transition_fact);
        // Note that update_state_internal does an external call and shouldn't be followed by storage changes

        // Reentrancy protection: validate final block number
        assert!(
            state_block_number() == initial_block_number + 1,
            starknet_err::err_invalid_final_block_number()
        );
    }

    public fun update_state_internal(
        program_output: &vector<u64>,
        state_transition_fact: vector<u8>,
    ) {
        // Validate config hash.
        assert!(
            *vector::borrow(program_output, starknet_output::get_use_kzg_da_offset()) == config_hash,
            starknet_err::err_invalid_config_hash()
        );

        let program_hash = program_hash();
        let sharp_fact = Hash::keccak256(Vector::concat(
            Vector::concat(program_hash, Vector::singleton(state_transition_fact))
        ));
        assert!(
            IFactRegistry::is_valid(&verifier_address, sharp_fact),
            Error::permission_denied(NO_STATE_TRANSITION_PROOF)
        );

        LogStateTransitionFact::emit_event(state_transition_fact);

        // Perform state update.
        state().update(program_output);

        // Process the messages after updating the state.
        // This is safer, as there is a call to transfer the fees during
        // the processing of the L1 -> L2 messages.

        // Process L2 -> L1 messages.
        // let use_kzg_da_offset = (*Vector::borrow(program_output, USE_KZG_DA_OFFSET) as usize);
        // let output_offset = message_segment_offset(use_kzg_da_offset);
        // *output_offset = *output_offset + process_messages(
        // true, // isL2ToL1
        // &Vector::sub_vector(program_output, output_offset, Vector::length(program_output)),
        // &l2_to_l1_messages
        // );
        //
        // // Process L1 -> L2 messages.
        // *output_offset = *output_offset + process_messages(
        // false, // isL2ToL1
        // &Vector::sub_vector(program_output, output_offset, Vector::length(program_output)),
        // &l1_to_l2_messages
        // );
        // assert!(
        // output_offset == Vector::length(program_output),
        // Error::invalid_argument(STARKNET_OUTPUT_TOO_LONG)
        // );

        let state_ = state();
        LogStateUpdate::emit_event(state_.global_root, state_.block_number, state_.block_hash);
    }

}