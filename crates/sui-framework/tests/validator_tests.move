// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sui::validator_tests {
    use std::ascii;
    use std::string::Self;
    use sui::coin;
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::url;
    use sui::validator::{Self, Validator};
    use sui::stake::Stake;
    use sui::tx_context::{Self, TxContext};
    use sui::locked_coin::{Self, LockedCoin};
    use sui::balance::Balance;
    use sui::stake;
    use std::option;

    const PROTOCOL_PUBKEY: vector<u8> = vector[131, 117, 151, 65, 106, 116, 161, 1, 125, 44, 138, 143, 162, 193, 244, 241, 19, 159, 175, 120, 76, 35, 83, 213, 49, 79, 36, 21, 121, 79, 86, 242, 16, 1, 185, 176, 31, 191, 121, 156, 221, 167, 20, 33, 126, 19, 4, 105, 15, 229, 33, 187, 35, 99, 208, 103, 214, 176, 193, 196, 168, 154, 172, 78, 102, 5, 52, 113, 233, 213, 195, 23, 172, 220, 90, 232, 23, 17, 97, 66, 153, 105, 253, 219, 145, 125, 216, 254, 125, 49, 227, 8, 6, 206, 88, 13];
    const NETWORK_PUBKEY: vector<u8> = vector[171, 2, 39, 3, 139, 105, 166, 171, 153, 151, 102, 197, 151, 186, 140, 116, 114, 90, 213, 225, 20, 167, 60, 69, 203, 12, 180, 198, 9, 217, 117, 38];
    const WORKER_PUBKEY: vector<u8> = vector[];
    const PROOF_OF_POSSESSION: vector<u8> = vector[150, 32, 70, 34, 231, 29, 255, 62, 248, 219, 245, 72, 85, 77, 190, 195, 251, 255, 166, 250, 229, 133, 29, 117, 17, 182, 0, 164, 162, 59, 36, 250, 78, 129, 8, 46, 106, 112, 197, 152, 219, 114, 241, 121, 242, 189, 75, 204];


    #[test_only]
    fun get_test_validator(ctx: &mut TxContext, init_stake: Balance<SUI>): Validator {
        let sender = tx_context::sender(ctx);
        validator::new(
            sender,
            PROTOCOL_PUBKEY,
            NETWORK_PUBKEY,
            WORKER_PUBKEY,
            PROOF_OF_POSSESSION,
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
        )
    }

    #[test]
    fun test_validator_owner_flow() {
        let sender = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);

            let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));

            let validator = get_test_validator(ctx, init_stake);
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
        let sender = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;
        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        let ctx = test_scenario::ctx(scenario);
        let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));

        let validator = get_test_validator(ctx, init_stake);
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

    #[test]
    fun test_validator_update_metadata_ok() {
        let sender = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;
        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        let ctx = test_scenario::ctx(scenario);
        let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));

        let validator = get_test_validator(ctx, init_stake);

        test_scenario::next_tx(scenario, sender);
        {
            validator::update_next_epoch_network_address(&mut validator, x"6666");
            validator::update_next_epoch_p2p_address(&mut validator, x"7777");
            validator::update_next_epoch_consensus_address(&mut validator, x"8888");
            validator::update_next_epoch_worker_address(&mut validator, x"9999");
            validator::update_next_epoch_protocol_pubkey(
                &mut validator,
                vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105],
                vector[141, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3],
            );
            validator::update_next_epoch_worker_pubkey(
                &mut validator,
                vector[0, 0, 0, 0]
            );
            validator::update_next_epoch_network_pubkey(
                &mut validator,
                vector[1, 1, 1, 1]
            );

            validator::update_name(&mut validator, string::from_ascii(ascii::string(b"new_name")));
            validator::update_description(&mut validator, string::from_ascii(ascii::string(b"new_desc")));
            validator::update_image_url(&mut validator, url::new_unsafe_from_bytes(b"new_image_url"));
            validator::update_project_url(&mut validator, url::new_unsafe_from_bytes(b"new_proj_url"));
        };

        test_scenario::next_tx(scenario, sender);
        {
            // Current epoch
            assert!(validator::name(&mut validator) == &string::from_ascii(ascii::string(b"new_name")), 0);
            assert!(validator::description(&mut validator) == &string::from_ascii(ascii::string(b"new_desc")), 0);
            assert!(validator::image_url(&mut validator) == &url::new_unsafe_from_bytes(b"new_image_url"), 0);
            assert!(validator::project_url(&mut validator) == &url::new_unsafe_from_bytes(b"new_proj_url"), 0);
            assert!(validator::network_address(&validator) == &x"FFFF", 0);
            assert!(validator::p2p_address(&validator) == &x"FFFF", 0);
            assert!(validator::consensus_address(&validator) == &x"FFFF", 0);
            assert!(validator::worker_address(&validator) == &x"FFFF", 0);
            assert!(validator::protocol_pubkey_bytes(&validator) == &PROTOCOL_PUBKEY, 0);
            assert!(validator::proof_of_possession(&validator) == &PROOF_OF_POSSESSION, 0);
            assert!(validator::network_pubkey_bytes(&validator) == &NETWORK_PUBKEY, 0);
            assert!(validator::worker_pubkey_bytes(&validator) == &WORKER_PUBKEY, 0);

            // Next epoch
            assert!(validator::next_epoch_network_address(&validator) == &option::some(x"6666"), 0);
            assert!(validator::next_epoch_p2p_address(&validator) == &option::some(x"7777"), 0);
            assert!(validator::next_epoch_consensus_address(&validator) == &option::some(x"8888"), 0);
            assert!(validator::next_epoch_worker_address(&validator) == &option::some(x"9999"), 0);
            assert!(
                validator::next_epoch_protocol_pubkey_bytes(&validator) == &option::some(vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105]),
                0
            );
            assert!(
                validator::next_epoch_proof_of_possession(&validator) == &option::some(vector[141, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3]),
                0
            );
            assert!(
                validator::next_epoch_worker_pubkey_bytes(&validator) == &option::some(vector[0, 0, 0, 0]),
                0
            );
            assert!(
                validator::next_epoch_network_pubkey_bytes(&validator) == &option::some(vector[1, 1, 1, 1]),
                0
            );
        };

        validator::destroy(validator, test_scenario::ctx(scenario));
        test_scenario::end(scenario_val);
    }

    #[expected_failure(abort_code = sui::validator::EInvalidProofOfPossession)]
    #[test]
    fun test_validator_update_metadata_invalid_proof_of_possession() {
        let sender = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;
        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        let ctx = test_scenario::ctx(scenario);
        let init_stake = coin::into_balance(coin::mint_for_testing(10, ctx));

        let validator = get_test_validator(ctx, init_stake);

        test_scenario::next_tx(scenario, sender);
        {
            validator::update_next_epoch_protocol_pubkey(
                &mut validator,
                vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105],
                // This is invalid proof of possession, so we abort
                vector[121, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3],
            );
        };

        validator::destroy(validator, test_scenario::ctx(scenario));
        test_scenario::end(scenario_val);
    }
}
