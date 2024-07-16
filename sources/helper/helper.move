module starknet_addr::helper {

    use std::vector;

    public fun u256_to_bytes(value: u256): vector<u8> {
        let bytes = vector::empty<u8>();
        let n = value;
        while (n > 0) {
            let byte = ((n % 256) as u8);
            vector::push_back(&mut bytes, byte);
            n = n / 256;
        };
        while (vector::length(&bytes) < 32) {
            vector::push_back(&mut bytes, 0);
        };
        vector::reverse(&mut bytes);
        bytes
    }

    public fun bytes_to_256(value: &vector<u8>): u256 {
        assert!(
            vector::length(value) == 32, 0x60001
        );
        let result: u256 = 0;
        let factor: u256 = 1;
        let length = vector::length(value);
        for (i in 0..length) {
            result = result + (*vector::borrow(value, i) as u256) * factor;
            factor = factor * 256;
        };
        result
    }

    public fun append_vector(des: &mut vector<u8>, src: &vector<u8>) {
        let len = vector::length(src);
        for (i in 0..len) {
            vector::push_back(des, *vector::borrow(src, i));
        }
    }
}