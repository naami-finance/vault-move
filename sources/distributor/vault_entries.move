module naami::vault_entries {
    use naami::vault::{Vault, Self};

    use sui::tx_context::TxContext;
    use sui::coin::Coin;
    use sui::transfer;

    public entry fun deposit<TCoin, TShare>(vault: &mut Vault<TCoin, TShare>, coin: Coin<TCoin>){
        vault::deposit(vault, coin);
    }

    public entry fun distribute<TCoin, TShare>(
        vault: &mut Vault<TCoin, TShare>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        transfer::share_object(vault::distribute(vault, amount, ctx));
    }
}