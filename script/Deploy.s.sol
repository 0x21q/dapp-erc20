// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ERC20BDA} from "../src/ERC20BDA.sol";

contract DeployScript is Script {
    function run() external returns (ERC20BDA) {
        address[] memory mintingAdmins = new address[](1);
        address[] memory restrAdmins = new address[](1);
        address[] memory idps = new address[](1);
        address[] memory idpAdmins = new address[](1);

        // anvil accs
        mintingAdmins[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        restrAdmins[0] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        idpAdmins[0] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        idps[0] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

        // setup contract
        vm.startBroadcast();
        ERC20BDA erc20contract = new ERC20BDA(
            1_000_000 * 10**18, // uint256 _maxSupply,
            10_000 * 10**18,    // uint256 _maxDailyLimit,
            720 * 10**18,       // uint256 _expirationTimeH,
            mintingAdmins,      // address[] memory _mintingAdmins,
            restrAdmins,        // address[] memory _restrAdmins,
            idps,               // address[] memory _identityProviders,
            idpAdmins           // address[] memory _idpAdmins
        );
        vm.stopBroadcast();

        // define user acc to mint some tokens (another anvil account)
        address user_account = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

        // verify the account use private key of idp admin
        vm.startBroadcast(0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6);
        erc20contract.verifyAddressAdmin(user_account);
        vm.stopBroadcast();

        // mint tokens
        uint256 amount = 1000 * 10**18;

        // use private key of minting admin
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        erc20contract.mint(user_account, amount);
        vm.stopBroadcast();

        return erc20contract;
    }
}
