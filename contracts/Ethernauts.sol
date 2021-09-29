//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Ethernauts is ERC721Enumerable, Ownable {
    using Address for address payable;

    // Can be set only once on deploy
    uint public immutable maxTokens;
    uint public immutable maxGiftable;

    // Can be changed by owner
    string public baseTokenURI;
    uint public mintPrice;
    uint public earlyMintPrice;
    address public couponSigner;

    // Internal usage
    uint private _tokensGifted;
    mapping(address => bool) private _redeemedCoupons;

    // Three different sale stages:
    enum SaleState {
        Paused, // No one can mint, except the owner via gifting (default)
        Early, // Only community can mint, at a discount using signed messages
        Open // Anyone can mint
    }
    SaleState public currentSaleState;

    constructor(
        uint definitiveMaxGiftable,
        uint definitiveMaxTokens,
        uint initialMintPrice,
        uint initialEarlyMintPrice,
        address initialCouponSigner
    ) ERC721("Ethernauts", "NAUTS") {
        require(definitiveMaxGiftable <= 100, "Max giftable supply too large");
        require(definitiveMaxTokens <= 10000, "Max token supply too large");

        maxGiftable = definitiveMaxGiftable;
        maxTokens = definitiveMaxTokens;
        mintPrice = initialMintPrice;
        earlyMintPrice = initialEarlyMintPrice;
        couponSigner = initialCouponSigner;

        currentSaleState = SaleState.Paused;
    }

    // ----------
    // Modifiers
    // ----------

    modifier onlyOnState(SaleState definedSaleState) {
        require(currentSaleState == definedSaleState, "Not allowed in current state");
        _;
    }

    // --------------------
    // Public external ABI
    // --------------------

    function mint() external payable onlyOnState(SaleState.Open) {
        require(msg.value >= mintPrice, "Invalid msg.value");
        require(availableToMint() > 0, "No available supply");

        _mintNext(msg.sender);
    }

    function mintEarly(bytes memory signedCoupon) external payable onlyOnState(SaleState.Early) {
        require(msg.value >= earlyMintPrice, "Invalid msg.value");
        require(availableToMint() > 0, "No available supply");
        require(!userRedeemedCoupon(msg.sender), "Used coupon");
        require(isCouponSignedForUser(msg.sender, signedCoupon), "Invalid coupon");

        _mintNext(msg.sender);

        _redeemedCoupons[msg.sender] = true;
    }

    function tokensGifted() public view returns (uint) {
        return _tokensGifted;
    }

    function availableSupply() public view returns (uint) {
        return maxTokens - totalSupply();
    }

    function availableToMint() public view returns (uint) {
        return availableSupply() - availableToGift();
    }

    function availableToGift() public view returns (uint) {
        return maxGiftable - _tokensGifted;
    }

    function exists(uint tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function isCouponSignedForUser(address user, bytes memory coupon) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(messageHash);

        address retrievedSigner = ECDSA.recover(prefixedHash, coupon);

        return couponSigner == retrievedSigner;
    }

    function userRedeemedCoupon(address user) public view returns (bool) {
        return _redeemedCoupons[user];
    }

    // -----------------------
    // Protected external ABI
    // -----------------------

    function gift(address to) external onlyOwner {
        require(_tokensGifted < maxGiftable, "No more Ethernauts can be gifted");

        _mintNext(to);

        _tokensGifted += 1;
    }

    function setMintPrice(uint newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setEarlyMintPrice(uint newEarlyMintPrice) external onlyOwner {
        earlyMintPrice = newEarlyMintPrice;
    }

    function setBaseURI(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function setSaleState(SaleState newSaleState) external onlyOwner {
        require(newSaleState != currentSaleState, "Invalid new state");

        currentSaleState = newSaleState;
    }

    function setCouponSigner(address newCouponSigner) external onlyOwner {
        couponSigner = newCouponSigner;
    }

    function withdraw(address payable beneficiary) external onlyOwner {
        beneficiary.sendValue(address(this).balance);
    }

    // -------------------
    // Private functions
    // -------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _mintNext(address to) private {
        uint tokenId = totalSupply();

        _mint(to, tokenId);
    }

    function _mint(address to, uint tokenId) internal virtual override {
        require(totalSupply() < maxTokens, "No available supply");

        super._mint(to, tokenId);
    }
}
