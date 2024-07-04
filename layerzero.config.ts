import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const polygonContract: OmniPointHardhat = {
    eid: EndpointId.POLYGON_V2_MAINNET,
    contractName: 'ptpt_adapter_polygon',
}

const zksyncContract: OmniPointHardhat = {
    eid: EndpointId.ZKSYNC_V2_MAINNET,
    contractName: 'ptless_zks',
}

const baseContract: OmniPointHardhat = {
    eid: EndpointId.BASE_V2_MAINNET,
    contractName: 'ptpt_base',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: polygonContract,
        },
        {
            contract: baseContract,
        },
    ],
    connections: [
        {
            from: polygonContract,
            to: baseContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 200000,
                        value: 0,
                    },
                ],
            },
        },
        {
            from: baseContract,
            to: polygonContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 200000,
                        value: 0,
                    },
                ],
            },
        }
    ],
}

export default config
