// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract NFTFacet is ERC721A {
    error MintPriceNotPaid();
    error NonExistentTokenURI();
    error WithdrawTransfer();

    event PermanentURI(string _value, uint256 indexed _id);

    uint256 public constant MINT_PRICE = 1 ether;

    string internal baseTokenURI;
    string public unrevealedURI;
    bool public revealed = false;

    constructor() ERC721A("PlanetAmor", "AMOR") {}

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function mint(uint256 quantity) external payable {
        if (msg.value < MINT_PRICE * quantity) revert MintPriceNotPaid();
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentTokenURI();

        string memory currentBaseURI = _baseURI();
        return revealed
            ? bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
                : ""
            : unrevealedURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawTransfer();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    // Required overrides from ERC721A
    function name() public pure override returns (string memory) {
        return "PlanetAmor";
    }

    function symbol() public pure override returns (string memory) {
        return "AMOR";
    }
}
