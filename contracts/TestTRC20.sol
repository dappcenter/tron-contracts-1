pragma solidity >=0.5.4;

import "./tokens/TRC20/TRC20Mintable.sol";

contract TestTRC20 is TRC20Mintable {
    constructor () public {
        mint(msg.sender, 100000000000);
    }
}

