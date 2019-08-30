pragma solidity >=0.4.24;

contract Dividends {
    address _owner;

    constructor() public {
        _owner = msg.sender;
    }

    function () external payable { }
}