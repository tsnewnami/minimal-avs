// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {SlashingRegistryCoordinator, IPauserRegistry, IAllocationManager, ISocketRegistry, IIndexRegistry, IBLSApkRegistry, IStakeRegistry} from "@eigenlayer-middleware/src/SlashingRegistryCoordinator.sol";

contract MinimalRegistryCoordinator is SlashingRegistryCoordinator {
    constructor(
        IStakeRegistry _stakeRegistry,
        IBLSApkRegistry _blsApkRegistry,
        IIndexRegistry _indexRegistry,
        ISocketRegistry _socketRegistry,
        IAllocationManager _allocationManager,
        IPauserRegistry _pauserRegistry
    )
        SlashingRegistryCoordinator(
            _stakeRegistry,
            _blsApkRegistry,
            _indexRegistry,
            _socketRegistry,
            _allocationManager,
            _pauserRegistry,
            "0.0.1"
        )
    {
        _disableInitializers();
    }
}
