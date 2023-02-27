// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { bcs as suiBcs } from '@mysten/sui.js';
import { useQuery } from '@tanstack/react-query';

import { TxTimeType } from '~/components/tx-time/TxTimeType';
import { useRpc } from '~/hooks/useRpc';
import { Heading } from '~/ui/Heading';
import { Text } from '~/ui/Text';

export const SYSTEM_EPOCH_INFO = '0x2::sui_system::SystemEpochInfo';

suiBcs.registerStructType(SYSTEM_EPOCH_INFO, {
    epoch: 'u64',
    referenceGasPrice: 'u64',
    totalStake: 'u64',
    storageFundInflows: 'u64',
    storageFundOutflows: 'u64',
    storageFundBalance: 'u64',
    stakeSubsidyAmount: 'u64',
    totalGasFees: 'u64',
    totalStakeRewards: 'u64',
});

export default function Epochs() {
    const rpc = useRpc();

    const { data, isLoading } = useQuery(
        ['epoch-checkpoint-info'],
        async () => {
            // get epoch info
            const { data } = await rpc.getEvents(
                { MoveEvent: SYSTEM_EPOCH_INFO },
                null,
                100,
                'descending'
            );

            const [evt] = data;
            const { event }: any = evt;
            const {
                moveEvent: { bcs },
            } = event;

            // todo: confirm this logic
            const epochInfo = suiBcs.de(SYSTEM_EPOCH_INFO, bcs, 'base64');

            // get latest checkpoint sequence number
            const latestCheckpoint =
                await rpc.getLatestCheckpointSequenceNumber();

            // get info on latest checkpoint
            const checkpointInfo = await rpc.getCheckpointSummary(
                latestCheckpoint!
            );

            // get contents of checkpoint
            const contents = await rpc.getCheckpointContents(
                checkpointInfo.content_digest!
            );

            // these should be of equal length unless genesis or latest checkpoint
            const txCount = contents.transactions.length;
            const userSigCount = contents.user_signatures.length;

            return {
                epochInfo,
                txCount,
                userSigCount,
                latestCheckpointSequenceNumber: latestCheckpoint,
                checkpointInfo,
                checkpointContents: contents,
            };
        }
    );

    if (isLoading) return <div>loading...</div>;

    return (
        <div className="flex flex-col">
            <pre>
                {JSON.stringify(
                    data,
                    (kev, value) =>
                        typeof value === 'bigint' ? value.toString() : value,
                    2
                )}
            </pre>
            <div className="mx-auto flex flex-col space-y-8">
                <Heading variant="heading6/medium">Epoch Info</Heading>
                <div className="flex flex-col">
                    Current Epoch:
                    <Text variant="body/medium">
                        {data?.epochInfo.epoch.toString()}
                    </Text>
                    Reference Gas Price:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.referenceGasPrice.toString()}
                    </Text>
                    Total Stake:
                    <Text variant="body/medium">
                        {data?.epochInfo.totalStake.toString()}
                    </Text>
                    Storage Fund Inflows:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.storageFundInflows.toString()}
                    </Text>
                    Storage Fund Outflows:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.storageFundInflows.toString()}
                    </Text>
                    Storage Fund Balance:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.storageFundBalance.toString()}
                    </Text>
                    Storage Subsidy Amount:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.stakeSubsidyAmount.toString()}
                    </Text>
                    Total Gas Fees:
                    <Text variant="body/medium">
                        {data?.epochInfo.totalGasFees.toString()}
                    </Text>
                    Total Stake Rewards:{' '}
                    <Text variant="body/medium">
                        {data?.epochInfo.totalStakeRewards.toString()}
                    </Text>
                </div>
                <Heading variant="heading6/medium">Checkpoint Info</Heading>
                <div className="flex flex-col">
                    Latest Checkpoint Sequence Number:{' '}
                    <Text variant="body/medium">
                        {data?.latestCheckpointSequenceNumber}
                    </Text>
                    Transactions in Checkpoint:
                    <Text variant="body/medium">{data?.txCount}</Text>
                    Time:{' '}
                    <Text variant="body/medium">
                        <TxTimeType
                            timestamp={data?.checkpointInfo.timestamp_ms!}
                        />
                    </Text>
                </div>
            </div>
        </div>
    );
}
