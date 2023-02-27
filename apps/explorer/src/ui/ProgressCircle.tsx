// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { motion } from 'framer-motion';

export function ProgressCircle({ progress }: { progress: number }) {
    return (
        <motion.svg className="rotate-90" viewBox="0 0 16 16">
            <motion.circle
                fill="none"
                cx="8"
                cy="8"
                r="5"
                strokeLinecap={progress === 100 ? 'butt' : 'round'}
                strokeWidth={1.5}
                stroke="currentColor"
                animate={{
                    pathLength: progress === 100 ? 1.5 : progress / 100,
                    type: 'spring',
                    transition: { duration: 1 },
                }}
            />
        </motion.svg>
    );
}
