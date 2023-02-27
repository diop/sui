// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { useFeature, useGrowthBook } from '@growthbook/growthbook-react';
import { useQuery } from '@tanstack/react-query';
import { Navigate, useParams } from 'react-router-dom';

import { getEpoch } from './mocks';
import { EpochStats } from './stats/Activity';
import { useCheckpointsTable } from './useCheckpointsTable';

import { StatsWrapper } from '~/components/HomeMetrics';
import { SuiAmount } from '~/components/transaction-card/TxCardUtils';
import { EpochProgress } from '~/pages/epochs/stats/Progress';
import { LoadingSpinner } from '~/ui/LoadingSpinner';
import { TableCard } from '~/ui/TableCard';
import { Tab, TabGroup, TabList, TabPanels } from '~/ui/Tabs';
import { GROWTHBOOK_FEATURES } from '~/utils/growthbook';

function EpochDetail() {
    const enabled = useFeature(GROWTHBOOK_FEATURES.EPOCHS_CHECKPOINTS).on;
    const { epoch } = useParams<{ epoch: string }>();
    const { data: epochData, isLoading } = useQuery(
        ['epoch', epoch],
        async () => await getEpoch(epoch!)
    );

    const { data: checkpointsTable } = useCheckpointsTable(epoch!);

    if (isLoading) return <LoadingSpinner />;
    if (!enabled) return <Navigate to="/" />;
    if (!epochData) return null;

    return (
        <div className="flex flex-col space-y-16">
            <div className="flex gap-6">
                <EpochProgress
                    epoch={epochData.epoch}
                    start={epochData.startTimestamp}
                    end={epochData.endTimestamp}
                />
                <EpochStats label="Activity">
                    <StatsWrapper label="Storage Size" tooltip="Storage Size">
                        {`${epochData.storageSize.toFixed(2)} GB`}
                    </StatsWrapper>
                    <StatsWrapper label="Gas Revenue" tooltip="Gas Revenue">
                        <SuiAmount
                            amount={epochData.gasCostSummary?.gasRevenue}
                        />
                    </StatsWrapper>
                    <StatsWrapper
                        label="Storage Revenue"
                        tooltip="Storage Revenue"
                    >
                        <SuiAmount
                            amount={epochData.gasCostSummary?.storageRevenue}
                        />
                    </StatsWrapper>
                    <StatsWrapper label="Stake Rewards" tooltip="Stake Rewards">
                        <SuiAmount
                            amount={epochData.gasCostSummary?.stakeRewards}
                        />
                    </StatsWrapper>
                </EpochStats>
                <EpochStats label="Rewards">
                    <StatsWrapper label="Total Rewards" tooltip="Total Rewards">
                        <SuiAmount amount={epochData.totalRewards} />
                    </StatsWrapper>
                    <StatsWrapper
                        label="Stake Subsidies"
                        tooltip="Stake Subsidies"
                    >
                        <SuiAmount amount={epochData.stakeSubsidies} />
                    </StatsWrapper>
                    <StatsWrapper
                        label="Storage Fund Earnings"
                        tooltip="Storage Fund Earnings"
                    >
                        <SuiAmount amount={epochData.storageFundEarnings} />
                    </StatsWrapper>
                </EpochStats>
            </div>
            <div>
                <TabGroup size="lg">
                    <TabList>
                        <Tab>Checkpoints</Tab>
                    </TabList>
                    <TabPanels className="mt-4">
                        {checkpointsTable ? (
                            <TableCard
                                data={checkpointsTable?.data}
                                columns={checkpointsTable?.columns}
                            />
                        ) : null}
                    </TabPanels>
                </TabGroup>
            </div>
        </div>
    );
}

export default () => {
    const gb = useGrowthBook();
    if (gb?.ready) {
        return <EpochDetail />;
    }
    return <LoadingSpinner />;
};
