module vault::safe {

    use sui::object::UID;
    use sui::coin::Coin;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::object;

    use std::ascii;
    use std::type_name;
    use std::vector;
    use sui::dynamic_object_field;
    use vault::aggregator::Aggregator;
    use vault::aggregator;
    use sui::coin;

    struct Safe has key, store {
        id: UID
    }

    public fun create(ctx: &mut TxContext): Safe {
        Safe {
            id: object::new(ctx)
        }
    }

    public entry fun deposit<TCoin, TShare>(
        safe: &mut Safe,
        coin: Coin<TCoin>,
        ctx: &mut TxContext
    ) {
        let key = get_key<TCoin, TShare>();
        if (!dynamic_object_field::exists_(&mut safe.id, key)) {
            // aggregator does not exist, so create it instead
            let balance = coin::into_balance(coin);
            dynamic_object_field::add(
                &mut safe.id,
                key,
                aggregator::create<TCoin, TShare>(balance, ctx)
            );
        } else {
            aggregator::deposit(
                dynamic_object_field::borrow_mut<
                    vector<u8>,
                    Aggregator<TCoin, TShare>
                >(&mut safe.id, key),
                coin,
            );
        }
    }


    public entry fun distribute<TCoin, TShare>(
        safe: &mut Safe,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let key = get_key<TCoin, TShare>();
        assert!(dynamic_object_field::exists_(&mut safe.id, key), 999);

        let aggregator = dynamic_object_field::borrow_mut<
            vector<u8>,
            Aggregator<TCoin, TShare>
        >(&mut safe.id, key);

        transfer::share_object(
            aggregator::distribute(aggregator, amount, ctx)
        );
    }


    // can be simplified
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