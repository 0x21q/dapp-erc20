// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC20BDA is ERC20Capped, AccessControlEnumerable {
    // roles
    bytes32 public constant mintingAdmin = keccak256("MINTING_ADMIN_ROLE");
    bytes32 public constant restrAdmin = keccak256("RESTR_ADMIN_ROLE");
    bytes32 public constant idpAdmin = keccak256("IDP_ADMIN_ROLE");

    uint256 public immutable maxDailyLimit; // for minting
    uint256 public dailyMinted;
    uint256 public lastMintReset;
    uint256 public immutable expirationTime;

    // transfer limits
    struct TransferLimit {
        uint256 limit;
        uint256 amountTransferred;
        uint256 lastReset;
    }

    mapping(address => TransferLimit) public transferLimits;
    mapping(address => bool) public isAddressIDP;
    mapping(address => uint256) public verificationTimestamp;
    mapping(address => bool) public isAddressBlocked;

    address[] public identityProviders;

    uint256 public nextProposalID;
    mapping(uint256 => Proposal) public proposals;

    // proposal and voting system
    struct Proposal {
        bytes32 role;
        address account;
        bool isAdd;
        address[] approvals;
        bool executed;
    }

    event ProposalCreated(uint256 proposalId, bytes32 role, address account, bool isAdd, address proposer);
    event ProposalApproved(uint256 proposalId, address approver);
    event ProposalExecuted(uint256 proposalId);
    event AddressVerifiedIDP(address indexed account, uint256 timestamp);
    event AddressVerifiedAdmin(address indexed account, uint256 timestamp);
    event AddressRevoked(address indexed account);
    event AddressBlocked(address indexed account);
    event AddressUnblocked(address indexed account);
    event TransferRestrictionCreated(address indexed account, uint256 limit);

    // other transaction related events are already emitted from openzeppelin

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
            require(!isAddressIDP[_identityProviders[i]], "Duplicate IDP");
            isAddressIDP[_identityProviders[i]] = true;
            identityProviders.push(_identityProviders[i]);
        }

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
            amountTransferred: 0,
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

    // based on the https://solidity-by-example.org/signature/
    function verifyIdentity(uint256 timestamp, bytes memory signature) external {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r; bytes32 s; uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        string memory message = string(
            abi.encodePacked(
                "User with address ",
                Strings.toHexString(uint256(uint160(msg.sender)), 20),
                " has verified their identity at ",
                Strings.toString(timestamp)
            )
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(message).length),
                message
            )
        );

        address signer = ecrecover(messageHash, v, r, s);

        require(isAddressIDP[signer], "Invalid IDP signature");
        require(timestamp <= block.timestamp, "Future timestamp");

        verificationTimestamp[msg.sender] = timestamp;
        emit AddressVerifiedIDP(msg.sender, timestamp);
    }

    function verifyAddressAdmin(address account) external onlyRole(idpAdmin) {
        verificationTimestamp[account] = block.timestamp;
        emit AddressVerifiedAdmin(account, block.timestamp);
    }

    function revokeVerification(address account) external onlyRole(idpAdmin) {
        verificationTimestamp[account] = 0;
        emit AddressRevoked(account);
    }

    function blockAddress(address account) external onlyRole(idpAdmin) {
        isAddressBlocked[account] = true;
        emit AddressBlocked(account);
    }

    function unblockAddress(address account) external onlyRole(idpAdmin) {
        isAddressBlocked[account] = false;
        emit AddressUnblocked(account);
    }

    // blocked users are still classified as verified
    function isVerified(address account) public view returns (bool) {
        return
            verificationTimestamp[account] != 0 &&
            block.timestamp <= verificationTimestamp[account] + expirationTime;
    }

    // proposal and voting functions
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

    function proposeRoleChange(bytes32 role, address account, bool isAdd) external returns (uint256) {
        require(role == mintingAdmin || role == restrAdmin || role == idpAdmin, "Invalid role");
        require(hasRole(role, msg.sender), "Caller not a role member");

        uint proposalID = nextProposalID++;
        proposals[proposalID] = Proposal({
            role: role,
            account: account,
            isAdd: isAdd,
            approvals: new address[](0),
            executed: false
        });
        emit ProposalCreated(proposalID, role, account, isAdd, msg.sender);

        return proposalID;
    }

    function approveProposal(uint256 proposalID) external {
        Proposal storage proposal = proposals[proposalID];
        require(hasRole(proposal.role, msg.sender), "Caller not a role member");
        require(!proposal.executed, "Proposal already executed");

        // Check if the caller has already approved
        for (uint i = 0; i < proposal.approvals.length; i++) {
            if (proposal.approvals[i] == msg.sender) {
                revert("Already approved");
            }
        }
        proposal.approvals.push(msg.sender);
        emit ProposalApproved(proposalID, msg.sender);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        bytes32 role = proposal.role;
        require(role == mintingAdmin || role == restrAdmin || role == idpAdmin, "Invalid role"); // maybe not necessary

        uint256 memberCount = getRoleMemberCount(role);
        require(memberCount > 0, "Role has no members");

        uint256 required = (memberCount / 2) + 1; // maybe (memberCount + 1) / 2

        uint256 validApprovals = 0;
        for (uint i = 0; i < proposal.approvals.length; i++) {
            if (hasRole(role, proposal.approvals[i])) {
                validApprovals++;
            }
        }
        require(validApprovals >= required, "Not enough approvals");

        // either grant or revoke role based on the proposal
        if (proposal.isAdd) {
            grantRole(role, proposal.account);
        } else {
            revokeRole(role, proposal.account);
        }

        proposal.executed = true; // maybe at the beggining
        emit ProposalExecuted(proposalId);
    }

    function _update(
        address sender,
        address receiver,
        uint256 amount
    ) internal override {
        // check if sender is not blocked
        if (sender != address(0)) {
            require(!isAddressBlocked[sender], "Sender is blocked");
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

            // check transfer limit but only for accounts WITH limit
            TransferLimit storage limit = transferLimits[sender];
            if (limit.lastReset != 0) {
                if (block.timestamp >= limit.lastReset + 1 days) {
                    limit.amountTransferred = 0;
                    limit.lastReset = block.timestamp;
                }
                require(
                    limit.amountTransferred + amount <= limit.limit,
                    "Transfer limit exceeded"
                );
                limit.amountTransferred += amount;
            }
        }

        super._update(sender, receiver, amount);
    }
}
