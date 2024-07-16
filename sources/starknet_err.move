module starknet_addr::starknet_err {

    const EINVALID_BLOCK_NUMBER: u64 = 0x20001;
    const EINVALID_PREVIOUS_ROOT: u64 = 0x20002;
    const EINVALID_CONFIG_HASH: u64 = 0x20003;

    const ENAMED_STORAGE_ALREADY_SET: u64 = 0x30001;

    const EINVALID_MESSAGE_SEGMENT_SIZE: u64 = 0x40001;
    const EMESSAGE_TOO_SHORT: u64 = 0x40002;
    const EINVALID_PAYLOAD_LENGTH: u64 = 0x40003;
    const ETRUNCATED_MESSAGE_PAYLOAD: u64 = 0x40004;
    const EINVALID_MESSAGE_TO_CONSUME: u64 = 0x40005;
    const ESTARKNET_OUTPUT_TOO_LONG: u64 = 0x40006;
    const EINVALID_FINAL_BLOCK_NUMBER: u64 = 0x40007;
    const ESTARKNET_OUTPUT_TOO_SHORT: u64 = 0x40008;

    const UNEXPECTED_KZG_DA_FLAG: u64 = 0x50001;

    const NO_STATE_TRANSITION_PROOF: u64 = 0x6001;

    public fun err_no_state_transition_proof(): u64 {
        return NO_STATE_TRANSITION_PROOF
    }

    public fun err_invalid_block_number(): u64 {
        return EINVALID_BLOCK_NUMBER
    }

    public fun err_invalid_prev_root(): u64 {
        return EINVALID_BLOCK_NUMBER
    }

    public fun err_invalid_config_hash(): u64 {
        return EINVALID_CONFIG_HASH
    }

    public fun err_starknet_output_too_short(): u64 {
        return ESTARKNET_OUTPUT_TOO_SHORT
    }

    public fun err_named_storage_already_set(): u64 {
        return ENAMED_STORAGE_ALREADY_SET
    }

    public fun err_invalid_message_segment_size(): u64 {
        return EINVALID_MESSAGE_SEGMENT_SIZE
    }

    public fun err_message_too_short(): u64 {
        return EMESSAGE_TOO_SHORT
    }

    public fun err_invalid_payload_length(): u64 {
        return EINVALID_PAYLOAD_LENGTH
    }

    public fun err_truncated_message_payload(): u64 {
        return ETRUNCATED_MESSAGE_PAYLOAD
    }

    public fun err_invalid_message_to_consume(): u64 {
        return EINVALID_MESSAGE_TO_CONSUME
    }

    public fun err_starknet_output_too_long(): u64 {
        return ESTARKNET_OUTPUT_TOO_LONG
    }

    public fun err_invalid_final_block_number(): u64 {
        return EINVALID_FINAL_BLOCK_NUMBER
    }

    public fun err_unexpected_kzg_da_flag(): u64 {
        return UNEXPECTED_KZG_DA_FLAG
    }
}