// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Town is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum TownType {
        FIRST,
        SECOND,
        THIRD,
        FOURTH
    }

    struct Position {
        uint256 x;
        uint256 y;
    }

    struct RequiredBuildingLevel {
        uint256 id;
        uint256 level;
    }

    struct BaseBuildingProps {
        uint256 id;
        uint256 level;
        uint256 maxLevel;
        RequiredBuildingLevel[] requiredBuildingsPerLevel;
        uint256[] costPerLevel;
        string name;
    }

    struct Building {
        BaseBuildingProps base;
    }

    struct BuildingLevels {
        uint256 building1;
        uint256 building2;
        uint256 building3;
    }

    struct TownStats {
        uint256 id;
        TownType townType;
        BuildingLevels buildigLevels;
        Position position;
    }

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(address => uint256) private townHolders;
    mapping(uint256 => TownStats) private townById;

    constructor() ERC721("TOWN", "TOWN"){}

    function safeMint(uint256 _x, uint256 _y, TownType townType) external {
        require(_x <= GRID_SIZE && _x >= 0 && _y <= GRID_SIZE && _y >= 0, "TOWN: invalid x or y");
        require(positions[_x][_y]==false,"Town: Town already taken");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        positions[_x][_y] = true;
        townHolders[msg.sender] = tokenId;
        townById[tokenId] = TownStats(
            tokenId,
            townType,
            BuildingLevels(0,0,0),
            Position(_x,_y)
        );
        _safeMint(msg.sender, tokenId);
    }

    function getTownStatsById(uint256 townId) external view returns (TownStats memory){
        _requireMinted(townId);
        return townById[townId];
    }
}
