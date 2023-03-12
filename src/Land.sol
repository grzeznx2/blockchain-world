// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Land is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Position {
        uint256 x;
        uint256 y;
    }

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(uint256 => Position) private positionById;
    mapping(address => uint256) private landHolders;

    constructor() ERC721("LAND", "LAND"){}

    function safeMint(uint256 _x, uint256 _y) external {
        require(_x <= GRID_SIZE && _x >= 0 && _y <= GRID_SIZE && _y >= 0, "LAND: invalid x or y");
        require(positions[_x][_y]==false,"Land: Land already taken");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        positions[_x][_y] = true;
        positionById[tokenId] = Position(_x, _y);
        landHolders[msg.sender] = tokenId;
        _safeMint(msg.sender, tokenId);
    }

    function getPositionById(uint256 landId) external view returns (Position memory){
        _requireMinted(landId);
        return positionById[landId];
    }
}
