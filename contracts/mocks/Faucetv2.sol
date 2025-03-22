// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Faucetv2 {
    using SafeERC20 for IERC20;
    address public owner;
    uint256 public tokenAmount1;
    uint256 public tokenAmount2;
    uint256 public waitTime;
    bool public lock;
    IERC20 public tokenInstance1;
    IERC20 public tokenInstance2;

    mapping(address => uint256) unlockTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "sender is not a owner");
        _;
    }

    //Events
    event Withdrawals(address indexed to, uint amount1, uint amount2);
    event Deposit(address indexed from, uint amount);

    constructor(address _tokenInstance1, address _tokenInstance2,   uint256 _tokenAmount1, uint256 _tokenAmount2,  uint256 _waitTime) {
        tokenInstance1 = IERC20(_tokenInstance1);
        tokenInstance2 = IERC20(_tokenInstance2);

        tokenAmount1 = _tokenAmount1;
        tokenAmount2 = _tokenAmount2;

        waitTime = _waitTime;
        lock = false;
        owner = msg.sender;
    }

    function requestTokens() external {
        //re-entrancy mutex
        require(!lock);
        lock = true;

        //check unlock time
        require(allowedToWithdraw(msg.sender));
        unlockTime[msg.sender] = block.timestamp + waitTime;

        //check faucet balance
        require(tokenInstance1.balanceOf(address(this)) >= tokenAmount1);
        require(tokenInstance2.balanceOf(address(this)) >= tokenAmount2);
        //transfer tokens
        tokenInstance1.safeTransfer(msg.sender, tokenAmount1);
        tokenInstance2.safeTransfer(msg.sender, tokenAmount2);
        emit Withdrawals(msg.sender,tokenAmount1,tokenAmount2);

        //re-entrancy mutex
        lock = false;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(unlockTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= unlockTime[_address]) {
            return true;
        }
        return false;
    }

    function setWaitTime (uint256 _waitTime) external onlyOwner{
        waitTime = _waitTime;
    }
    function setToken1Address(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0));
        tokenInstance1 = IERC20(_tokenAddress);
    }

    function setToken2Address(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0));
        tokenInstance2 = IERC20(_tokenAddress);
    }

    function setTokenAmount1(uint256 _tokenAmount) external onlyOwner {
        tokenAmount1 = _tokenAmount;
    }

    function setTokenAmount2(uint256 _tokenAmount) external onlyOwner {
        tokenAmount2 = _tokenAmount;
    }


    function withdawAll() external onlyOwner{
        if (address(this).balance > 0){
            (bool callSuccess, ) = owner.call{value: address(this).balance}("");
            require(callSuccess, "Transfer failed");
        }
        if (tokenInstance1.balanceOf(address(this))>0){
            tokenInstance1.safeTransfer(msg.sender, tokenInstance1.balanceOf(address(this)));
        }
        if (tokenInstance2.balanceOf(address(this))>0){
            tokenInstance2.safeTransfer(msg.sender, tokenInstance2.balanceOf(address(this)));
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }


    function transferToken1(address to, uint256 amount) external onlyOwner{

        uint256 balance = tokenInstance1.balanceOf(address(this));
        require(balance >= amount, "insufficient balance");
        tokenInstance1.safeTransfer(to, amount);

    }

    function transferToken2(address to, uint256 amount) external onlyOwner {
        uint256 balance = tokenInstance2.balanceOf(address(this));
        require(balance >= amount, "insufficient balance");
        tokenInstance2.safeTransfer(to, amount);

    }


    //  Sending Tokens to this faucet fills it up
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}