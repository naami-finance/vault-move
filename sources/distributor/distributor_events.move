module vault::distributor_events {
    use sui::event;
    use sui::object::ID;

    friend vault::distributor;

    struct DistributionCreated<phantom TCoin, phantom TShare> has copy, drop {
        amount: u64,
        distribution_id: ID,
    }

    public(friend) fun distribution_created<TCoin, TShare>(amount: u64, distribution_id: ID) {
        event::emit(DistributionCreated<TCoin, TShare> {
            amount,
            distribution_id
        });
    }

    public(friend) fun distribution_claimed(distribution_id: ID, new_amount: u64) {
        event::emit(DistributionClaimed {
            distribution_id,
            new_amount
        });
    }

    struct DistributionClaimed  has copy, drop {
        distribution_id: ID,
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