module starknet_addr::starknet_validity {

    use std::bcs;
    use std::vector;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event;

    use starknet_addr::bytes::{num_to_bytes_be, to_bytes_24_be, vec_to_bytes_be};
    use starknet_addr::fact_registry;
    use starknet_addr::kzg_helper;
    use starknet_addr::onchain_data_fact_tree_encoded as onchain_data_fact;
    use starknet_addr::pre_compile;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;
    use starknet_addr::starknet_state;
    use starknet_addr::starknet_storage;

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
            *vector::borrow(program_output, starknet_output::get_config_hash_offset()) == get_config_hash(),
            starknet_err::err_invalid_config_hash()
        );

        let program_hash: vector<u8> = num_to_bytes_be(&get_program_hash());
        let buffer: vector<u8> = vector::empty<u8>();
        vector::append(&mut buffer, program_hash);
        vector::append(&mut buffer, state_transition_fact);
        let sharp_fact = keccak256(buffer);
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
        let pre_kzg_segment = vector::slice(
            &program_output,
            starknet_output::get_header_size(),
            vector::length(&program_output)
        );
        let kzg_segment = vector::slice(&pre_kzg_segment, 0u64, starknet_output::get_kzg_segment_size());
        verify_kzg_proof(&kzg_segment, &kzg_proof);

        let state_transition_fact = keccak256(vec_to_bytes_be(&program_output));
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

        let blob_hash: vector<u8> = get_blob_hash();

        // TODO: Write a get_blobhash(index) return the versioned hash version of blob index t-th
        // assert!(
        //     bcs::to_bytes(&(*vector::borrow(&blob_hash, 0u64))) == helper::get_versioned_hash_version_kzg(),
        //     starknet_err::err_unexpected_blob_hash_version()
        // );
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
            vector::append(&mut kzg_commitment, to_bytes_24_be(&bcs::to_bytes(&kzg_commitment_high)));
            vector::append(&mut kzg_commitment, to_bytes_24_be(&bcs::to_bytes(&kzg_commitment_low)));

            y = num_to_bytes_be(&((y_high << 128) + y_low));
        };
        let z = *vector::borrow(kzg_segment, 2);

        let precompile_input: vector<u8> = vector::empty<u8>();
        vector::append(&mut precompile_input, blob_hash);
        vector::append(&mut precompile_input, num_to_bytes_be(&z));
        vector::append(&mut precompile_input, y);
        vector::append(&mut precompile_input, kzg_commitment);
        vector::append(&mut precompile_input, *kzg_proof);

        let (precompile_output, ok) = pre_compile::point_evaluation_precompile(precompile_input);
        assert!(ok, starknet_err::err_point_evaluation_precompile_call_failed());

        assert!(
            keccak256(precompile_output) == kzg_helper::get_point_evaluation_precompile_output(),
            starknet_err::err_unexpected_point_evaluation_precompile_output()
        );
    }

    public fun get_blob_hash(): vector<u8> {
        x"010b37b597b57e4c7d3df9c81ceb00130e2cca57679e6ddae2144503c5f751a1"
    }

    #[test(s = @starknet_addr)]
    fun test_update_state_kzg_da(s: &signer) {
        let state = starknet_state::new(
            1140305933455702090030976682007678821560814182066058788699329257003131568320,
            663730,
            0
        );

        starknet_storage::initialize(
            s,
            1865367024509426979036104162713508294334262484507712987283009063059134893433,
            @starknet_addr,
            2590421891839256512113614983194993186457498815986333310670788206383913888162,
            state
        );

        let program_output: vector<u256> = vector[
            1140305933455702090030976682007678821560814182066058788699329257003131568320,
            2564087571168869030849741453167808611635007296011392663568683807641455099416,
            663731,
            1537006764759948130436448467054129621068903866332413870731059124996705590800,
            2590421891839256512113614983194993186457498815986333310670788206383913888162,
            1,
            5495246417610986281159676219993690967067612120205267783816,
            3761087859177836140573657651666911802410811047530211431325,
            2609772038065995024432088513112532882720771352701829745873416390305542106921,
            94771607049779468086511148776901632421,
            36434806342950337696864723428487729449,
            8,
            3256441166037631918262930812410838598500200462657642943867372734773841898370,
            993696174272377493693496825928908586134624850969,
            5,
            0,
            259250955146465173507305340095009695073789544843,
            4543560,
            4136982361299020,
            0,
            0
        ];

        // This test depends on the value of `fact`, which is precomputed and registered before updating the state.
        // All test data is taken from transaction 0xe76c6accacbcedb7f66d5dc3f1a3e189d4e4d194ea88c19ee29955adbc902362.

        fact_registry::register_fact(s, x"af6d61465fa108b0e7d4d9bef635dec868bcfa8e9fa14c5486c6017cd552fd4c");

        let kzg_proof: vector<u8> = x"8664b3057bc3aefaf110db484fdc0c422c58209c7f8a331a4c5f853a9e37d0de5f02ec0289d7d0634e49ef813fb8e84d";

        update_state_kzg_da(program_output, kzg_proof);
    }

    #[test(s = @starknet_addr)]
    fun test_update_state(s: &signer) {
        let state = starknet_state::new(
            1970272326382990453316397420342340810466901058626735958618873840050980391150,
            608890,
            0
        );

        starknet_storage::initialize(
            s,
            109586309220455887239200613090920758778188956576212125550190099009305121410,
            @starknet_addr,
            2590421891839256512113614983194993186457498815986333310670788206383913888162,
            state
        );

        let program_output = vector[
            1970272326382990453316397420342340810466901058626735958618873840050980391150,
            3458474516901043875685413386881507261498565942069144376940366111442758962633,
            608891,
            492947369139090042378802255177414102958465992946764632218968988097869936180,
            2590421891839256512113614983194993186457498815986333310670788206383913888162,
            0,
            0,
            0
        ];

        let onchain_data_hash = 4643044994485936859054407373370718990191010183076115682089501129170;
        let onchain_data_size = 17360712499668091053135558285859368683200285152058604480060410253312987758592;

        // This test depends on the value of `fact`, which is precomputed and registered before updating the state.
        // All test data is taken from transaction 0xd7cfa525566850a190eec7937da2f8e43c8e87873747e5a41c74adb404210472.
        // The expected `onchain_data_hash` and `onchain_data_size` may change when simulating the transaction.

        fact_registry::register_fact(s, x"b7fae2e2b20a6e0c96d4899cbd47f0af865f53afe75a1482ab5d637a89d8aca4");
        update_state(program_output, onchain_data_hash, onchain_data_size);
    }
}