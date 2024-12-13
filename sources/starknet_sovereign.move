module starknet_addr::starknet {
    // This line is used for generating constants DO NOT REMOVE!
    // 4
    const CONFIG_HASH_OFFSET: u64 = 0x4;
    // 131075
    const EINVALID_CONFIG_HASH: u64 = 0x20003;
    // 262151
    const EINVALID_FINAL_BLOCK_NUMBER: u64 = 0x40007;
    // 262145
    const EINVALID_MESSAGE_SEGMENT_SIZE: u64 = 0x40001;
    // 262149
    const EINVALID_MESSAGE_TO_CONSUME: u64 = 0x40005;
    // 262147
    const EINVALID_PAYLOAD_LENGTH: u64 = 0x40003;
    // 262146
    const EMESSAGE_TOO_SHORT: u64 = 0x40002;
    // 262150
    const ESTARKNET_OUTPUT_TOO_LONG: u64 = 0x40006;
    // 262152
    const ESTARKNET_OUTPUT_TOO_SHORT: u64 = 0x40008;
    // 262148
    const ETRUNCATED_MESSAGE_PAYLOAD: u64 = 0x40004;
    // 6
    const HEADER_SIZE: u64 = 0x6;
    // 2 ^ 30
    const MAX_PAYLOAD_LENGTH: u64 = 0x40000000;
    // 0
    const MESSAGE_TO_L1_FROM_ADDRESS_OFFSET: u64 = 0x0;
    // 2
    const MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET: u64 = 0x2;
    // 3
    const MESSAGE_TO_L1_PREFIX_SIZE: u64 = 0x3;
    // 1
    const MESSAGE_TO_L1_TO_ADDRESS_OFFSET: u64 = 0x1;
    // 0
    const MESSAGE_TO_L2_FROM_ADDRESS_OFFSET: u64 = 0x0;
    // 2
    const MESSAGE_TO_L2_NONCE_OFFSET: u64 = 0x2;
    // 4
    const MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET: u64 = 0x4;
    // 5
    const MESSAGE_TO_L2_PREFIX_SIZE: u64 = 0x5;
    // 3
    const MESSAGE_TO_L2_SELECTOR_OFFSET: u64 = 0x3;
    // 1
    const MESSAGE_TO_L2_TO_ADDRESS_OFFSET: u64 = 0x1;
    // End of generating constants!

    use std::bcs;
    use std::vector;
    use aptos_std::aptos_hash::keccak256;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;

    use starknet_addr::starknet_state;
    use starknet_addr::starknet_storage;

    struct MessageStorage has store, key {
        l1_to_l2_messages: SmartTable<vector<u8>, u256>,
        l2_to_l1_messages: SmartTable<vector<u8>, u256>,
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

    fun set_message_cancellation_delay(_delay_in_seconds: u256) {}

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
        starknet_storage::initialize(s, program_hash, verifier, config_hash, starknet_state::new(
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
        starknet_state::get_global_root(starknet_storage::get_state(@starknet_addr))
    }

    #[view]
    public fun state_block_number(): u256 {
        starknet_state::get_block_number(starknet_storage::get_state(@starknet_addr))
    }

    #[view]
    public fun state_block_hash(): u256 {
        starknet_state::get_block_hash(starknet_storage::get_state(@starknet_addr))
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
        assert!(vector::length(&program_output) >= HEADER_SIZE, ESTARKNET_OUTPUT_TOO_SHORT);
        // Validate config hash
        assert!(
            get_config_hash() == *vector::borrow(
                &program_output,
                CONFIG_HASH_OFFSET
            ),
            EINVALID_CONFIG_HASH
        );
        // Update state
        starknet_storage::update_state(@starknet_addr, program_output);


        // Process the messages after updating the state.
        // This is safer, as there is a call to transfer the fees during
        // the processing of the L1 -> L2 messages.

        // Process L2 -> L1 messages.
        let _output_offset = HEADER_SIZE;
        let _program_output_length = vector::length(&program_output);

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

        assert!(output_offset == vector::length(&program_output), ESTARKNET_OUTPUT_TOO_LONG);
        // Note that processing L1 -> L2 messages does an external call, and it shouldn't be
        // followed by storage changes.

        let state = starknet_storage::get_state(@starknet_addr);

        event::emit(LogStateUpdate {
            global_root: starknet_state::get_global_root(state),
            block_number: starknet_state::get_block_number(state),
            blockHash: starknet_state::get_block_hash(state)
        });
        // Re-entrancy protection (see above).
        assert!(state_block_number() == initial_block_number + 1, EINVALID_FINAL_BLOCK_NUMBER)
    }

    fun process_messages(is_L2_to_L1: bool, program_output: vector<u256>): u64 acquires MessageStorage {
        let msg_storage = borrow_global_mut<MessageStorage>(@starknet_addr);
        let l1_to_l2_messages = &mut msg_storage.l1_to_l2_messages;
        let l2_to_l1_messages = &mut msg_storage.l2_to_l1_messages;

        let message_segment_size = (*vector::borrow(&program_output, 0) as u64);
        assert!(message_segment_size < MAX_PAYLOAD_LENGTH, EINVALID_MESSAGE_SEGMENT_SIZE);

        let offset = 1u64;
        let message_segment_end = offset + message_segment_size;

        let payload_offset_size =
            if (is_L2_to_L1)
                MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET
            else
                MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET;

        let total_mgs_fees = 0;
        while (offset < message_segment_end) {
            let payload_length_offset = offset + payload_offset_size;
            assert!(
                payload_length_offset < vector::length(&program_output),
                EMESSAGE_TOO_SHORT
            );

            let payload_length = (*vector::borrow(&program_output, payload_length_offset) as u64);
            assert!(payload_length < MAX_PAYLOAD_LENGTH, EINVALID_PAYLOAD_LENGTH);

            let end_offset = payload_length_offset + payload_length;
            assert!(
                end_offset <= vector::length(&program_output),
                ETRUNCATED_MESSAGE_PAYLOAD
            );

            let msg_hash = keccak256(
                bcs::to_bytes(
                    &vector::slice(&program_output, offset, end_offset
                    )));

            if (is_L2_to_L1) {
                event::emit(LogMessageToL1 {
                    from_address: *vector::borrow(
                        &program_output,
                        offset + MESSAGE_TO_L1_FROM_ADDRESS_OFFSET
                    ),
                    to_address: *vector::borrow(
                        &program_output,
                        offset + MESSAGE_TO_L1_TO_ADDRESS_OFFSET
                    ),
                    payload: vector::slice(
                        &program_output,
                        offset + MESSAGE_TO_L1_PREFIX_SIZE,
                        end_offset
                    )
                });
                let msg = smart_table::borrow_mut_with_default(l2_to_l1_messages, msg_hash, 0);
                *msg = *msg + 1;
            } else {
                let msg_fee_plus_one = smart_table::borrow_mut(l1_to_l2_messages, msg_hash);
                assert!(*msg_fee_plus_one > 0, EINVALID_MESSAGE_TO_CONSUME);
                total_mgs_fees = total_mgs_fees + *msg_fee_plus_one - 1;
                smart_table::upsert(l1_to_l2_messages, msg_hash, 0);

                let nonce = *vector::borrow(&program_output, MESSAGE_TO_L2_NONCE_OFFSET);
                let msgs = vector::slice(
                    &program_output,
                    offset + MESSAGE_TO_L2_PREFIX_SIZE,
                    end_offset
                );
                event::emit(ConsumedMessageToL2 {
                    from_address: *vector::borrow(
                        &program_output,
                        offset + MESSAGE_TO_L2_FROM_ADDRESS_OFFSET
                    ),
                    to_address: *vector::borrow(
                        &program_output,
                        offset + MESSAGE_TO_L2_TO_ADDRESS_OFFSET
                    ),
                    selector: *vector::borrow(
                        &program_output,
                        offset + MESSAGE_TO_L2_SELECTOR_OFFSET
                    ),
                    payload: msgs,
                    nonce,
                    fee: 0
                });
            };
            offset = end_offset;
        };

        assert!(offset == message_segment_end, EINVALID_MESSAGE_SEGMENT_SIZE);

        if (total_mgs_fees > 0) {
            // TODO: transfer fees
        };

        return offset
    }

    #[test(s = @starknet_addr)]
    fun update_state_success(s: &signer) {
        let state = starknet_state::new(0, 0, 0);

        let msg_storage = MessageStorage {
            l1_to_l2_messages: smart_table::new(),
            l2_to_l1_messages: smart_table::new()
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