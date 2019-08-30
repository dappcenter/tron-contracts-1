pragma solidity >=0.4.24;

import "@openzeppelin/contracts/ownership/Ownable.sol";

contract PresaleChestGateway is Ownable {

    mapping(address => bool) tokens;

    event ChestReceived(address indexed from, uint256 chestId, uint256 amount);

    function onChestReceived(address from, uint256 chestId, uint256 amount) external {
        require(tokens[msg.sender], "not approved token");
        
        emit ChestReceived(from, chestId, amount);
    }

    function addToken(address token) external onlyOwner {
        tokens[token] = true;
    }
}