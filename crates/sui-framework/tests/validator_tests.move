// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sui::validator_tests {
    use sui::coin;
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::validator;
    use sui::stake::Stake;
    use sui::locked_coin::{Self, LockedCoin};
    use sui::stake;
    use std::option;

    #[test]
    fun test_validator_owner_flow() {
        // Proof of possesion generated from sui/crates/sui-types/src/unit_tests/crypto_tests.rs
        let sender = @0xaf76afe6f866d8426d2be85d6ef0b11f871a251d043b2f11e15563bf418f5a5a;
        let pubkey = vector[153, 242, 94, 246, 31, 128, 50, 185, 20, 99, 100, 96, 152, 44, 92, 198, 241, 52, 239, 29, 218, 231, 102, 87, 242, 203, 254, 193, 235, 252, 141, 9, 115, 116, 8, 13, 246, 252, 240, 220, 184, 188, 75, 13, 142, 10, 245, 216, 14, 187, 255, 43, 76, 89, 159, 84, 244, 45, 99, 18, 223, 195, 20, 39, 96, 120, 193, 204, 52, 126, 187, 190, 197, 25, 139, 226, 88, 81, 63, 56, 107, 147, 13, 2, 194, 116, 154, 128, 62, 35, 48, 149, 94, 189, 26, 16];
        let pop = vector[170, 123, 102, 14, 115, 218, 115, 118, 170, 89, 192, 247, 101, 58, 60, 31, 48, 30, 9, 47, 0, 59, 54, 9, 136, 148, 14, 159, 198, 205, 109, 33, 189, 144, 195, 122, 18, 111, 137, 207, 112, 77, 204, 241, 187, 152, 88, 238];

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);

            let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));
            let validator = validator::new(
                sender,
                pubkey,
                vector[171, 2, 39, 3, 139, 105, 166, 171, 153, 151, 102, 197, 151, 186, 140, 116, 114, 90, 213, 225, 20, 167, 60, 69, 203, 12, 180, 198, 9, 217, 117, 38],
                vector[],
                pop,
                b"Validator1",
                b"Validator1",
                b"Validator1",
                b"Validator1",
                x"FFFF",
                x"FFFF",
                x"FFFF",
                x"FFFF",
                init_stake,
                option::none(),
                1,
                0,
                0,
                ctx
            );
            assert!(validator::stake_amount(&validator) == 10, 0);
            assert!(validator::sui_address(&validator) == sender, 0);

            validator::destroy(validator, ctx);
        };

        // Check that after destroy, the original stake still exists.
        test_scenario::next_tx(scenario, sender);
        {
            let stake = test_scenario::take_from_sender<Stake>(scenario);
            assert!(stake::value(&stake) == 10, 0);
            test_scenario::return_to_sender(scenario, stake);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_pending_validator_flow() {
        // Proof of possesion generated from sui/crates/sui-types/src/unit_tests/crypto_tests.rs
        let sender = @0xaf76afe6f866d8426d2be85d6ef0b11f871a251d043b2f11e15563bf418f5a5a;
        let pubkey = vector[153, 242, 94, 246, 31, 128, 50, 185, 20, 99, 100, 96, 152, 44, 92, 198, 241, 52, 239, 29, 218, 231, 102, 87, 242, 203, 254, 193, 235, 252, 141, 9, 115, 116, 8, 13, 246, 252, 240, 220, 184, 188, 75, 13, 142, 10, 245, 216, 14, 187, 255, 43, 76, 89, 159, 84, 244, 45, 99, 18, 223, 195, 20, 39, 96, 120, 193, 204, 52, 126, 187, 190, 197, 25, 139, 226, 88, 81, 63, 56, 107, 147, 13, 2, 194, 116, 154, 128, 62, 35, 48, 149, 94, 189, 26, 16];
        let pop = vector[170, 123, 102, 14, 115, 218, 115, 118, 170, 89, 192, 247, 101, 58, 60, 31, 48, 30, 9, 47, 0, 59, 54, 9, 136, 148, 14, 159, 198, 205, 109, 33, 189, 144, 195, 122, 18, 111, 137, 207, 112, 77, 204, 241, 187, 152, 88, 238];

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        let ctx = test_scenario::ctx(scenario);
        let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));

        let validator = validator::new(
            sender,
            pubkey,
            vector[171, 2, 39, 3, 139, 105, 166, 171, 153, 151, 102, 197, 151, 186, 140, 116, 114, 90, 213, 225, 20, 167, 60, 69, 203, 12, 180, 198, 9, 217, 117, 38],
            vector[],
            pop,
            b"Validator1",
            b"Validator1",
            b"image_url1",
            b"project_url1",
            x"FFFF",
            x"FFFF",
            x"FFFF",
            x"FFFF",
            init_stake,
            option::none(),
            1,
            0,
            0,
            ctx
        );

        test_scenario::next_tx(scenario, sender);
        {
            let ctx = test_scenario::ctx(scenario);
            let new_stake = coin::into_balance(coin::mint_for_testing(30, ctx));
            validator::request_add_stake(&mut validator, new_stake, option::none(), ctx);

            assert!(validator::stake_amount(&validator) == 10, 0);
            assert!(validator::pending_stake_amount(&validator) == 30, 0);
        };

        test_scenario::next_tx(scenario, sender);
        {
            let stake = test_scenario::take_from_sender<Stake>(scenario);
            let ctx = test_scenario::ctx(scenario);
            validator::request_withdraw_stake(&mut validator, &mut stake, 5, 35, ctx);
            test_scenario::return_to_sender(scenario, stake);
            assert!(validator::stake_amount(&validator) == 10, 0);
            assert!(validator::pending_stake_amount(&validator) == 30, 0);
            assert!(validator::pending_withdraw(&validator) == 5, 0);

            // Calling `adjust_stake_and_gas_price` will withdraw the coin and transfer to sender.
            validator::adjust_stake_and_gas_price(&mut validator);

            assert!(validator::stake_amount(&validator) == 35, 0);
            assert!(validator::pending_stake_amount(&validator) == 0, 0);
            assert!(validator::pending_withdraw(&validator) == 0, 0);
        };

        test_scenario::next_tx(scenario, sender);
        {
            let withdraw = test_scenario::take_from_sender<LockedCoin<SUI>>(scenario);
            assert!(locked_coin::value(&withdraw) == 5, 0);
            test_scenario::return_to_sender(scenario, withdraw);
        };

        validator::destroy(validator, test_scenario::ctx(scenario));
        test_scenario::end(scenario_val);
    }
}
