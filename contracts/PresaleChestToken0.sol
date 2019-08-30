pragma solidity >=0.5.4;

import "./PresaleChestToken.sol";

contract PresaleChestToken0 is PresaleChestToken {
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 id, PresaleChestGateway gatewayContract) PresaleChestToken(name, symbol, decimals, id, gatewayContract) public {
    }
}


