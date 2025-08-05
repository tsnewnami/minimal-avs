// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IndexRegistry} from "@eigenlayer-middleware/src/IndexRegistry.sol";
import {StakeRegistry} from "@eigenlayer-middleware/src/StakeRegistry.sol";
import {BLSApkRegistry} from "@eigenlayer-middleware/src/BLSApkRegistry.sol";
import {
    RegistryCoordinator,
    IBLSApkRegistry,
    IIndexRegistry,
    ISocketRegistry
} from "@eigenlayer-middleware/src/RegistryCoordinator.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IRewardsCoordinator} from "eigenlayer-contracts/src/contracts/interfaces/IRewardsCoordinator.sol";
import {IPermissionController} from "eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {MinimalRegistryCoordinator} from "./MinimalRegistryCoordinator.sol";

contract Empty{}

struct DeployParams {
    IDelegationManager delegationManager;
    IAVSDirectory avsDirectory;
    IRewardsCoordinator rewardsCoordinator;
    IAllocationManager allocationManager;
    IPermissionController permissionController;
    address initialOwner;
    address rewardsInitiator;
    address churnApprover;
    address ejector;
    address deployer;
    string metadataURI;
}

contract Deployer {
    function _create(DeployParams memory params)
        internal
        returns (
            address indexRegistryProxy,
            address stakeRegistryProxy,
            address apkRegistryProxy,
            address slashingRegistryCoordinatorProxy,
            address serviceManagerProxy,
            address proxyAdmin,
            address tracer
        )
    {
        address emptyContract = address(new EmptyContract());

        address[] memory pausers = new address[](1);
        pausers[0] = params.initialOwner;

        IPauserRegistry pauserRegistry = IPauserRegistry(new PauserRegistry(pausers, params.initialOwner));

        // Deploy proxies for each contract
        indexRegistryProxy = address(new TransparentUpgradeableProxy(emptyContract, address(proxyAdmin), ""));
        stakeRegistryProxy = address(new TransparentUpgradeableProxy(emptyContract, address(proxyAdmin), ""));
        apkRegistryProxy = address(new TransparentUpgradeableProxy(emptyContract, address(proxyAdmin), ""));
        slashingRegistryCoordinatorProxy =
            address(new TransparentUpgradeableProxy(emptyContract, address(proxyAdmin), ""));
        serviceManagerProxy = address(new TransparentUpgradeableProxy(emptyContract, address(proxyAdmin), ""));
        SocketRegistry socketRegistry = new SocketRegistry(IRegistryCoordinator(slashingRegistryCoordinatorProxy));

        bytes memory slashingRegistryCoordinatorInit = abi.encodeWithSelector(
            SlashingRegistryCoordinator.initialize.selector,
            params.deployer,
            params.churnApprover,
            params.ejector,
            0,
            serviceManagerProxy
        );

        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(payable(address(indexRegistryProxy))),
            address(new IndexRegistry(ISlashingRegistryCoordinator(slashingRegistryCoordinatorProxy)))
        );

        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(payable(stakeRegistryProxy)),
            address(
                new StakeRegistry(
                    ISlashingRegistryCoordinator(slashingRegistryCoordinatorProxy),
                    params.delegationManager,
                    params.avsDirectory,
                    params.allocationManager
                )
            )
        );

        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(payable(apkRegistryProxy)),
            address(new BLSApkRegistry(ISlashingRegistryCoordinator(slashingRegistryCoordinatorProxy)))
        );

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(slashingRegistryCoordinatorProxy)),
            address(
                new MinimalRegistryCoordinator(
                    IStakeRegistry(stakeRegistryProxy),
                    IBLSApkRegistry(apkRegistryProxy),
                    IIndexRegistry(indexRegistryProxy),
                    ISocketRegistry(socketRegistry),
                    IAllocationManager(params.allocationManager),
                    IPauserRegistry(pauserRegistry)
                )
            ),
            slashingRegistryCoordinatorInit
        );

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(serviceManagerProxy)),
            address(
                new ServiceManager(
                    ServiceManagerConstructorParams({
                        avsDirectory: params.avsDirectory,
                        rewardsCoordinator: params.rewardsCoordinator,
                        permissionController: params.permissionController,
                        allocationManager: params.allocationManager,
                        slashingRegistryCoordinator: ISlashingRegistryCoordinator(slashingRegistryCoordinatorProxy),
                        stakeRegistry: IStakeRegistry(stakeRegistryProxy)
                    })
                )
            ),
            abi.encodeWithSelector(
                ServiceManager.initialize.selector,
                params.deployer,
                params.rewardsInitiator,
                params.metadataURI
            )
        );

        return (
            indexRegistryProxy,
            stakeRegistryProxy,
            apkRegistryProxy,
            slashingRegistryCoordinatorProxy,
            serviceManagerProxy,
            proxyAdmin,
            address(0x0)
        );
    }
}