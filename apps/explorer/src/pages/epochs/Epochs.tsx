// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { useFeature, useGrowthBook } from '@growthbook/growthbook-react';
import { useQuery } from '@tanstack/react-query';
import { useMemo } from 'react';
import { Navigate } from 'react-router-dom';

import { EpochTimer } from './EpochTimer';
import { getEpochs } from './mocks';

import { SuiAmount } from '~/components/transaction-card/TxCardUtils';
import { TxTimeType } from '~/components/tx-time/TxTimeType';
import { LoadingSpinner } from '~/ui/LoadingSpinner';
import { PlaceholderTable } from '~/ui/PlaceholderTable';
import { TableCard } from '~/ui/TableCard';
import { Tab, TabGroup, TabList, TabPanel, TabPanels } from '~/ui/Tabs';
import { GROWTHBOOK_FEATURES } from '~/utils/growthbook';

function Epochs() {
    const enabled = useFeature(GROWTHBOOK_FEATURES.EPOCHS_CHECKPOINTS).on;
    // todo: replace this call with an rpc call to `sui_getEpochs`
    // when it is implemented
    const { data: epochs } = useQuery(
        ['epochs'],
        async () => await getEpochs()
    );

    const tableData = useMemo(
        () =>
            epochs
                ? {
                      data: epochs?.map((epoch: any) => ({
                          time: <TxTimeType timestamp={epoch.timestamp} />,
                          epoch: epoch.epoch,
                          transactions: epoch.transaction_count,
                          stakeRewards: (
                              <SuiAmount amount={epoch.total_stake_rewards} />
                          ),
                          checkpointSet: epoch.checkpoint_set?.join(' - '),
                          storageRevenue: (
                              <SuiAmount
                                  amount={
                                      BigInt(epoch.storage_fund_inflows ?? 0) -
                                      BigInt(epoch.storage_fund_outflows ?? 0)
                                  }
                              />
                          ),
                      })),
                      columns: [
                          { header: 'Time', accessorKey: 'time' },
                          { header: 'Epoch', accessorKey: 'epoch' },
                          {
                              header: 'Transactions',
                              accessorKey: 'transactions',
                          },
                          {
                              header: 'Checkpoint Set',
                              accessorKey: 'checkpointSet',
                          },
                          {
                              header: 'Stake Rewards',
                              accessorKey: 'stakeRewards',
                          },
                          {
                              header: 'Storage Revenue',
                              accessorKey: 'storageRevenue',
                          },
                      ],
                  }
                : null,
        [epochs]
    );

    if (!enabled) return <Navigate to="/" />;

    return (
        <div>
            <TabGroup size="lg">
                <TabList>
                    <Tab>Epochs</Tab>
                </TabList>
                <TabPanels>
                    <TabPanel>
                        <div className="flex flex-col items-center justify-center gap-6">
                            <EpochTimer />
                            {/* todo: add pagination */}
                            {tableData ? (
                                <TableCard
                                    data={tableData.data}
                                    columns={tableData.columns}
                                />
                            ) : (
                                <PlaceholderTable
                                    rowCount={20}
                                    rowHeight="13px"
                                    colHeadings={['time', 'number']}
                                    colWidths={['50%', '50%']}
                                />
                            )}
                        </div>
                    </TabPanel>
                </TabPanels>
            </TabGroup>
        </div>
    );
}

export default () => {
    const gb = useGrowthBook();
    if (gb?.ready) {
        return <Epochs />;
    } else {
        return <LoadingSpinner />;
    }
};
