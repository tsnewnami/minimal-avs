// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {IAllocationManager, IAllocationManagerTypes} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {console} from "forge-std/console.sol";
import {MinimalAVSRegistrar} from "../src/MinimalAVSRegistrar.sol";
import {IAVSRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IAVSRegistrar.sol";
import {IStrategy} from "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";

contract Deploy is Script {
    // Eigenlayer Core Contracts
    IAllocationManager public ALLOCATION_MANAGER =
        IAllocationManager(0x42583067658071247ec8CE0A516A58f682002d07);
    IKeyRegistrar public KEY_REGISTRAR =
        IKeyRegistrar(0xA4dB30D08d8bbcA00D40600bee9F029984dB162a);

    // EigenLayer Strategies
    IStrategy public STRATEGY_WETH =
        IStrategy(0x424246eF71b01ee33aA33aC590fd9a0855F5eFbc);

    IAVSRegistrar public avsRegistrar;

    function _deployContracts(
        uint256 deployerPrivateKey,
        address avs
    ) internal {
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed to:", address(proxyAdmin));

        // Deploy MinimalAVSRegistrar
        MinimalAVSRegistrar minimalAVSRegistrar = new MinimalAVSRegistrar(
            avs,
            ALLOCATION_MANAGER,
            KEY_REGISTRAR
        );
        console.log(
            "MinimalAVSRegistrar deployed to:",
            address(minimalAVSRegistrar)
        );

        // Deploy proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(minimalAVSRegistrar),
            address(proxyAdmin),
            abi.encodeWithSelector(MinimalAVSRegistrar.initialize.selector)
        );
        console.log("MinimalAVSRegistrar proxy deployed to:", address(proxy));

        avsRegistrar = IAVSRegistrar(address(proxy));

        // Transfer ownership of proxy to deployer
        proxyAdmin.transferOwnership(avs);
        console.log("ProxyAdmin transferred to:", avs);

        vm.stopBroadcast();
    }

    function _setUpAVS(uint256 avsPrivateKey, address avs) internal {
        vm.startBroadcast(avsPrivateKey);

        // Update AVS metadata URI
        ALLOCATION_MANAGER.updateAVSMetadataURI(avs, "https://avs.test.xyz");

        // Set AVS registrar
        ALLOCATION_MANAGER.setAVSRegistrar(avs, IAVSRegistrar(avsRegistrar));

        // Create Operator Sets
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = STRATEGY_WETH;
        IAllocationManagerTypes.CreateSetParams[]
            memory createOperatorSetParams = new IAllocationManagerTypes.CreateSetParams[](
                1
            );
        createOperatorSetParams[0] = IAllocationManagerTypes.CreateSetParams({
            operatorSetId: 0,
            strategies: strategies
        });
        ALLOCATION_MANAGER.createOperatorSets(avs, createOperatorSetParams);

        vm.stopBroadcast();
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        uint256 avsPrivateKey = vm.envUint("PRIVATE_KEY_AVS");
        address avs = vm.addr(avsPrivateKey);
        console.log("AVS address:", avs);
 
        _deployContracts(deployerPrivateKey, avs);
        _setUpAVS(avsPrivateKey, avs);
    }
}
