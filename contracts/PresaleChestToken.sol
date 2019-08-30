pragma solidity >=0.5.4;

import "./tokens/TRC20/TRC20Mintable.sol";
import "./tokens/TRC20/TRC20Detailed.sol";
import "./PresaleChestGateway.sol";

contract PresaleChestToken is TRC20Mintable, TRC20Detailed {
    PresaleChestGateway private _gatewayContract;
    uint256 private _id;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 id, PresaleChestGateway gatewayContract) TRC20Detailed(name, symbol, decimals) public {
        _gatewayContract = gatewayContract;
        _id = id;
    }

    function sendToGateway(uint256 amount) external {
        transfer(address(_gatewayContract), amount);
        _gatewayContract.onChestReceived(msg.sender, _id, amount);
    }
}


