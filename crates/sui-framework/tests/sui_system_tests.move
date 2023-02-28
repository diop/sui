// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// This file contains tests testing functionalities in `sui_system` that are not
// already tested by the other more themed tests such as `delegation_tests` or
// `rewards_distribution_tests`.

#[test_only]
module sui::sui_system_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::governance_test_utils::{add_validator, advance_epoch, remove_validator, set_up_sui_system_state};
    use sui::sui_system::{Self, SuiSystemState};
    use sui::validator::Self;
    use sui::vec_set;
    use sui::table;
    use sui::coin;
    use sui::validator::Validator;
    use sui::test_utils::assert_eq;
    use std::option::Self;
    use sui::url;
    use std::string;
    use std::ascii;

    #[test]
    fun test_report_validator() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);

        report_helper(@0x1, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1], 0);
        report_helper(@0x3, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1, @0x3], 0);

        // Report again and result should stay the same.
        report_helper(@0x1, @0x2, false, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1, @0x3], 0);

        // Undo the report.
        report_helper(@0x3, @0x2, true, scenario);
        assert!(get_reporters_of(@0x2, scenario) == vector[@0x1], 0);

        advance_epoch(scenario);

        // After an epoch ends, report records are reset.
        assert!(get_reporters_of(@0x2, scenario) == vector[], 0);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::ENotValidator)]
    fun test_report_non_validator_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x1, @0x42, false, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::ECannotReportOneself)]
    fun test_report_self_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x1, @0x1, false, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = sui_system::EReportRecordNotFound)]
    fun test_undo_report_failure() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        report_helper(@0x2, @0x1, true, scenario);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_staking_pool_mappings() {
        let scenario_val = test_scenario::begin(@0x0);
        let scenario = &mut scenario_val;

        set_up_sui_system_state(vector[@0x1, @0x2, @0x3], scenario);
        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let pool_id_1 = sui_system::validator_staking_pool_id(&system_state, @0x1);
        let pool_id_2 = sui_system::validator_staking_pool_id(&system_state, @0x2);
        let pool_id_3 = sui_system::validator_staking_pool_id(&system_state, @0x3);
        let pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        assert_eq(table::length(pool_mappings), 3);
        assert_eq(*table::borrow(pool_mappings, pool_id_1), @0x1);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        test_scenario::return_shared(system_state);

        let new_validator_addr = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;
        test_scenario::next_tx(scenario, new_validator_addr);

        // Add a validator
        add_validator(new_validator_addr, 100, scenario);
        advance_epoch(scenario);

        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let pool_id_4 = sui_system::validator_staking_pool_id(&system_state, new_validator_addr);
        pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        // Check that the previous mappings didn't change as well.
        assert_eq(table::length(pool_mappings), 4);
        assert_eq(*table::borrow(pool_mappings, pool_id_1), @0x1);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        assert_eq(*table::borrow(pool_mappings, pool_id_4), new_validator_addr);
        test_scenario::return_shared(system_state);

        // Remove one of the original validators.
        remove_validator(@0x1, scenario);
        advance_epoch(scenario);

        test_scenario::next_tx(scenario, @0x1);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        pool_mappings = sui_system::validator_staking_pool_mappings(&system_state);
        // Check that the previous mappings didn't change as well.
        assert_eq(table::length(pool_mappings), 3);
        assert_eq(table::contains(pool_mappings, pool_id_1), false);
        assert_eq(*table::borrow(pool_mappings, pool_id_2), @0x2);
        assert_eq(*table::borrow(pool_mappings, pool_id_3), @0x3);
        assert_eq(*table::borrow(pool_mappings, pool_id_4), new_validator_addr);
        test_scenario::return_shared(system_state);

        test_scenario::end(scenario_val);
    }

    fun report_helper(reporter: address, reported: address, is_undo: bool, scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, reporter);

        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let ctx = test_scenario::ctx(scenario);
        if (is_undo) {
            sui_system::undo_report_validator(&mut system_state, reported, ctx);
        } else {
            sui_system::report_validator(&mut system_state, reported, ctx);
        };
        test_scenario::return_shared(system_state);
    }

    fun get_reporters_of(addr: address, scenario: &mut Scenario): vector<address> {
        test_scenario::next_tx(scenario, addr);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let res = vec_set::into_keys(sui_system::get_reporters_of(&system_state, addr));
        test_scenario::return_shared(system_state);
        res
    }

    fun update_metadata(scenario: &mut Scenario, system_state: &mut SuiSystemState, name: vector<u8>, protocol_pub_key: vector<u8>, pop: vector<u8>, network_address: vector<u8>, p2p_address: vector<u8>) {
        let ctx = test_scenario::ctx(scenario);
        sui_system::update_validator_name(system_state, name, ctx);
        sui_system::update_validator_description(system_state, b"new_desc", ctx);
        sui_system::update_validator_image_url(system_state, b"new_image_url", ctx);
        sui_system::update_validator_project_url(system_state, b"new_project_url", ctx);
        sui_system::update_validator_next_epoch_network_address(system_state, network_address, ctx);
        sui_system::update_validator_next_epoch_p2p_address(system_state, p2p_address, ctx);
        sui_system::update_validator_next_epoch_consensus_address(system_state, x"8888", ctx);
        sui_system::update_validator_next_epoch_worker_address(system_state, x"9999", ctx);
        sui_system::update_validator_next_epoch_protocol_pubkey(
            system_state,
            protocol_pub_key,
            pop,
            ctx
        );
        sui_system::update_validator_next_epoch_worker_pubkey(system_state, x"00", ctx);
        sui_system::update_validator_next_epoch_network_pubkey(system_state, x"11", ctx);
    }

    fun verify_metadata(
        validator: &Validator,
        name: vector<u8>,
        protocol_pub_key: vector<u8>,
        pop: vector<u8>,
        network_address: vector<u8>,
        p2p_address: vector<u8>,
        new_protocol_pub_key: vector<u8>,
        new_pop: vector<u8>,
        new_network_address: vector<u8>,
        new_p2p_address: vector<u8>,
    ) {
        // Current epoch
        assert!(validator::name(validator) == &string::from_ascii(ascii::string(name)), 0);
        assert!(validator::description(validator) == &string::from_ascii(ascii::string(b"new_desc")), 0);
        assert!(validator::image_url(validator) == &url::new_unsafe_from_bytes(b"new_image_url"), 0);
        assert!(validator::project_url(validator) == &url::new_unsafe_from_bytes(b"new_project_url"), 0);
        assert!(validator::network_address(validator) == &network_address, 0);
        assert!(validator::p2p_address(validator) == &p2p_address, 0);
        assert!(validator::consensus_address(validator) == &x"FFFF", 0);
        assert!(validator::worker_address(validator) == &x"FFFF", 0);
        assert!(validator::protocol_pubkey_bytes(validator) == &protocol_pub_key, 0);
        assert!(validator::proof_of_possession(validator) == &pop, 0);
        assert!(validator::network_pubkey_bytes(validator) == &x"FF", 0);
        assert!(validator::worker_pubkey_bytes(validator) == &x"FF", 0);

        // Next epoch
        assert!(validator::next_epoch_network_address(validator) == &option::some(new_network_address), 0);
        assert!(validator::next_epoch_p2p_address(validator) == &option::some(new_p2p_address), 0);
        assert!(validator::next_epoch_consensus_address(validator) == &option::some(x"8888"), 0);
        assert!(validator::next_epoch_worker_address(validator) == &option::some(x"9999"), 0);
        assert!(
            validator::next_epoch_protocol_pubkey_bytes(validator) == &option::some(new_protocol_pub_key),
            0
        );
        assert!(
            validator::next_epoch_proof_of_possession(validator) == &option::some(new_pop),
            0
        );
        assert!(
            validator::next_epoch_worker_pubkey_bytes(validator) == &option::some(x"00"),
            0
        );
        assert!(
            validator::next_epoch_network_pubkey_bytes(validator) == &option::some(x"11"),
            0
        );
    }

    fun verify_metadata_after_advancing_epoch(
        validator: &Validator,
        name: vector<u8>,
        protocol_pub_key: vector<u8>,
        pop: vector<u8>,
        network_address: vector<u8>,
        p2p_address: vector<u8>,
    ) {
        // Current epoch
        assert!(validator::name(validator) == &string::from_ascii(ascii::string(name)), 0);
        assert!(validator::description(validator) == &string::from_ascii(ascii::string(b"new_desc")), 0);
        assert!(validator::image_url(validator) == &url::new_unsafe_from_bytes(b"new_image_url"), 0);
        assert!(validator::project_url(validator) == &url::new_unsafe_from_bytes(b"new_project_url"), 0);
        assert!(validator::network_address(validator) == &network_address, 0);
        assert!(validator::p2p_address(validator) == &p2p_address, 0);
        assert!(validator::consensus_address(validator) == &x"8888", 0);
        assert!(validator::worker_address(validator) == &x"9999", 0);
        assert!(validator::protocol_pubkey_bytes(validator) == &protocol_pub_key, 0);
        assert!(validator::proof_of_possession(validator) == &pop, 0);
        assert!(validator::worker_pubkey_bytes(validator) == &x"00", 0);
        assert!(validator::network_pubkey_bytes(validator) == &x"11", 0);

        // Next epoch
        assert!(option::is_none(validator::next_epoch_network_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_p2p_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_consensus_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_worker_address(validator)), 0);
        assert!(option::is_none(validator::next_epoch_protocol_pubkey_bytes(validator)), 0);
        assert!(option::is_none(validator::next_epoch_proof_of_possession(validator)), 0);
        assert!(option::is_none(validator::next_epoch_worker_pubkey_bytes(validator)), 0);
        assert!(option::is_none(validator::next_epoch_network_pubkey_bytes(validator)), 0);
    }

    #[test]
    fun test_active_validator_update_metadata() {
        let validator_addr = @0x8feebb589ffa14667ff721b7cfb186cfad6530fc;
        let scenario_val = test_scenario::begin(validator_addr);
        let scenario = &mut scenario_val;

        // Set up SuiSystemState with an active validator
        set_up_sui_system_state(vector[validator_addr], scenario);
        test_scenario::next_tx(scenario, validator_addr);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);

        // Test active validator metadata changes
        test_scenario::next_tx(scenario, validator_addr); 
        {
            update_metadata(
                scenario,
                &mut system_state,
                b"validator_new_name",
                vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105],
                vector[141, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3],
                x"DDDD",
                x"DDDD",
            );
        };

        test_scenario::next_tx(scenario, validator_addr);
        let validator = sui_system::active_validator_by_address(&system_state, validator_addr);
        verify_metadata(
            validator,
            b"validator_new_name",
            x"FF",
            x"FF",
            x"FFFF",
            x"FFFF",
            vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105],
            vector[141, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3],
            x"DDDD",
            x"DDDD",
        );

        test_scenario::return_shared(system_state);
        test_scenario::end(scenario_val);

        // Test pending validator metadata changes
        let new_validator_addr = @0xb019b5675640fbe5795c3c77c06acd097ebc13bb;
        let scenario_val = test_scenario::begin(new_validator_addr);
        let scenario = &mut scenario_val;
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        test_scenario::next_tx(scenario, new_validator_addr);
        {
            let ctx = test_scenario::ctx(scenario);
            sui_system::request_add_validator(
                &mut system_state,
                vector[149, 251, 227, 167, 111, 228, 241, 217, 164, 45, 2, 93, 198, 3, 10, 108, 4, 240, 5, 62, 142, 108, 208, 137, 217, 225, 96, 40, 228, 115, 148, 63, 85, 114, 241, 142, 252, 23, 24, 29, 183, 153, 120, 172, 56, 14, 123, 114, 6, 241, 0, 251, 216, 117, 224, 186, 248, 141, 37, 90, 131, 3, 144, 202, 184, 2, 113, 33, 149, 137, 25, 206, 5, 149, 233, 250, 222, 26, 214, 16, 111, 200, 179, 133, 85, 178, 245, 198, 77, 116, 22, 68, 3, 39, 43, 124],
                x"FF",
                x"FF",
                vector[144, 126, 49, 226, 178, 192, 48, 149, 38, 128, 247, 237, 42, 186, 192, 86, 232, 124, 48, 77, 142, 148, 154, 29, 14, 52, 177, 248, 132, 159, 63, 144, 143, 53, 190, 224, 19, 52, 109, 111, 251, 187, 42, 101, 146, 215, 27, 243],
                b"ValidatorName2",
                b"description2",
                b"image_url2",
                b"project_url2",
                x"AAAA",
                x"AAAA",
                x"FFFF",
                x"FFFF",
                coin::mint_for_testing(100, ctx),
                1,
                0,
                ctx,
            );
        };

        test_scenario::next_tx(scenario, new_validator_addr); 
        {
            update_metadata(
                scenario,
                &mut system_state,
                b"new_validator_new_name",
                vector[161, 57, 156, 108, 213, 236, 89, 156, 168, 125, 28, 14, 245, 197, 58, 6, 54, 147, 52, 137, 250, 4, 124, 175, 24, 199, 187, 42, 165, 161, 213, 0, 103, 188, 105, 8, 99, 80, 23, 152, 168, 150, 235, 4, 251, 65, 19, 206, 9, 206, 159, 67, 231, 221, 181, 69, 183, 56, 41, 228, 195, 253, 156, 225, 167, 252, 82, 115, 230, 61, 3, 210, 83, 58, 212, 20, 41, 46, 120, 89, 143, 240, 195, 10, 146, 112, 197, 188, 40, 122, 168, 208, 84, 24, 147, 160],
                vector[141, 39, 116, 152, 110, 247, 89, 132, 247, 174, 80, 80, 211, 230, 159, 107, 100, 126, 119, 229, 11, 138, 10, 193, 16, 118, 37, 135, 86, 128, 94, 79, 1, 60, 99, 249, 79, 33, 93, 233, 8, 126, 11, 85, 176, 123, 197, 108],
                x"EEEE",
                x"EEEE",
            );
        };

        test_scenario::next_tx(scenario, new_validator_addr);
        let validator = sui_system::pending_validator_by_address(&system_state, new_validator_addr);
        verify_metadata(
            validator,
            b"new_validator_new_name",
            vector[149, 251, 227, 167, 111, 228, 241, 217, 164, 45, 2, 93, 198, 3, 10, 108, 4, 240, 5, 62, 142, 108, 208, 137, 217, 225, 96, 40, 228, 115, 148, 63, 85, 114, 241, 142, 252, 23, 24, 29, 183, 153, 120, 172, 56, 14, 123, 114, 6, 241, 0, 251, 216, 117, 224, 186, 248, 141, 37, 90, 131, 3, 144, 202, 184, 2, 113, 33, 149, 137, 25, 206, 5, 149, 233, 250, 222, 26, 214, 16, 111, 200, 179, 133, 85, 178, 245, 198, 77, 116, 22, 68, 3, 39, 43, 124],
            vector[144, 126, 49, 226, 178, 192, 48, 149, 38, 128, 247, 237, 42, 186, 192, 86, 232, 124, 48, 77, 142, 148, 154, 29, 14, 52, 177, 248, 132, 159, 63, 144, 143, 53, 190, 224, 19, 52, 109, 111, 251, 187, 42, 101, 146, 215, 27, 243],
            x"AAAA",
            x"AAAA",
            vector[161, 57, 156, 108, 213, 236, 89, 156, 168, 125, 28, 14, 245, 197, 58, 6, 54, 147, 52, 137, 250, 4, 124, 175, 24, 199, 187, 42, 165, 161, 213, 0, 103, 188, 105, 8, 99, 80, 23, 152, 168, 150, 235, 4, 251, 65, 19, 206, 9, 206, 159, 67, 231, 221, 181, 69, 183, 56, 41, 228, 195, 253, 156, 225, 167, 252, 82, 115, 230, 61, 3, 210, 83, 58, 212, 20, 41, 46, 120, 89, 143, 240, 195, 10, 146, 112, 197, 188, 40, 122, 168, 208, 84, 24, 147, 160],
            vector[141, 39, 116, 152, 110, 247, 89, 132, 247, 174, 80, 80, 211, 230, 159, 107, 100, 126, 119, 229, 11, 138, 10, 193, 16, 118, 37, 135, 86, 128, 94, 79, 1, 60, 99, 249, 79, 33, 93, 233, 8, 126, 11, 85, 176, 123, 197, 108],
            x"EEEE",
            x"EEEE",
        );

        test_scenario::return_shared(system_state);

        // Advance epoch to effectuate the metadata changes.
        test_scenario::next_tx(scenario, new_validator_addr);
        advance_epoch(scenario);

        // Now both validators are active, verify their metadata.
        test_scenario::next_tx(scenario, new_validator_addr);
        let system_state = test_scenario::take_shared<SuiSystemState>(scenario);
        let validator = sui_system::active_validator_by_address(&system_state, validator_addr);
        verify_metadata_after_advancing_epoch(
            validator,
            b"validator_new_name",
            vector[128, 66, 3, 168, 165, 211, 149, 2, 72, 28, 144, 54, 135, 81, 114, 114, 244, 7, 1, 16, 148, 211, 223, 27, 47, 235, 209, 94, 184, 197, 218, 217, 160, 175, 123, 79, 166, 132, 43, 220, 28, 158, 186, 19, 135, 53, 255, 33, 25, 133, 14, 237, 99, 54, 47, 141, 171, 104, 109, 191, 207, 96, 167, 194, 129, 67, 112, 11, 132, 116, 217, 163, 204, 3, 94, 71, 182, 222, 11, 204, 101, 76, 76, 18, 133, 231, 54, 20, 167, 50, 113, 131, 240, 158, 47, 105],
            vector[141, 105, 159, 105, 236, 237, 114, 186, 36, 14, 245, 66, 203, 132, 92, 175, 139, 247, 226, 152, 234, 163, 184, 82, 12, 142, 113, 167, 185, 116, 90, 126, 169, 90, 58, 253, 210, 1, 148, 137, 164, 224, 231, 95, 252, 33, 171, 3],
            x"DDDD",
            x"DDDD",
        );

        let validator = sui_system::active_validator_by_address(&system_state, new_validator_addr);
        verify_metadata_after_advancing_epoch(
            validator,
            b"new_validator_new_name",
            vector[161, 57, 156, 108, 213, 236, 89, 156, 168, 125, 28, 14, 245, 197, 58, 6, 54, 147, 52, 137, 250, 4, 124, 175, 24, 199, 187, 42, 165, 161, 213, 0, 103, 188, 105, 8, 99, 80, 23, 152, 168, 150, 235, 4, 251, 65, 19, 206, 9, 206, 159, 67, 231, 221, 181, 69, 183, 56, 41, 228, 195, 253, 156, 225, 167, 252, 82, 115, 230, 61, 3, 210, 83, 58, 212, 20, 41, 46, 120, 89, 143, 240, 195, 10, 146, 112, 197, 188, 40, 122, 168, 208, 84, 24, 147, 160],
            vector[141, 39, 116, 152, 110, 247, 89, 132, 247, 174, 80, 80, 211, 230, 159, 107, 100, 126, 119, 229, 11, 138, 10, 193, 16, 118, 37, 135, 86, 128, 94, 79, 1, 60, 99, 249, 79, 33, 93, 233, 8, 126, 11, 85, 176, 123, 197, 108],
            x"EEEE",
            x"EEEE",
        );

        test_scenario::return_shared(system_state);
        test_scenario::end(scenario_val);
    }
}
