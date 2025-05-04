// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ERC20BDA} from "../src/ERC20BDA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC20BDATest is Test {
    ERC20BDA public token;

    // setup few addresses with private keys for signing tests
    uint256 private idp1PrivateKey = 0xdeadbeef;
    uint256 private user3PrivateKey = 0xbeefdead;
    
    address public admin = address(0x1);
    address public mintingAdmin1 = address(0x2);
    address public mintingAdmin2 = address(0x3);
    address public restrAdmin1 = address(0x4);
    address public restrAdmin2 = address(0x5);
    address public idpAdmin1 = address(0x6);
    address public idpAdmin2 = address(0x7);
    address public idp1 = vm.addr(idp1PrivateKey);
    address public idp2 = address(0x9);
    address public user1 = address(0x10);
    address public user2 = address(0x11);
    address public user3 = vm.addr(user3PrivateKey);

    uint256 public maxSupply = 1_000_000 * 10**18;
    uint256 public maxDailyLimit = 10_000 * 10**18;
    uint256 public expirationTimeH = 720; // 30 days
    
    bytes32 public constant mintingAdminRole = keccak256("MINTING_ADMIN_ROLE");
    bytes32 public constant restrAdminRole = keccak256("RESTR_ADMIN_ROLE");
    bytes32 public constant idpAdminRole = keccak256("IDP_ADMIN_ROLE");
    
    function setUp() public {
        vm.startPrank(admin);

        address[] memory mintingAdmins = new address[](2);
        mintingAdmins[0] = mintingAdmin1;
        mintingAdmins[1] = mintingAdmin2;
        
        address[] memory restrAdmins = new address[](2);
        restrAdmins[0] = restrAdmin1;
        restrAdmins[1] = restrAdmin2;
        
        address[] memory idpAdmins = new address[](2);
        idpAdmins[0] = idpAdmin1;
        idpAdmins[1] = idpAdmin2;
        
        address[] memory identityProviders = new address[](2);
        identityProviders[0] = idp1;
        identityProviders[1] = idp2;
        
        token = new ERC20BDA(
            maxSupply,
            maxDailyLimit,
            expirationTimeH,
            mintingAdmins,
            restrAdmins,
            identityProviders,
            idpAdmins
        );
        vm.stopPrank();
    }
    
    // Constructor Tests
    
    function testConstructor() public view {
        assertEq(token.name(), "ERC20BDA");
        assertEq(token.symbol(), "ERC");
        assertEq(token.cap(), maxSupply);
        assertEq(token.maxDailyLimit(), maxDailyLimit);
        assertEq(token.expirationTime(), expirationTimeH * 1 hours);
        // check roles
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(mintingAdminRole, mintingAdmin1));
        assertTrue(token.hasRole(mintingAdminRole, mintingAdmin2));
        assertTrue(token.hasRole(restrAdminRole, restrAdmin1));
        assertTrue(token.hasRole(restrAdminRole, restrAdmin2));
        assertTrue(token.hasRole(idpAdminRole, idpAdmin1));
        assertTrue(token.hasRole(idpAdminRole, idpAdmin2));
        // check identity providers
        assertTrue(token.isAddressIDP(idp1));
        assertTrue(token.isAddressIDP(idp2));
        assertEq(token.identityProviders(0), idp1);
        assertEq(token.identityProviders(1), idp2);
    }
    
    function testConstructorInvalidParameters() public {
        vm.startPrank(admin);
        
        address[] memory mintingAdmins = new address[](2);
        mintingAdmins[0] = mintingAdmin1;
        mintingAdmins[1] = mintingAdmin2;
        
        address[] memory restrAdmins = new address[](2);
        restrAdmins[0] = restrAdmin1;
        restrAdmins[1] = restrAdmin2;
        
        address[] memory idpAdmins = new address[](2);
        idpAdmins[0] = idpAdmin1;
        idpAdmins[1] = idpAdmin2;
        
        address[] memory identityProviders = new address[](2);
        identityProviders[0] = idp1;
        identityProviders[1] = idp1; // duplicate IDP
        
        // test duplicate IDP
        vm.expectRevert("Duplicate IDP");
        new ERC20BDA(
            maxSupply,
            maxDailyLimit,
            expirationTimeH,
            mintingAdmins,
            restrAdmins,
            identityProviders,
            idpAdmins
        );
        
        // reset identityProviders
        identityProviders[0] = idp1;
        identityProviders[1] = idp2;
        
        // test daily limit > max supply
        vm.expectRevert(
            "Daily limit cannot be larger than maximum supply"
        );
        new ERC20BDA(
            maxSupply,
            maxSupply + 1,
            expirationTimeH,
            mintingAdmins,
            restrAdmins,
            identityProviders,
            idpAdmins
        );
        
        // test zero expiration time
        vm.expectRevert("Expiration time must be greater than 0");
        new ERC20BDA(
            maxSupply,
            maxDailyLimit,
            0,
            mintingAdmins,
            restrAdmins,
            identityProviders,
            idpAdmins
        );
        vm.stopPrank();
    }
    
    // Minting Tests
    
    function testMintSuccessful(uint256 amount) public {
        vm.assume(amount <= maxDailyLimit);
        // first verify the user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        // mint tokens
        vm.prank(mintingAdmin1);
        token.mint(user1, amount);
        // check balances
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.dailyMinted(), amount);
    }
    
    function testMintDailyLimitReset() public {
        // first verify the user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        // mint tokens on day 1
        vm.startPrank(mintingAdmin1);
        uint256 amount = 1000 * 10**18;
        token.mint(user1, amount);
        // check balances
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.dailyMinted(), amount);
        // advance time by 1 day
        vm.warp(block.timestamp + 1 days);
        // mint tokens on day 2
        token.mint(user1, amount);
        // check balances
        assertEq(token.balanceOf(user1), amount * 2);
        assertEq(token.dailyMinted(), amount); // reset to current day's mint
        vm.stopPrank();
    }
    
    function testMintDailyLimitExceeded(uint256 amount) public {
        // assume require check for fuzzing
        vm.assume(amount > maxDailyLimit);
        // first verify the user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        // try to mint more than daily limit
        vm.prank(mintingAdmin1);
        vm.expectRevert("Daily mint limit exceeded");
        token.mint(user1, amount);
    }
    
    function testMintUnauthorized() public {
        // try to mint as non-admin
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, 1000 * 10**18);
    }
    
    function testMintToNonVerifiedAddress() public {
        // try to mint to non-verified user
        uint256 amount = 1000 * 10**18;
        vm.prank(mintingAdmin1);
        vm.expectRevert("Cannot mint to non-verified address");
        token.mint(user1, amount);
    }

    // Transfer Tests
    
    function testTransferSuccessful() public {
        // verify users
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user2);
        // mint tokens to user1
        vm.prank(mintingAdmin1);
        token.mint(user1, 1000 * 10**18);
        // transfer from user1 to user2
        vm.prank(user1);
        token.transfer(user2, 500 * 10**18);
        // check balances
        assertEq(token.balanceOf(user1), 500 * 10**18);
        assertEq(token.balanceOf(user2), 500 * 10**18);
    }
    
    function testTransferWithLimit() public {
        // verify users
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user2);
        // mint tokens to user1
        vm.prank(mintingAdmin1);
        token.mint(user1, 1000 * 10**18);
        // set transfer limit for user1
        vm.prank(restrAdmin1);
        token.setTransferLimit(user1, 300 * 10**18);
        // transfer within limit
        vm.prank(user1);
        token.transfer(user2, 200 * 10**18);
        // check balances
        assertEq(token.balanceOf(user1), 800 * 10**18);
        assertEq(token.balanceOf(user2), 200 * 10**18);
        // try to transfer exceeding limit
        vm.prank(user1);
        vm.expectRevert("Transfer limit exceeded");
        token.transfer(user2, 200 * 10**18);
        // advance time by 1 day
        vm.warp(block.timestamp + 1 days);
        // transfer again after limit reset
        vm.prank(user1);
        token.transfer(user2, 200 * 10**18);
        // check balances
        assertEq(token.balanceOf(user1), 600 * 10**18);
        assertEq(token.balanceOf(user2), 400 * 10**18);
    }
    
    function testTransferFromNonVerifiedAddress() public {
        // verify receiver
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user2);
        // mint tokens to user1 (need to verify first)
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        vm.prank(mintingAdmin1);
        token.mint(user1, 1000 * 10**18);
        // expire user1 verification
        vm.warp(block.timestamp + token.expirationTime() + 1);
        // try to transfer from non-verified user
        vm.prank(user1);
        vm.expectRevert("Sender is not verified");
        token.transfer(user2, 500 * 10**18);
    }
    
    function testTransferToNonVerifiedAddress() public {
        // verify sender
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        // mint tokens to user1
        vm.prank(mintingAdmin1);
        token.mint(user1, 1000 * 10**18);
        // try to transfer to non-verified user
        vm.prank(user1);
        vm.expectRevert("Receiver is not verified");
        token.transfer(user2, 500 * 10**18);
    }
    
    function testTransferFromBlockedAddress() public {
        // verify users
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user2);
        // mint tokens to user1
        vm.prank(mintingAdmin1);
        token.mint(user1, 1000 * 10**18);
        // block user1
        vm.prank(idpAdmin1);
        token.blockAddress(user1);
        // try to transfer from blocked user
        vm.prank(user1);
        vm.expectRevert("Sender is blocked");
        token.transfer(user2, 500 * 10**18);
        // unblock user1
        vm.prank(idpAdmin1);
        token.unblockAddress(user1);
        // now transfer should work
        vm.prank(user1);
        token.transfer(user2, 500 * 10**18);
        assertEq(token.balanceOf(user1), 500 * 10**18);
        assertEq(token.balanceOf(user2), 500 * 10**18);
    }
    
    // Identity Management Tests
    
    function testVerifyIdentity() public {
        uint256 timestamp = block.timestamp;
        // generate signature from idp1
        bytes32 messageHash = getVerificationMessageHash(user1, timestamp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(idp1PrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        // user verifies identity
        vm.prank(user1);
        token.verifyIdentity(timestamp, signature);
        // check verification status
        assertTrue(token.isVerified(user1));
        assertEq(token.verificationTimestamp(user1), timestamp);
    }
    
    function testVerifyIdentityInvalidSignature() public {
        uint256 timestamp = block.timestamp;
        // generate signature from user3 (not an IDP)
        bytes32 messageHash = getVerificationMessageHash(user1, timestamp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user3PrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        // try to verify with invalid signature
        vm.prank(user1);
        vm.expectRevert("Invalid IDP signature");
        token.verifyIdentity(timestamp, signature);
    }
    
    function testVerifyIdentityFutureTimestamp() public {
        uint256 timestamp = block.timestamp + 1 hours;
        // generate signature from idp1
        bytes32 messageHash = getVerificationMessageHash(user1, timestamp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(idp1PrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        // try to verify with future timestamp
        vm.prank(user1);
        vm.expectRevert("Future timestamp");
        token.verifyIdentity(timestamp, signature);
    }
    
    function testVerifyAddressAdmin() public {
        // admin verifies user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        // check verification status
        assertTrue(token.isVerified(user1));
        assertEq(token.verificationTimestamp(user1), block.timestamp);
    }
    
    function testVerifyAddressAdminUnauthorized() public {
        // try to verify as non-admin
        vm.prank(user2);
        vm.expectRevert();
        token.verifyAddressAdmin(user1);
    }
    
    function testRevokeVerification() public {
        // first verify the user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        assertTrue(token.isVerified(user1));
        // revoke verification
        vm.prank(idpAdmin1);
        token.revokeVerification(user1);
        // check verification status
        assertFalse(token.isVerified(user1));
        assertEq(token.verificationTimestamp(user1), 0);
    }
    
    function testBlockUnblockAddress() public {
        // block user
        vm.prank(idpAdmin1);
        token.blockAddress(user1);
        // check blocked status
        assertTrue(token.isAddressBlocked(user1));
        // unblock user
        vm.prank(idpAdmin1);
        token.unblockAddress(user1);
        // check blocked status
        assertFalse(token.isAddressBlocked(user1));
    }
    
    function testExpiredVerification() public {
        // first verify the user
        vm.prank(idpAdmin1);
        token.verifyAddressAdmin(user1);
        assertTrue(token.isVerified(user1));
        // advance time beyond expiration
        vm.warp(block.timestamp + token.expirationTime() + 1);
        // check verification status
        assertFalse(token.isVerified(user1));
    }
    
    // Identity Provider Management Tests
    
    function testAddIdentityProvider() public {
        uint256 newIdpPrivateKey = 0x987889;
        address newIdp = vm.addr(newIdpPrivateKey);
        // check IDP status
        vm.prank(idpAdmin1);
        token.addIdentityProvider(newIdp);
        assertTrue(token.isAddressIDP(newIdp));
        // generate valid signature using the new IDP's private key
        uint256 timestamp = block.timestamp;
        bytes32 messageHash = getVerificationMessageHash(user1, timestamp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(newIdpPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.prank(user1);
        token.verifyIdentity(timestamp, signature);
        assertTrue(token.isVerified(user1));
    }
    
    function testAddDuplicateIdentityProvider() public {
        // try to add existing IDP
        vm.prank(idpAdmin1);
        vm.expectRevert("Address is already an IDP");
        token.addIdentityProvider(idp1);
    }
    
    function testRemoveIdentityProvider() public {
        // remove existing IDP
        vm.prank(idpAdmin1);
        token.removeIdentityProvider(idp1);
        // check IDP status
        assertFalse(token.isAddressIDP(idp1));

    }
    
    function testRemoveNonExistentIdentityProvider() public {
        // try to remove non-existent IDP
        vm.prank(idpAdmin1);
        vm.expectRevert("Address is not an IDP");
        token.removeIdentityProvider(user1);
    }
    
    // Transfer Restriction Tests
    
    function testSetTransferLimit(uint256 limit) public {
        // set transfer limit
        vm.prank(restrAdmin1);
        token.setTransferLimit(user1, limit);
        // check limit
        (uint256 storedLimit, uint256 amountTransferred, uint256 lastReset) = token.transferLimits(user1);
        assertEq(storedLimit, limit);
        assertEq(amountTransferred, 0);
        assertEq(lastReset, block.timestamp);
    }
    
    function testUnsetTransferLimit() public {
        // first set a limit
        vm.prank(restrAdmin1);
        token.setTransferLimit(user1, 500 * 10**18);
        // unset limit
        vm.prank(restrAdmin1);
        token.unsetTransferLimit(user1);
        // check limit is removed
        (uint256 storedLimit, uint256 amountTransferred, uint256 lastReset) = token.transferLimits(user1);
        assertEq(storedLimit, 0);
        assertEq(amountTransferred, 0);
        assertEq(lastReset, 0);
    }
    
    // Proposal System Tests
    
    function testProposeRoleChange() public {
        // create proposal to add user1 as mintingAdmin
        vm.prank(mintingAdmin1);
        uint256 proposalId = token.proposeRoleChange(mintingAdminRole, user1, true);
        // check proposal was created
        ERC20BDA.Proposal memory proposal = token.getProposal(proposalId);
        bytes32 role = proposal.role;
        address account = proposal.account;
        bool isAdd = proposal.isAdd;
        bool executed = proposal.executed;
        assertEq(role, mintingAdminRole);
        assertEq(account, user1);
        assertTrue(isAdd);
        assertFalse(executed);
    }
    
    function testProposalApproval() public {
        // create proposal
        vm.prank(mintingAdmin1);
        uint256 proposalId = token.proposeRoleChange(mintingAdminRole, user1, true);
        // approve proposal
        vm.prank(mintingAdmin2);
        token.approveProposal(proposalId);
        // try to approve again
        vm.prank(mintingAdmin2);
        vm.expectRevert("Already approved");
        token.approveProposal(proposalId);
    }
    
    function testExecuteProposal() public {
        // create proposal
        vm.prank(mintingAdmin1);
        uint256 proposalId = token.proposeRoleChange(mintingAdminRole, user1, true);
        // for 2 minting admins are required 2 approves (2 / 2 + 1)
        vm.prank(mintingAdmin1);
        token.approveProposal(proposalId);
        vm.prank(mintingAdmin2);
        token.approveProposal(proposalId);
        // execute proposal (anyone can execute)
        vm.prank(user3);
        token.executeProposal(proposalId);
        // check role was granted
        assertTrue(token.hasRole(mintingAdminRole, user1));
        // check proposal is marked executed
        ERC20BDA.Proposal memory proposal = token.getProposal(proposalId);
        bool executed = proposal.executed;
        assertTrue(executed);
    }
    
    function testExecuteProposalRevoke() public {
        // first add user1 as mintingAdmin
        vm.prank(mintingAdmin1);
        uint256 proposalId1 = token.proposeRoleChange(mintingAdminRole, user1, true);
        vm.prank(mintingAdmin1);
        token.approveProposal(proposalId1);
        vm.prank(mintingAdmin2);
        token.approveProposal(proposalId1);
        vm.prank(user3);
        token.executeProposal(proposalId1);
        // check role
        assertTrue(token.hasRole(mintingAdminRole, user1));
        // now create proposal to revoke role
        vm.prank(mintingAdmin1);
        uint256 proposalId2 = token.proposeRoleChange(mintingAdminRole, user1, false);
        vm.prank(mintingAdmin1);
        token.approveProposal(proposalId2);
        vm.prank(mintingAdmin2);
        token.approveProposal(proposalId2);
        vm.prank(user3);
        token.executeProposal(proposalId2);
        // check role was revoked
        assertFalse(token.hasRole(mintingAdminRole, user1));
    }
    
    function testExecuteAlreadyExecutedProposal() public {
        // create and execute proposal
        vm.prank(mintingAdmin1);
        uint256 proposalId = token.proposeRoleChange(mintingAdminRole, user1, true);
        // get approvals
        vm.prank(mintingAdmin1);
        token.approveProposal(proposalId);
        vm.prank(mintingAdmin2);
        token.approveProposal(proposalId);
        vm.prank(user3);
        token.executeProposal(proposalId);
        // try to execute again
        vm.prank(user3);
        vm.expectRevert("Proposal already executed");
        token.executeProposal(proposalId);
    }
    
    function testExecuteProposalNotEnoughApprovals() public {
        // create proposal
        vm.prank(mintingAdmin1);
        uint256 proposalId = token.proposeRoleChange(mintingAdminRole, user1, true);
        // try to execute without enough approvals
        vm.prank(user3);
        vm.expectRevert("Not enough approvals");
        token.executeProposal(proposalId);
    }
    
    // Helper Function
    
    function getVerificationMessageHash(address account, uint256 timestamp) internal pure returns (bytes32) {
        string memory message = string(
            abi.encodePacked(
                "User with address ",
                Strings.toHexString(uint256(uint160(account)), 20),
                " has verified their identity at ",
                Strings.toString(timestamp)
            )
        );
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(message).length),
                message
            )
        );
    }
}