// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {ServiceManagerBase, ISlashingRegistryCoordinator} from "@eigenlayer-middleware/src/ServiceManagerBase.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";
import {IRewardsCoordinator} from "eigenlayer-contracts/src/contracts/interfaces/IRewardsCoordinator.sol";
import {IPermissionController} from "eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {IAVSRegistrar} from "@eigenlayer/contracts/interfaces/IAVSRegistrar.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IStakeRegistry} from "@eigenlayer-middleware/src/interfaces/IStakeRegistry.sol";

struct ServiceManagerConstructorParams {
    IAVSDirectory avsDirectory;
    IRewardsCoordinator rewardsCoordinator;
    IPermissionController permissionController;
    IAllocationManager allocationManager;
    ISlashingRegistryCoordinator slashingRegistryCoordinator;
    IStakeRegistry stakeRegistry;
}

/**
 * @title ServiceManager
 */
contract ServiceManager is ServiceManagerBase {
    constructor(
        ServiceManagerConstructorParams memory params
    )
        ServiceManagerBase(
            params.avsDirectory,
            params.rewardsCoordinator,
            params.slashingRegistryCoordinator,
            params.stakeRegistry,
            params.permissionController,
            params.allocationManager
        )
    {
        _disableInitializers();
    }
}
