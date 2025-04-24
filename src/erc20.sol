// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20bda is IERC20 {
    string public constant name = "ERC20bda";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => uint256) limits;

    uint256 totalSupply = 0;
    uint256 maxSupply;
    address[] mintingAdmins;
    address[] restrAdmins;
    uint256 maxDailyLimit;
    uint256 dailyMinted = 0; // TODO: needs to be restarted every day

    modifier checkDailyLimit(uint256 maxDailyLimit, uint256 maxSupply) {
        if (maxDailyLimit > maxSupply) {
            revert("Maximum daily limit cannot be larger than maximum supply.");
        }
        _;
    }

    constructor(
        uint256 memory _maxSupply,
        address[] memory _mintingAdmins,
        uint256 memory _maxDailyLimit,
        address[] memory _restrAdmins,
    ) checkDailyLimit(_maxDailyLimit, _maxSupply) {
        maxSupply = _maxSupply;
        mintingAdmins = _mintingAdmins;
        maxDailyLimit = _maxDailyLimit;
        restrAdmins = _restrAdmins;
        balances[msg.sender] = totalSupply; // not sure what this does
    }

    function mintTokens(address receiver, uint256 numTokens) public returns (bool) {
        // check if daily limit won't be passed
        require(dailyMinted + numTokens <= maxDailyLimit);
        require(totalSupply + numTokens <= maxSupply);

        // check if sender has minting admin role
        bool memory isAdmin = false;
        for(uint i = 0; i < mintingAdmins.length; i++) {
            if (msg.sender == mintingAdmins[i]) {
                isAdmin = true;
            }
        }
        require(isAdmin);

        // mint tokens to receiver address
        dailyMinted = dailyMinted + numTokens;
        totalSupply = totalSupply + numTokens;
        balances[address(0x0)] = balances[address(0x0)] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(address(0x0), receiver, numTokens);

        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply;
    }

    function balanceOf(
        address tokenOwner
    ) public view override returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(
        address receiver,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(
        address delegate,
        uint256 numTokens
    ) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(
        address owner,
        address delegate
    ) public view override returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}
