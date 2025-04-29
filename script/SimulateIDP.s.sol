// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ERC20BDA} from "../src/ERC20BDA.sol";

contract IDPVerificationScript is Script {
    function run() external {
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address idp = vm.envAddress("IDP_ADDRESS");
        address userToVerify = vm.envAddress("USER_TO_VERIFY");

        // TODO

        vm.startBroadcast(idp);

        ERC20BDA(tokenAddress).verifyAddress(userToVerify);

        vm.stopBroadcast();

        console.log("Verified address:", userToVerify);
    }
}
