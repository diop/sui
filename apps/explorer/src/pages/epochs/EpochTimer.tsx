// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { useQuery } from '@tanstack/react-query';

import { getCurrentEpoch } from './mocks';
import { useEpochProgress } from './useEpochProgress';

import { ProgressCircle } from '~/ui/ProgressCircle';
import { Text } from '~/ui/Text';

export function EpochTimer() {
    const { data: currentEpoch } = useQuery(
        ['epoch', 'current'],
        async () => await getCurrentEpoch()
    );
    const { progress, label } = useEpochProgress(
        currentEpoch?.startTimestamp,
        currentEpoch?.endTimestamp
    );

    return (
        <div className="flex w-fit items-center gap-1.5 rounded-lg border border-gray-45 py-2 px-2.5 shadow-notification">
            <div className="w-5 text-steel-darker">
                <ProgressCircle progress={progress} />
            </div>
            <Text variant="p2/medium" color="steel-darker">
                Epoch {currentEpoch?.epoch} in progress. {label}
            </Text>
        </div>
    );
}
