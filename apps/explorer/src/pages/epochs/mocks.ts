// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// todo: remove this
import { faker } from '@faker-js/faker';

export type Epoch = {
    epoch: number;
    validators: any;
    transactionCount: number;
    checkpointSet: [number, number];
    startTimestamp: number;
    endTimestamp: number;
    storageSize: number;
    totalRewards: number;
    stakeSubsidies: number;
    storageFundEarnings: number;
    gasCostSummary?: {
        gasRevenue: number;
        totalRevenue: number;
        storageRevenue: number;
        stakeRewards: number;
    };
};

export const getEpoch = async (): Promise<Epoch> => ({
    epoch: +faker.random.numeric(1),
    validators: [],
    transactionCount: +faker.random.numeric(7),
    checkpointSet: [+faker.random.numeric(5), +faker.random.numeric(5)],
    startTimestamp: faker.date.recent().getTime(),
    endTimestamp: faker.date.soon().getTime(),
    storageSize: +faker.random.numeric(6) / 1000,
    totalRewards: +faker.random.numeric(11),
    stakeSubsidies: +faker.random.numeric(11),
    storageFundEarnings: +faker.random.numeric(11),
    gasCostSummary: {
        gasRevenue: +faker.random.numeric(11),
        totalRevenue: +faker.random.numeric(11),
        storageRevenue: +faker.random.numeric(11),
        stakeRewards: +faker.random.numeric(11),
    },
});

export const getCurrentEpoch = async (): Promise<Partial<Epoch>> => ({
    epoch: 5,
    validators: [],
    transactionCount: 4803777,
    checkpointSet: [55159, 29804],
    startTimestamp: faker.date.recent().getTime(),
    endTimestamp: faker.date.soon().getTime(),
});

export const getEpochs = async () =>
    Promise.all(Array.from({ length: 20 }).map(getEpoch));

// getCheckpoints()
export const getCheckpoints = async () =>
    await Promise.all(Array.from({ length: 20 }).map(getCheckpoint));

// getCheckpoint()
export const getCheckpoint = async () => ({
    epoch: faker.random.numeric(2),
    timestampMs: faker.date.recent().getTime(),
    sequence_number: faker.random.numeric(5),
    network_total_transactions: faker.random.numeric(7),
    content_digest: faker.git.commitSha(),
    signature: faker.git.commitSha(),
    previous_digest: faker.git.commitSha(),
    epoch_rolling_gas_cost_summary: {
        computation_cost: faker.datatype.number(),
        storage_cost: faker.datatype.number(),
        storage_rebate: faker.datatype.number(),
    },
    transaction_count: faker.random.numeric(7),
    transactions: [],
});
