// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { type ReactNode } from 'react';

import { Card } from '~/ui/Card';
import { Heading } from '~/ui/Heading';

export interface EpochActivityProps {
    epoch?: string;
    start: number;
    end: number;
    inProgress?: boolean;
}

export function EpochStats({
    label,
    children,
}: {
    label: string;
    children: ReactNode;
}) {
    return (
        <Card spacing="lg">
            <div className="flex flex-col space-y-8">
                <Heading color="steel-darker" variant="heading4/semibold">
                    {label}
                </Heading>
                {/* todo: get tooltip content, can we re-use metrics components from home */}
                <div className="grid grid-cols-2 gap-6">{children}</div>
            </div>
        </Card>
    );
}
