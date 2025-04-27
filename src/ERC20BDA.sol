// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20BDA is ERC20Capped, AccessControl {
    // roles
    bytes32 public constant mintingAdmin = keccak256("MINTING_ADMIN_ROLE");
    bytes32 public constant restrAdmin = keccak256("RESTR_ADMIN_ROLE");
    bytes32 public constant idpAdmin = keccak256("IDP_ADMIN_ROLE");

    uint256 public immutable maxDailyLimit;
    uint256 public dailyMinted;
    uint256 public lastMintReset;
    uint256 public immutable expirationTime;

    struct TransferLimit {
        uint256 limit;
        uint256 used;
        uint256 lastReset;
    }

    mapping(address => TransferLimit) public transferLimits;
    mapping(address => bool) public isAddressIDP;
    mapping(address => uint256) public verificationTimestamp;
    mapping(address => bool) public isAddressBlocked;

    address[] public identityProviders;

    event AddressVerified(address indexed account, uint256 timestamp);
    event AddressRevoked(address indexed account);
    event AddressBlocked(address indexed account);
    event AddressUnblocked(address indexed account);
    event TransferRestrictionCreated(address indexed account, uint256 limit);

    // other transaction related events are already emitted in openzeppelin

    constructor(
        uint256 _maxSupply,
        uint256 _maxDailyLimit,
        uint256 _expirationTimeH,
        address[] memory _mintingAdmins,
        address[] memory _restrAdmins,
        address[] memory _identityProviders,
        address[] memory _idpAdmins
    ) ERC20("ERC20BDA", "ERC") ERC20Capped(_maxSupply) {
        require(
            _maxDailyLimit <= _maxSupply,
            "Maximum daily limit cannot be larger than maximum supply."
        );
        require(_expirationTimeH > 0, "Expiration time must be greater than 0");

        maxDailyLimit = _maxDailyLimit;
        lastMintReset = block.timestamp;
        expirationTime = _expirationTimeH * 1 hours;

        // initialize map for lookups and array for enumeration
        for (uint i = 0; i < _identityProviders.length; i++) {
            isAddressIDP[_identityProviders[i]] = true;
        }
        identityProviders = _identityProviders;

        // initialize roles
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint i = 0; i < _mintingAdmins.length; i++) {
            grantRole(mintingAdmin, _mintingAdmins[i]);
        }
        for (uint i = 0; i < _restrAdmins.length; i++) {
            grantRole(restrAdmin, _restrAdmins[i]);
        }
        for (uint i = 0; i < _idpAdmins.length; i++) {
            grantRole(idpAdmin, _idpAdmins[i]);
        }
    }

    function mint(
        address receiver,
        uint256 amount
    ) external onlyRole(mintingAdmin) {
        // reset daily limit if 24 hours have passed
        if (block.timestamp >= lastMintReset + 1 days) {
            dailyMinted = 0;
            lastMintReset = block.timestamp;
        }

        require(
            dailyMinted + amount <= maxDailyLimit,
            "Daily mint limit exceeded"
        );

        dailyMinted += amount;
        _mint(receiver, amount);
    }

    function setTransferLimit(
        address account,
        uint256 limit
    ) external onlyRole(restrAdmin) {
        transferLimits[account] = TransferLimit({
            limit: limit,
            used: 0,
            lastReset: block.timestamp
        });
        emit TransferRestrictionCreated(account, limit);
    }

    function addIdentityProvider(
        address idpAddress
    ) external onlyRole(idpAdmin) {
        require(!isAddressIDP[idpAddress], "Address is already an IDP");
        identityProviders.push(idpAddress);
        isAddressIDP[idpAddress] = true;
    }

    function removeIdentityProvider(
        address idpAddress
    ) external onlyRole(idpAdmin) {
        require(isAddressIDP[idpAddress], "Address is not an IDP");
        // swap last item with removed and pop
        for (uint256 i = 0; i < identityProviders.length; i++) {
            if (identityProviders[i] == idpAddress) {
                identityProviders[i] = identityProviders[
                    identityProviders.length - 1
                ];
                identityProviders.pop();
                break;
            }
        }
        isAddressIDP[idpAddress] = false;
    }

    function verifyAddressIDP(address account) external {
        require(isAddressIDP[msg.sender], "Caller is not an IDP");
        verificationTimestamp[account] = block.timestamp;
        emit AddressVerified(account, block.timestamp);
    }

    function verifyAddressAdmin(address account) external onlyRole(idpAdmin) {
        verificationTimestamp[account] = block.timestamp;
        emit AddressVerified(account, block.timestamp);
    }

    function revokeVerification(address account) external onlyRole(idpAdmin) {
        verificationTimestamp[account] = 0;
        emit AddressRevoked(account);
    }

    function blockAddress(address account) external onlyRole(idpAdmin) {
        isBlocked[account] = true;
        emit AddressBlocked(account);
    }

    function unblockAddress(address account) external onlyRole(idpAdmin) {
        isBlocked[account] = false;
        emit AddressUnblocked(account);
    }

    // blocked users are still classified as verified
    function isVerified(address account) public view returns (bool) {
        return
            verificationTimestamp[account] != 0 &&
            block.timestamp <= verificationTimestamp[account] + expirationTime;
    }

    function _update(
        address sender,
        address receiver,
        uint256 amount
    ) internal override {
        // check if sender is not blocked
        if (sender != address(0)) {
            require(!isBlocked[sender], "Sender is blocked");
        }

        // check verification status
        if (sender == address(0)) {
            require(
                isVerified(receiver),
                "Cannot mint to non-verified address"
            );
        } else if (receiver == address(0)) {
            require(
                isVerified(sender),
                "Cannot burn from non-verified address"
            );
        } else if (sender != address(0) && receiver != address(0)) {
            require(isVerified(sender), "Sender is not verified");
            require(isVerified(receiver), "Receiver is not verified");

            // check transfer limit
            TransferLimit storage limit = transferLimits[sender];
            if (block.timestamp >= limit.lastReset + 1 days) {
                limit.used = 0;
                limit.lastReset = block.timestamp;
            }
            require(
                limit.used + amount <= limit.limit,
                "Transfer limit exceeded"
            );
            limit.used += amount;
        }

        super._update(sender, receiver, amount);
    }
}
