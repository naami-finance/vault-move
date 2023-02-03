module naami::vault_registry {
    use sui::object::UID;
    use naami::vault::{Self};
    use sui::tx_context::TxContext;
    use std::ascii;
    use std::type_name;
    use std::vector;
    use sui::dynamic_object_field;

    struct VaultRegistry {
        id: UID
    }

    public fun create_vault<TCoin, TShare>(registry: &mut VaultRegistry, ctx: &mut TxContext) {
        let key = get_key<TCoin, TShare>();
        assert!(!dynamic_object_field::exists_(&mut registry.id, key), 0);

        let vault = vault::create<TCoin, TShare>(ctx);
        dynamic_object_field::add(&mut registry.id, key, vault);
    }

    // ensure TCoin is Coin<T> and TShare is ShareBucket<T> ?
    fun get_key<TCoin, TShare>(): vector<u8> {
        let x = ascii::into_bytes(type_name::into_string(type_name::get<TCoin>()));
        let y = ascii::into_bytes(type_name::into_string(type_name::get<TShare>()));

        assert!(&x != &y, 0);

        let x_length = vector::length(&x);
        let y_length = vector::length(&y);

        let length = if (x_length > y_length) y_length else x_length;

        let i = 0;
        while (i <= length) {
            let x_val = vector::borrow(&x, i);
            let y_val = vector::borrow(&y, i);

            if (*x_val > *y_val) {
                vector::append(&mut x, y);
                return (x)
            };

            if (*y_val > *x_val) {
                vector::append(&mut y, x);
                return (y)
            };

            i = i + 1;
        };

        vector::append(&mut x, y);
        (x)
    }
}