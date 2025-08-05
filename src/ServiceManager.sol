// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {ServiceManagerBase, ISlashingRegistryCoordinator} from "@eigenlayer-middleware/src/ServiceManagerBase.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";
import {IRewardsCoordinator} from "eigenlayer-contracts/src/contracts/interfaces/IRewardsCoordinator.sol";
import {IPermissionController} from "eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {IAVSRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IAVSRegistrar.sol";
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

    function initialize(
        address initialOwner_,
        address rewardsInitiator_,
        string calldata metadataURI_
    ) external initializer {
        __ServiceManagerBase_init(initialOwner_, rewardsInitiator_);

        _allocationManager.updateAVSMetadataURI(address(this), metadataURI_);
        _allocationManager.setAVSRegistrar(address(this), IAVSRegistrar(address(_registryCoordinator)));
        _permissionController.addPendingAdmin(address(this), initialOwner_);
        _permissionController.setAppointee({
            account: address(this),
            appointee: address(_registryCoordinator),
            target: address(_allocationManager),
            selector: _allocationManager.createOperatorSets.selector
        });
        _permissionController.setAppointee({
            account: address(this),
            appointee: address(this),
            target: address(_allocationManager),
            selector: _allocationManager.deregisterFromOperatorSets.selector
        });
        _permissionController.setAppointee({
            account: address(this),
            appointee: address(this),
            target: address(_allocationManager),
            selector: _allocationManager.slashOperator.selector
        });
    }
}
