module starknet_addr::starknet {

    use std::bcs;
    use std::signer;
    use std::signer::address_of;
    use std::vector;
    use std::vector::slice;
    use aptos_std::aptos_hash::keccak256;
    use aptos_std::debug::print;
    use aptos_std::math64::pow;
    use aptos_std::table;
    use aptos_std::table::Table;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use starknet_addr::starknet_storage::{Storage};
    use starknet_addr::starknet_storage;
    use starknet_addr::starket_state;
    use starknet_addr::starket_state::State;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;

    #[test_only]
    // use aptos_std::debug::print;
    use starknet_addr::starket_state::get_global_root;

    struct MessageStorage has store, key {
        l1_to_l2_messages: Table<vector<u8>, u256>,
        l2_to_l1_messages: Table<vector<u8>, u256>,
    }

    #[event]
    struct LogMessageToL1 has store, drop {
        from_address: u256,
        to_address: u256,
        payload: vector<u256>
    }

    #[event]
    struct ConsumedMessageToL2 has store, drop {
        from_address: u256,
        to_address: u256,
        selector: u256,
        payload: vector<u256>,
        nonce: u256,
        fee: u256
    }

    #[event]
    struct LogStateUpdate has store, drop {
        global_root: u256,
        block_number: u256,
        blockHash: u256
    }


    const PROGRAM_HASH_TAG: vector<u8> = b"STARKNET_1.0_INIT_PROGRAM_HASH_UINT";
    const VERIFIER_ADDRESS_TAG: vector<u8> = b"STARKNET_1.0_INIT_VERIFIER_ADDRESS";
    const STATE_STRUCT_TAG: vector<u8> = b"STARKNET_1.0_INIT_STARKNET_STATE_STRUCT";
    const CONFIG_HASH_TAG: vector<u8> = b"STARKNET_1.0_STARKNET_CONFIG_HASH";

    fun set_message_cancellation_delay(delay_in_seconds: u256) {}

    #[view]
    public fun is_initialized(addr: address): bool {
        starknet_storage::is_initialized(addr)
    }

    fun num_of_subContracts() {}

    fun validate_init_data() {}

    fun process_sub_contract_addresses() {}

    public entry fun initialize_contract_state(
        s: &signer,
        program_hash: u256,
        verifier: address,
        config_hash: u256,
        global_root: u256,
        block_number: u256,
        block_hash: u256
    ) {
        starknet_storage::initialize(s, program_hash, verifier, config_hash, starket_state::new(
            global_root,
            block_number,
            block_hash
        ));
    }

    #[view]
    public fun identity(): vector<u8> {
        return b"StarkWare_Starknet_2023_6"
    }

    #[view]
    public fun state_root(): u256 {
        starket_state::get_global_root(starknet_storage::get_state(@starknet_addr))
    }

    #[view]
    public fun state_block_number(): u256 {
        starket_state::get_block_number(starknet_storage::get_state(@starknet_addr))
    }

    #[view]
    public fun state_block_hash(): u256 {
        starket_state::get_block_hash(starknet_storage::get_state(@starknet_addr))
    }

    #[view]
    public fun get_config_hash(): u256 {
        starknet_storage::get_config_hash(@starknet_addr)
    }

    #[view]
    public fun get_program_hash(): u256 {
        starknet_storage::get_program_hash(@starknet_addr)
    }

    public entry fun update_state(program_output: vector<u256>) {
        // get initial block number
        let initial_block_number = state_block_number();

        // validate program output
        starknet_output::validate(program_output);
        // Validate config hash
        assert!(
            get_config_hash() == *vector::borrow(
                &program_output,
                starknet_output::get_config_hash_offset()
            ),
            starknet_err::err_invalid_config_hash()
        );
        // Update state
        starknet_storage::update_state(@starknet_addr, program_output);


        // Process the messages after updating the state.
        // This is safer, as there is a call to transfer the fees during
        // the processing of the L1 -> L2 messages.

        // Process L2 -> L1 messages.
        let output_offset = starknet_output::get_header_size();
        let program_output_length = vector::length(&program_output);

        // TODO: process messages
        // output_offset = output_offset + processMessages(
        //     true,
        //     vector::slice(&mut program_output, output_offset, program_output_length),
        // );
        //
        // // // Process L1 -> L2 messages.
        // output_offset = output_offset + processMessages(
        //     false,
        //     vector::slice(&mut program_output, output_offset, program_output_length),
        // );

        // TODO: remove dummy code
        let output_offset = vector::length(&program_output);

        assert!(output_offset == vector::length(&program_output), starknet_err::err_starknet_output_too_long());
        // Note that processing L1 -> L2 messages does an external call, and it shouldn't be
        // followed by storage changes.

        let state = starknet_storage::get_state(@starknet_addr);

        event::emit(LogStateUpdate {
            global_root: starket_state::get_global_root(state),
            block_number: starket_state::get_block_number(state),
            blockHash: starket_state::get_block_hash(state)
        });
        // Re-entrancy protection (see above).
        assert!(state_block_number() == initial_block_number + 1, starknet_err::err_invalid_final_block_number())
    }

