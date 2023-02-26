module vault::aggregator_events {
    use sui::object::ID;
    use sui::event;

    friend vault::aggregator;

    struct AggregatorCreated<phantom TCoin, phantom TShare> has copy, drop {
        id: ID
    }

    public(friend) fun aggregator_created<TCoin, TShare>(id: ID) {
        event::emit(AggregatorCreated<TCoin, TShare> {
            id
        });
    }

    struct CoinDeposited has copy, drop {
        aggregator_id: ID,
        amount: u64,
        new_aggregator_total_amount: u64
    }

    public(friend) fun coin_deposited(aggregator_id: ID, amount: u64, new_aggregator_total_amount: u64) {
        event::emit(CoinDeposited {
            aggregator_id,
            amount,
            new_aggregator_total_amount
        });
    }
}