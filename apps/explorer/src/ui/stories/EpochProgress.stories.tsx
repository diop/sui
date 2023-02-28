// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { type Meta, type StoryObj } from '@storybook/react';

import {
    EpochProgress,
    type EpochProgressProps,
} from '../../pages/epochs/stats/Progress';

export default {
    component: EpochProgress,
} as Meta;

export const InProgress: StoryObj<EpochProgressProps> = {
    name: 'In Progress',
    args: {
        epoch: 5,
        start: new Date().setHours(new Date().getHours() - 3),
        end: new Date().setHours(new Date().getHours() + 2),
    },
    render: (args) => (
        <div className="flex h-[216px]">
            <EpochProgress {...args} />
        </div>
    ),
};

export const Default: StoryObj<EpochProgressProps> = {
    args: {
        epoch: 16,
        start: new Date().setHours(new Date().getHours() - 3),
        end: new Date().setHours(new Date().getHours() + 2),
    },
    render: (args) => (
        <div className="flex h-[216px]">
            <EpochProgress {...args} />
        </div>
    ),
};
