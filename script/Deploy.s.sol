// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {Deployer} from "../src/Deployer.sol";
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";
import {IRewardsCoordinator} from "eigenlayer-contracts/src/contracts/interfaces/IRewardsCoordinator.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IPermissionController} from "eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {console} from "forge-std/console.sol";
import {DeployParams} from "../src/Deployer.sol";

contract Deploy is Deployer, Script {
    // Eigenlayer Core Contracts
    IDelegationManager public _delegationManager;
    IAVSDirectory public _avsDirectory;
    IRewardsCoordinator public _rewardsCoordinator;
    IAllocationManager public _allocationManager;
    IPermissionController public _permissionController;

    // Roles
    address public owner;
    address public rewardsInitiator;
    address public churnApprover;

    // Deployed middleware contracts
    address public serviceManagerProxy;
    address public slashingRegistryCoordinatorProxy;

    // Parameters
    string public metadataURI;
    uint256 public lookaheadPeriod;

    function _parseConfig() internal {
        string memory config = vm.readFile("script/config.json");

        // Parse contract addresses
        _delegationManager = IDelegationManager(
            stdJson.readAddress(config, "$.contracts.delegationManager")
        );
        _avsDirectory = IAVSDirectory(
            stdJson.readAddress(config, "$.contracts.avsDirectory")
        );
        _rewardsCoordinator = IRewardsCoordinator(
            stdJson.readAddress(config, "$.contracts.rewardCoordinator")
        );
        _allocationManager = IAllocationManager(
            stdJson.readAddress(config, "$.contracts.allocationManager")
        );
        _permissionController = IPermissionController(
            stdJson.readAddress(config, "$.contracts.permissionController")
        );

        // Parse roles
        owner = stdJson.readAddress(config, "$.roles.owner");
        rewardsInitiator = stdJson.readAddress(
            config,
            "$.roles.rewardsInitiator"
        );
        churnApprover = stdJson.readAddress(config, "$.roles.churnApprover");

        // Parse parameters
        metadataURI = stdJson.readString(config, "$.parameters.metadataURI");
        lookaheadPeriod = stdJson.readUint(
            config,
            "$.parameters.lookaheadPeriod"
        );
    }

    // Print config
    function _printConfig() internal {
        console.log("Contracts:");
        console.log("Delegation Manager:", address(_delegationManager));
        console.log("AVS Directory:", address(_avsDirectory));
        console.log("Rewards Coordinator:", address(_rewardsCoordinator));
        console.log("Allocation Manager:", address(_allocationManager));
        console.log("Permission Controller:", address(_permissionController));

        console.log("Roles:");
        console.log("Owner:", owner);
        console.log("Rewards Initiator:", rewardsInitiator);
        console.log("Churn Approver:", churnApprover);

        console.log("Parameters:");
        console.log("Metadata URI:", metadataURI);
        console.log("Lookahead Period:", lookaheadPeriod);
    }

    function _deploy() internal {
        DeployParams memory params = DeployParams({
            delegationManager: _delegationManager,
            avsDirectory: _avsDirectory,
            rewardsCoordinator: _rewardsCoordinator,
            allocationManager: _allocationManager,
            permissionController: _permissionController,
            initialOwner: owner,
            rewardsInitiator: rewardsInitiator,
            churnApprover: churnApprover,
            metadataURI: metadataURI,
            deployer: msg.sender,
            lookaheadPeriod: lookaheadPeriod
        });

        (
            address indexRegistryProxy,
            address stakeRegistryProxy,
            address apkRegistryProxy,
            address _slashingRegistryCoordinatorProxy,
            address _serviceManagerProxy,
            ProxyAdmin proxyAdmin,
            address tracer
        ) = _create(params);
        
        slashingRegistryCoordinatorProxy = _slashingRegistryCoordinatorProxy;
        serviceManagerProxy = _serviceManagerProxy;

    }


    function run() public {
        _parseConfig();
        _printConfig();
    }
}
