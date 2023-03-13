// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Land is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum LandType {
        FIRST,
        SECOND,
        THIRD,
        FOURTH
    }

    struct Position {
        uint256 x;
        uint256 y;
    }

    struct BuildingLevels {
        uint256 building1;
        uint256 building2;
        uint256 building3;
    }

    struct LandStats {
        uint256 id;
        LandType landType;
        BuildingLevels buildigLevels;
        Position position;
    }

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(address => uint256) private landHolders;
    mapping(uint256 => LandStats) private landById;

    constructor() ERC721("LAND", "LAND"){}

    function safeMint(uint256 _x, uint256 _y, LandType landType) external {
        require(_x <= GRID_SIZE && _x >= 0 && _y <= GRID_SIZE && _y >= 0, "LAND: invalid x or y");
        require(positions[_x][_y]==false,"Land: Land already taken");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        positions[_x][_y] = true;
        landHolders[msg.sender] = tokenId;
        landById[tokenId] = LandStats(
            tokenId,
            landType,
            BuildingLevels(0,0,0),
            Position(_x,_y)
        );
        _safeMint(msg.sender, tokenId);
    }

    function getLandStatsById(uint256 landId) external view returns (LandStats memory){
        _requireMinted(landId);
        return landById[landId];
    }
}
