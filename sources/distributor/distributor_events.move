module vault::distributor_events {
    use sui::event;
    use sui::object::ID;
    use std::type_name;
    use std::ascii;

    friend vault::distributor;

    struct DistributionCreated has copy, drop {
        coin_type: vector<u8>,
        share_type: vector<u8>,
        amount: u64,
        timestamp: u64,
        distribution_id: ID,
    }

    public(friend) fun distribution_created<TCoin, TShare>(amount: u64, distribution_id: ID, timestamp: u64) {
        event::emit(DistributionCreated {
            coin_type: ascii::into_bytes(type_name::into_string(type_name::get<TCoin>())),
            share_type: ascii::into_bytes(type_name::into_string(type_name::get<TShare>())),
            amount,
            distribution_id,
            timestamp
        });
    }

    public(friend) fun distribution_claimed(
        distribution_id: ID,
        new_amount: u64,
        share_bucket_id: ID,
    ) {
        event::emit(DistributionClaimed {
            distribution_id,
            new_amount,
            share_bucket_id
        });
    }

    struct DistributionClaimed  has copy, drop {
        distribution_id: ID,
        share_bucket_id: ID,
        new_amount: u64
    }

    public(friend) fun distribution_cleaned_up(distribution: ID) {
        event::emit(DistributionCleanedUp {
            distribution
        });
    }

    struct DistributionCleanedUp  has copy, drop {
        distribution: ID,
    }
}