    fun process_messages(is_L2_to_L1: bool, program_output: vector<u256>): u64 acquires MessageStorage {
        print(&program_output);
        let msg_storage = borrow_global_mut<MessageStorage>(@starknet_addr);
        let l1_to_l2_messages = &mut msg_storage.l1_to_l2_messages;
        let l2_to_l1_messages = &mut msg_storage.l2_to_l1_messages;

        let message_segment_size = (*vector::borrow(&program_output, 0) as u64);
        assert!(message_segment_size < pow(2, 30), starknet_err::err_invalid_message_segment_size());

        let offset = 1u64;
        let message_segment_end = offset + message_segment_size;

        let payload_offset_size =
            if (is_L2_to_L1)
                starknet_output::get_message_to_l1_payload_size_offset()
            else
                starknet_output::get_message_to_l2_payload_size_offset();

        let total_mgs_fees = 0;
        while (offset < message_segment_end) {
            let payload_length_offset = offset + payload_offset_size;
            assert!(
                payload_length_offset < vector::length(&program_output),
                starknet_err::err_message_too_short()
            );

            print(&payload_length_offset);
            print(&(*vector::borrow(&program_output, payload_length_offset)));
            print(&(*vector::borrow(&program_output, payload_length_offset) as u64));

            let payload_length = (*vector::borrow(&program_output, payload_length_offset) as u64);
            assert!(payload_length < pow(2, 30), starknet_err::err_invalid_payload_length());

            let end_offset = payload_length_offset + payload_length;
            assert!(
                end_offset <= vector::length(&program_output),
                starknet_err::err_truncated_message_payload()
            );

            if (is_L2_to_L1) {
                let msg_hash = keccak256(
                    bcs::to_bytes(
                        &vector::slice(&program_output, (offset as u64), (end_offset as u64)
                        )));

                event::emit(LogMessageToL1 {
                    from_address: *vector::borrow(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l1_from_address_offset()
                    ),
                    to_address: *vector::borrow(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l1_to_address_offset()
                    ),
                    payload: vector::slice(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l1_prefix_size(),
                        (end_offset as u64)
                    )
                });
                let msg = table::borrow_mut_with_default(l2_to_l1_messages, msg_hash, 0);
                *msg = *msg + 1;
            } else {
                let msg_hash = keccak256(
                    bcs::to_bytes(
                        &vector::slice(&program_output, (offset as u64), (end_offset as u64)
                        )));

                let msg_fee_plus_one = table::borrow_mut(l1_to_l2_messages, msg_hash);
                assert!(*msg_fee_plus_one > 0, starknet_err::err_invalid_message_to_consume());
                total_mgs_fees = total_mgs_fees + *msg_fee_plus_one - 1;
                table::upsert(l1_to_l2_messages, msg_hash, 0);

                let nonce = *vector::borrow(&program_output, starknet_output::get_message_to_l2_nonce_offset());
                let msgs = vector::slice(
                    &program_output,
                    (offset as u64) + starknet_output::get_message_to_l2_prefix_size(),
                    (end_offset as u64)
                );
                event::emit(ConsumedMessageToL2 {
                    from_address: *vector::borrow(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l2_from_address_offset()
                    ),
                    to_address: *vector::borrow(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l2_to_address_offset()
                    ),
                    selector: *vector::borrow(
                        &program_output,
                        (offset as u64) + starknet_output::get_message_to_l2_selector_offset()
                    ),
                    payload: msgs,
                    nonce,
                    fee: 0
                });
            };
            offset = end_offset;
        };

        assert!(offset == message_segment_end, starknet_err::err_invalid_message_segment_size());

        if (total_mgs_fees > 0) {
            // TODO: transfer fees
        };

        return offset
    }

    #[test(s = @starknet_addr)]
    fun update_state_success(s: &signer) {
        let state = starket_state::new(0, 0, 0);

        let msg_storage = MessageStorage {
            l1_to_l2_messages: table::new(),
            l2_to_l1_messages: table::new()
        };
        move_to(s, msg_storage);
        starknet_storage::initialize(
            s,
            1865367024509426979036104162713508294334262484507712987283009063059134893433,
            @starknet_addr,
            1553709454334774815764988612122634988906525555606597726644370513828557599647,
            state
        );

        // [prev_state, curr_state, block_number, block_hash, conf_hash, ...]
        let program_output =
            vector[0x0, 0x12345, 1, 0x1234, 1553709454334774815764988612122634988906525555606597726644370513828557599647, 100, 200, 1, 1351148242645005540004162531550805076995747746087542030095186557536641755046, 558404273560404778508455254030458021013656352466216690688595011803280448032];
        update_state(program_output);
        assert!(state_block_hash() == 0x1234, 1);
        assert!(state_block_number() == 1, 1);
        assert!(state_root() == 0x12345, 1);

        assert!(get_program_hash() == 1865367024509426979036104162713508294334262484507712987283009063059134893433, 1);
        assert!(get_config_hash() == 1553709454334774815764988612122634988906525555606597726644370513828557599647, 1);
    }
}