pragma solidity >=0.4.24;

import "./ECDSA.sol";

contract PaymentGateway is ECDSA {
    address payable _owner;
    address _oracle;
    address payable _dividends;
    uint _rate;
    uint _nonce;
    uint _devCut;

    mapping(bytes32 => uint) _iaps;

    event Purchase(
        address indexed from,
        string paymentId
    );

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    modifier onlyOracle() {
        if (msg.sender == _oracle) _;
    }

    function setOracle(address oracle) public onlyOwner {
        _oracle = oracle;
    }

    function setDividends(address payable dividends) public onlyOwner {
        _dividends = dividends;
    }

    function setDevCut(uint devCut) public onlyOwner {
        _devCut = devCut;
    }

    function withdrawAll() public onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function () external payable {
        revert("can't sent trx directly. Use purchase()");
    }

    function purchase(string memory iap, string memory paymentId, uint price, bytes memory signature) public payable {
        bytes32 hash = keccak256(abi.encodePacked(iap, paymentId, price));
        bytes32 messageHash = toTronSignedMessageHash(hash);

        address signer = recover(messageHash, signature);
        require(signer == _oracle, "message is not signed by oracle");

        require(msg.value >= price, "not enough funds");

        // if too much sent - sent rest back
        if (msg.value > price) {
            uint exceedSun = msg.value - price;
            msg.sender.transfer(exceedSun);
        }

        require(_dividends != address(0), "dividends contract is not set");

        // send 100% - _devCut to dividends
        _dividends.transfer(price * (100 - _devCut) / 100);

        emit Purchase(msg.sender, paymentId);
    }
}