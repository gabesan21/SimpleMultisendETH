// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender
pragma solidity 0.4.23;

import "./OwnedUpgradeabilityStorage.sol";
import "./Claimable.sol";
import "./SafeMath.sol";

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract FortMultisend is OwnedUpgradeabilityStorage, Claimable {
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);
    event ClaimedETH(address owner, uint256 balance);

    uint256 public fee;

    function() public payable {}

    constructor() public {
        setOwner(msg.sender);
        setArrayLimit(91);
        fee = 0;
        boolStorage[keccak256("rs_multisender_initialized")] = true;
    }

    function txCount(address customer) public view returns (uint256) {
        return uintStorage[keccak256("txCount", customer)];
    }

    function arrayLimit() public view returns (uint256) {
        return uintStorage[keccak256("arrayLimit")];
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        uintStorage[keccak256("arrayLimit")] = _newLimit;
    }

    function setFee() public onlyOwner {
        fee = 5;
    }

    function unsetFee() public onlyOwner {
        fee = 0;
    }

    function multisendToken(
        address token,
        address[] _contributors,
        uint256[] _balances
    ) public {
        uint256 total = 0;
        uint256 totalFee = 0;
        uint256 _fee = 0;
        require(_contributors.length <= arrayLimit());
        ERC20 erc20token = ERC20(token);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            totalFee += _balances[i];
            _fee = (_balances[i] * fee) / 1000;
            _balances[i] = _balances[i].sub(_fee);
            erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
            total += _balances[i];
        }
        totalFee -= total;
        erc20token.transferFrom(msg.sender, address(this), totalFee);
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(total, token);
    }

    function multisendEther(address[] _contributors, uint256[] _balances)
        public
        payable
    {
        require(_contributors.length <= arrayLimit());
        uint256 _fee;

        for (uint256 i = 0; i < _contributors.length; i++) {
            _fee = (_balances[i] * fee) / 1000;
            _balances[i] = _balances[i].sub(_fee);
            _contributors[i].transfer(_balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function claimTokens(address _token) public onlyOwner {
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }

    function claimETH() public onlyOwner {
        owner().transfer(address(this).balance);
        emit ClaimedETH(owner(), address(this).balance);
    }

    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256("txCount", customer)] = _txCount;
    }
}
