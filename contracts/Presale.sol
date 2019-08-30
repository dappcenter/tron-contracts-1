pragma solidity >=0.5.4;

import "./PresaleChestToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PresaleChestGateway.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Presale is ReentrancyGuard {
    using SafeMath for uint256;

    struct Chest {
        PresaleChestToken tokenContract;
        uint256 rate;
        uint256 maxPerAccount;
        ITRC20 paymentContract;
        uint256 cap;
        uint256 purchased;
    }

    mapping(uint256 => Chest) private _chests;
    mapping(uint256 => mapping(address => uint256)) purchased;
    mapping(address => address) referrals;

    // Address where funds are collected
    address payable private _wallet;
    address private _owner;
    PresaleChestGateway private _gatewayContract;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param referer who refered purchaser
     * @param chest type of the chest purchased
     * @param amount amount of chests purchased
     */
    event ChestPurchased(address indexed purchaser, address referer, uint256 chest, uint256 amount);

    /**
     * @param wallet Address where collected funds will be forwarded to
     */
    constructor (address payable wallet, PresaleChestGateway gatewayContract) public {
        require(wallet != address(0), "wallet is the zero address");
        require(address(gatewayContract) != address(0), "gateway contract is zero address");

        _gatewayContract = gatewayContract;
        _wallet = wallet;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    function () external payable {
        revert("can't send trx directly. Use buyChests()");
    }

    function addChest(uint256 chestId, PresaleChestToken tokenContract, uint256 cap, uint256 rate, uint256 maxPerAccount, ITRC20 paymentContract) public onlyOwner {
        Chest memory chest;
        chest.tokenContract = tokenContract;
        chest.rate = rate;
        chest.maxPerAccount = maxPerAccount;
        chest.paymentContract = paymentContract;
        chest.cap = cap;

        _chests[chestId] = chest;
    }

    function chestStatus(uint256 chestId) external view returns(address, uint256, uint256, uint256, uint256, uint256) {
        Chest memory chest = _chests[chestId];
        return (address(chest.tokenContract), chest.rate, chest.maxPerAccount, purchased[chestId][msg.sender], chest.purchased, chest.cap);
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function buyChestsWithToken(uint256 chestId, address referer, uint256 chests) public nonReentrant payable {
        Chest memory chest = _chests[chestId];
        require(chest.tokenContract != ITRC20(address(0)), "invalid chest id");
        require(chests > 0, "chests is 0");

        uint256 amount = chests.mul(chest.rate);
        // transfer from sender account to _wallet
        require(chest.paymentContract.allowance(msg.sender, address(this)) >= amount, "allowence low");

        _proceedPurchase(chests, chestId, referer);

        chest.paymentContract.transferFrom(msg.sender, _wallet, amount);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param chestId Id of the chest token
     */
    function buyChests(uint256 chestId, address referer) public nonReentrant payable {
        Chest memory chest = _chests[chestId];
        require(chest.tokenContract != ITRC20(address(0)), "invalid chest id");
        
        uint256 sunAmount = msg.value;
        require(sunAmount != 0, "sunAmount is 0");

        // calculate token amount to be created
        uint256 chests = sunAmount.div(chest.rate);

        require(chest.purchased.add(chests) <= chest.cap, "can't purchase over cap");

        _proceedPurchase(chests, chestId, referer);

        _wallet.transfer(msg.value);
    }

    function _proceedPurchase(uint256 chests, uint256 chestId, address referer) private {
        require(referer != msg.sender, "can't refer itself");

        address currentReferer = referrals[msg.sender];
        if (referer != address(0) && currentReferer == address(0)) {
            // save only first referee, this way 1 referer can have multiplie referees
            referrals[msg.sender] = referer;
            currentReferer = referer;
        }

        uint256 purchasedChests = purchased[chestId][msg.sender];

        require(purchasedChests+chests <= _chests[chestId].maxPerAccount, "can't purchase above limit");

        // update state
        purchased[chestId][msg.sender] = purchasedChests + chests;
        _chests[chestId].tokenContract.mint(msg.sender, chests);
        _chests[chestId].purchased += chests;
        emit ChestPurchased(msg.sender, currentReferer, chestId, chests);
    }
}
