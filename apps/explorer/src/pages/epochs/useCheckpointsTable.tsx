// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useQuery } from '@tanstack/react-query';

import { getCheckpoints } from './mocks';

import { Text } from '~/ui/Text';

export function useCheckpointsTable(epoch: string) {
    const { data: checkpointsTable } = useQuery(
        ['checkpoints', epoch],
        async () => {
            const checkpoints = await getCheckpoints();

            return {
                data: checkpoints.map((checkpoint) => ({
                    time: (
                        <Text variant="bodySmall/medium">
                            {checkpoint.timestampMs}
                        </Text>
                    ),
                    sequenceNumber: (
                        <Text variant="bodySmall/medium">
                            {checkpoint.sequence_number}
                        </Text>
                    ),
                    transactionCount: (
                        <Text variant="bodySmall/medium">
                            {checkpoint.transaction_count}
                        </Text>
                    ),
                    digest: (
                        <Text variant="bodySmall/medium">
                            {checkpoint.content_digest}
                        </Text>
                    ),
                    signature: (
                        <Text variant="bodySmall/medium">
                            {checkpoint.signature}
                        </Text>
                    ),
                })),
                columns: [
                    {
                        header: 'Time',
                        accessorKey: 'time',
                    },
                    {
                        header: 'Sequence Number',
                        accessorKey: 'sequenceNumber',
                    },
                    {
                        header: 'Transaction Count',
                        accessorKey: 'transactionCount',
                    },
                    {
                        header: 'Digest',
                        accessorKey: 'digest',
                    },
                    {
                        header: 'Signature',
                        accessorKey: 'signature',
                    },
                ],
            };
        }
    );
    return { data: checkpointsTable };
}
