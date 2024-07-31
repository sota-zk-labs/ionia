module starknet_addr::starknet_validity {

    use std::bcs;
    use std::vector;
    use aptos_std::aptos_hash::keccak256;
    use aptos_std::debug;
    use aptos_framework::event;

    use starknet_addr::bytes::{num_to_bytes_be, to_bytes_24_be};
    use starknet_addr::fact_registry;
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

        let state_transition_fact = keccak256(bcs::to_bytes(&program_output));
        debug::print(&state_transition_fact);
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

        let blob_hash: vector<u8> = x"0000000000000000000000000000000030946f3d87c8396d89c9bcf81ff3f232";

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
            keccak256(precompile_output) == POINT_EVALUATION_PRECOMPILE_OUTPUT,
            starknet_err::err_unexpected_point_evaluation_precompile_output()
        );
    }

    // #[test(s = @starknet_addr)]
    // fun test_update_state_kzg_da(s: &signer) {
    //     let state = starknet_state::new(0, 0, 0);
    //
    //     starknet_storage::initialize(
    //         s,
    //         1865367024509426979036104162713508294334262484507712987283009063059134893433,
    //         @starknet_addr,
    //         1553709454334774815764988612122634988906525555606597726644370513828557599647,
    //         state
    //     );
    //
    //     let program_output: vector<u256> = vector[
    //         2624495537743027597317971413655252110020834612827084833271773726863892158624,
    //         1518367200064081803680226907302538101202884873406076021112221967874915088145,
    //         663431,
    //         2519277086832679430044243670722131833880392874732106984033502911367536922509,
    //         2590421891839256512113614983194993186457498815986333310670788206383913888162,
    //         1,
    //         3599416175753320398983393619113548553286501362553103395308,
    //         4155295208113501251616340107677977620218240196840682461552,
    //         767379359787008064110421700070180377135058496841271215821598844962655746136,
    //         178669605765425549635792566257888423470,
    //         64573659955145567779264716045548778034,
    //         8,
    //         1664015738346703719092667845204826968002822652638997199367526143920141278968,
    //         1298815730822278902934766636815198998626615520107,
    //         5,
    //         1056821354461963493869604920442253899646534182978,
    //         785016880065820721037654191378140574206732777048,
    //         58373382721912932178140442381368767362441948891759404896140321857349706904,
    //         2859039056179775280844,
    //         0,
    //         0
    //     ];
    //     let kzg_proof: vector<u8> = x"b069a1cd9573be2387183d5cac41659a3d20d3a1091c5489421dd599cd032b9b5cd89ac4fcdad4ce4aea9a7f6934c2af";
    //
    //     update_state_kzg_da(program_output, kzg_proof);
    // }

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