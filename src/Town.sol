// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Town is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _buildingIdCounter;

    enum BuildingType {
        GOLD_MINE,
        DIAMOND_MINE,
        ROCK_MINE,
        LUMBER_MILL
    }

    enum TownType {
        FIRST,
        SECOND,
        THIRD,
        FOURTH
    }

    enum Resource {
        GOLD,
        WOOD,
        ROCK,
        DIAMOND
    }

    struct Position {
        uint256 x;
        uint256 y;
    }

    struct RequiredBuildingLevel {
        uint256 level;
        BuildingType buildingType;
    }

    struct ResourceCost {
        uint256 gold;
        uint256 wood;
        uint256 rock;
        uint256 diamond;
    }

    struct Building {
        BuildingType buildingType;
        TownType townType;
        uint256[] requiredBuildingLevels;
        uint256 maxLevel;
        string name;
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

    struct TownSchema {
        TownType townType;
        mapping(BuildingType => Building) buildings;
    }

    mapping(uint256 => RequiredBuildingLevel[]) public requiredBuildingLevelsMap;
    uint256 requiredBuildingLevelsId;

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(address => uint256) private townHolders;
    mapping(uint256 => TownStats) private townById;
    mapping(TownType => TownStats) private initialTownStatsByType;
    mapping(TownType => TownSchema) private townSchemaByTownType;

    constructor() ERC721("TOWN", "TOWN"){
    }

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

    function addBuilding(BuildingType buildingType, TownType townType, uint256 maxLevel, RequiredBuildingLevel[][] memory rbl) public {
        Building storage building = townSchemaByTownType[townType].buildings[buildingType];
        building.buildingType = buildingType;
        building.townType = townType;
        building.maxLevel = maxLevel;

        uint256 rblLength = rbl.length;

        for(uint256 i; i < rblLength; i++){
            uint256 length = rbl[i].length;
            building.requiredBuildingLevels.push(requiredBuildingLevelsId);
                for(uint256 j; j < length; j++){
                    RequiredBuildingLevel memory newRBL = RequiredBuildingLevel(rbl[i][j].level, rbl[i][j].buildingType);
                    requiredBuildingLevelsMap[requiredBuildingLevelsId].push(newRBL);
                }
            requiredBuildingLevelsId++;
        }
    }

    function getBuildingFromSchema(BuildingType buildingType, TownType townType) public view returns (Building memory){
        return townSchemaByTownType[townType].buildings[buildingType];
    }
}
