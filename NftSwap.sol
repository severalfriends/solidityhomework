// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSwap {
    struct Order {
        address owner;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Order)) public orders;

    event Listed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed owner
    );

    event Revoked(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner
    );

    event Purchased(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer
    );

    modifier checkOwner(address nftAddress, uint256 tokenId) {
        Order memory order = orders[nftAddress][tokenId];
        require(
            order.owner == msg.sender,
            "You are not the owner of this order"
        );
        _;
    }

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this NFT");

        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
                nft.getApproved(tokenId) == address(this),
            "Approve this contract to handle your NFT"
        );

        orders[nftAddress][tokenId] = Order({owner: msg.sender, price: price});
        emit Listed(nftAddress, tokenId, price, msg.sender);
    }

    function revokeNFT(
        address nftAddress,
        uint256 tokenId
    ) external checkOwner(nftAddress, tokenId) {
        delete orders[nftAddress][tokenId];
        emit Revoked(nftAddress, tokenId, msg.sender);
    }

    function updatePrice(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external checkOwner(nftAddress, tokenId) {
        Order memory order = orders[nftAddress][tokenId];
        order.price = newPrice;
        emit Listed(nftAddress, tokenId, newPrice, msg.sender);
    }

    function purchaseNFT(address nftAddress, uint256 tokenId) external payable {
        Order memory order = orders[nftAddress][tokenId];
        require(order.owner != address(0), "Order does not exist");

        require(msg.value == order.price, "incorrect price");
        IERC721 nft = IERC721(nftAddress);

        require(
            nft.ownerOf(tokenId) == order.owner,
            "seller no longer owns this NFT"
        );

        delete order;
        payable(order.owner).transfer(msg.value);
        nft.safeTransferFrom(order.owner, msg.sender, tokenId);
        emit Purchased(nftAddress, tokenId, order.price, msg.sender);
    }

    receive() external payable {}
}
