// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20BDA is ERC20Capped, AccessControl {
    // roles
    bytes32 public constant mintingAdmin = keccak256("MINTING_ADMIN_ROLE");
    bytes32 public constant restrAdmin = keccak256("RESTR_ADMIN_ROLE");

    uint256 public maxDailyLimit;
    uint256 public dailyMinted;
    uint256 public lastMintReset;

    struct TransferLimit {
        uint256 limit;
        uint256 used;
        uint256 lastReset;
    }

    mapping(address => TransferLimit) public transferLimits;
    mapping(address => bool) public isAddressIDP;
    mapping(address => bool) public isAddressVerified;

    constructor(
        uint256 _maxSupply,
        uint256 _maxDailyLimit,
        address[] memory _mintingAdmins,
        address[] memory _restrAdmins,
        address[] memory _identityProviders
    ) ERC20("ERC20BDA", "ERC") ERC20Capped(_maxSupply) {
        require(
            _maxDailyLimit <= _maxSupply,
            "Maximum daily limit cannot be larger than maximum supply."
        );

        maxDailyLimit = _maxDailyLimit;
        lastMintReset = block.timestamp;

        for (uint i = 0; i < _identityProviders.length; i++) {
            isAddressIDP[_identityProviders[i]] = true;
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint i = 0; i < _mintingAdmins.length; i++) {
            _setupRole(mintingAdmin, _mintingAdmins[i]);
        }
        for (uint i = 0; i < _restrAdmins.length; i++) {
            _setupRole(restrAdmin, _restrAdmins[i]);
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
        require(
            isVerified[receiver],
            "Non-verified address cannot receive tokens"
        );

        dailyMinted += amount;
        _mint(receiver, amount);
    }

    function setAddressAsVerified(
        address _address
    ) external onlyRole(mintingAdmin) {
        require(isAddressIDP[msg.sender], "Caller is not an IDP");
        isVerified[_address] = true;
        // emit AddressVerified(_address);
    }

    function setMaxDailyLimit(
        uint256 newLimit
    ) external onlyRole(mintingAdmin) {
        require(newLimit <= cap(), "Exceeds max supply");
        maxDailyLimit = newLimit;
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
    }

    function _update(
        address sender,
        address receiver,
        uint256 amount
    ) internal override {
        if (receiver != address(0)) {
            require(
                isVerified[receiver],
                "Non-verified address cannot receive tokens"
            );
        }

        // skip limit checks for minting and burning
        if (sender != address(0) && receiver != address(0)) {
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
