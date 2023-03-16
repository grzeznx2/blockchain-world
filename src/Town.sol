// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Town is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _buildingIdCounter;
    Counters.Counter private _townTypeIdCounter;

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

    enum Feature {
        CREATE_UNITS
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
        uint256 townTypeId;
        uint256[] requiredBuildingLevels;
        ResourceCost[] requiredResourceCostLevels;
        uint256 maxLevel;
        uint256 initialLevel;
        string name;
    }

    struct BuildingLevels {
        uint256 building1;
        uint256 building2;
        uint256 building3;
    }

    struct TownStats {
        uint256 id;
        uint256 townTypeId;
        BuildingLevels buildigLevels;
        Position position;
    }

    struct TownSchema {
        string townType;
        mapping(BuildingType => Building) buildings;
    }

    mapping(uint256 => RequiredBuildingLevel[]) public requiredBuildingLevelsMap;
    uint256 requiredBuildingLevelsId;

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(address => uint256) private townHolders;
    mapping(uint256 => TownStats) private townById;
    mapping(TownType => TownStats) private initialTownStatsByType;
    mapping(uint256 => TownSchema) private townSchemaByTownId;
    mapping(uint256 => string) private townTypeById;
    mapping(uint256 => bool) private townTypeExists;


    constructor() ERC721("TOWN", "TOWN"){
    }

    function requireTownType(uint256 _townTypeId) public view {
        require(townTypeExists[_townTypeId], "Town: Town type does not exist");
    }

    function safeMint(uint256 _x, uint256 _y, uint256 _townTypeId) external {
        requireTownType(_townTypeId);
        require(_x <= GRID_SIZE && _x >= 0 && _y <= GRID_SIZE && _y >= 0, "TOWN: invalid x or y");
        require(positions[_x][_y]==false,"Town: Town already taken");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        positions[_x][_y] = true;
        townHolders[msg.sender] = tokenId;
        townById[tokenId] = TownStats(
            tokenId,
            _townTypeId,
            BuildingLevels(0,0,0),
            Position(_x,_y)
        );
        _safeMint(msg.sender, tokenId);
    }

    function getTownStatsById(uint256 townId) external view returns (TownStats memory){
        _requireMinted(townId);
        return townById[townId];
    }

    function addBuilding(string calldata _name, uint256 _initialLevel, BuildingType buildingType, uint256 _townTypeId, uint256 maxLevel, RequiredBuildingLevel[][] memory rbl, ResourceCost[] memory _resourceCostLevels) public {
        requireTownType(_townTypeId);
        Building storage building = townSchemaByTownId[_townTypeId].buildings[buildingType];
        building.buildingType = buildingType;
        building.townTypeId = _townTypeId;
        building.maxLevel = maxLevel;
        building.initialLevel = _initialLevel;
        building.name = _name;

        uint256 rblLength = rbl.length;

        for(uint256 i; i < rblLength; i++){
            uint256 length = rbl[i].length;
            building.requiredResourceCostLevels.push(_resourceCostLevels[i]);
            building.requiredBuildingLevels.push(requiredBuildingLevelsId);
                for(uint256 j; j < length; j++){
                    RequiredBuildingLevel memory newRBL = RequiredBuildingLevel(rbl[i][j].level, rbl[i][j].buildingType);
                    requiredBuildingLevelsMap[requiredBuildingLevelsId].push(newRBL);
                }
            requiredBuildingLevelsId++;
        }
    }

    function getBuildingFromSchema(BuildingType buildingType, uint256 _townTypeId) public view returns (Building memory){
        return townSchemaByTownId[_townTypeId].buildings[buildingType];
    }

    function addTownType(string calldata _townType) public {
        uint256 townTypeId = _townTypeIdCounter.current();
        _townTypeIdCounter.increment();
        townTypeById[townTypeId] = _townType;
        townTypeExists[townTypeId] = true;
    }

    function addTownTypes(string[] calldata _townTypes) public {
        uint256 length = _townTypes.length;
        for(uint256 i; i < length; i++){
            addTownType(_townTypes[i]);
        }
    }
}
