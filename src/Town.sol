// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Town is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _buildingTypeIdCounter;
    Counters.Counter private _townTypeIdCounter;
    Counters.Counter private _unitTypeIdCounter;
    Counters.Counter private _createUnitDataIdCounter;
    Counters.Counter private _requiredBuildingLevelsIdCounter;

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

    struct CreateUnitData {
        uint256 unitTypeId;
        uint256 townTypeId;
        uint256 growthRate;
    }

    struct RequiredBuildingLevel {
        uint256 level;
        uint256 buildingTypeId;
    }

    struct ResourcesAmount {
        uint256 gold;
        uint256 wood;
        uint256 rock;
        uint256 diamond;
    }

    struct Unit {
        uint256 unitTypeId;
        uint256 townTypeId;
        uint256 defense;
        uint256 attack;
        uint256 health;
        uint256 speed;
        ResourcesAmount resourceCost;
        string name;
    }

    struct CreateUnitArgs {
        uint256 unitTypeId;
        uint256 townTypeId;
        uint256 defense;
        uint256 attack;
        uint256 health;
        uint256 speed;
        ResourcesAmount resourceCost;
        string name;
    }

    struct Building {
        uint256 buildingTypeId;
        uint256 townTypeId;
        uint256[] requiredBuildingLevels;
        ResourcesAmount[] requiredResourceCostLevels;
        ResourcesAmount[] resourcesProducedPerLevel;
        uint256[] createUnitDataPerLevel;
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
        mapping(uint256 => Building) buildings;
        mapping(uint256 => Unit) units;
    }

    mapping(uint256 => RequiredBuildingLevel[]) public requiredBuildingLevelMap;
    mapping(uint256 => CreateUnitData[]) public createUnitDataPerLevelMap;

    uint256 public GRID_SIZE = 999;
    mapping(uint256 => mapping(uint256 => bool)) private positions;
    mapping(address => uint256) private townHolders;
    mapping(uint256 => TownStats) private townById;
    mapping(TownType => TownStats) private initialTownStatsByType;
    mapping(uint256 => TownSchema) private townSchemaByTownId;
    uint256[] public townTypeIds;
    uint256[] public buildingTypeIds;
    uint256[] public unitTypeIds;
    mapping(uint256 => string) public townTypeById;
    mapping(uint256 => bool) public townTypeExists;
    mapping(uint256 => string) public buildingTypeById;
    mapping(uint256 => bool) public buildingTypeExists;
    mapping(uint256 => string) public unitTypeById;
    mapping(uint256 => bool) public unitTypeExists;


    constructor() ERC721("TOWN", "TOWN"){
    }

    function requireTownType(uint256 _townTypeId) public view {
        require(townTypeExists[_townTypeId], "Town: Town type does not exist");
    }

    function requireBuildingType(uint256 _buildingTypeId) public view {
        require(buildingTypeExists[_buildingTypeId], "Town: Building type does not exist");
    }

    function requireUnitType(uint256 _unitTypeId) public view {
        require(unitTypeExists[_unitTypeId], "Town: Unit type does not exist");
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

    function addBuilding
            (string calldata _name, uint256 _initialLevel, uint256 _buildingTypeId, uint256 _townTypeId, uint256 maxLevel,
            RequiredBuildingLevel[][] memory rbl, CreateUnitData[][] memory _createUnitDataPerLevel, ResourcesAmount[] memory _resourceCostLevels, ResourcesAmount[] memory _resourcesProducedPerLevel)
        public {
        requireTownType(_townTypeId);
        requireBuildingType(_buildingTypeId);

        Building storage building = townSchemaByTownId[_townTypeId].buildings[_buildingTypeId];
        building.buildingTypeId = _buildingTypeId;
        building.townTypeId = _townTypeId;
        building.maxLevel = maxLevel;
        building.initialLevel = _initialLevel;
        building.name = _name;

        uint256 rblLength = rbl.length;

        for(uint256 i; i < rblLength; i++){
            uint256 length = rbl[i].length;
            building.requiredResourceCostLevels.push(_resourceCostLevels[i]);
            building.resourcesProducedPerLevel.push(_resourcesProducedPerLevel[i]);
            uint256 requiredBuildingLevelsId = _requiredBuildingLevelsIdCounter.current();
            _requiredBuildingLevelsIdCounter.increment();
            building.requiredBuildingLevels.push(requiredBuildingLevelsId);
                for(uint256 j; j < length; j++){
                    // TODO: check if building type exists
                    RequiredBuildingLevel memory newRBL = RequiredBuildingLevel(rbl[i][j].level, rbl[i][j].buildingTypeId);
                    requiredBuildingLevelMap[requiredBuildingLevelsId].push(newRBL);
                }
        }

        uint256 createUnitDataPerLevelLength = _createUnitDataPerLevel.length;

        for(uint256 i; i < createUnitDataPerLevelLength; i++){
            uint256 createUnitDataId = _createUnitDataIdCounter.current();
            _createUnitDataIdCounter.increment();
            uint256 length = _createUnitDataPerLevel[i].length;
            building.createUnitDataPerLevel.push(createUnitDataId);
                for(uint256 j; j < length; j++){
                    // TODO: check if unit type exists
                    // TODO: check if town type exists
                    CreateUnitData memory createUnitData = CreateUnitData(_createUnitDataPerLevel[i][j].unitTypeId, _createUnitDataPerLevel[i][j].townTypeId, _createUnitDataPerLevel[i][j].growthRate);
                    createUnitDataPerLevelMap[createUnitDataId].push(createUnitData);
                }
        }
    }

    function getBuildingFromSchema(uint256 _buildingTypeId, uint256 _townTypeId) public view returns (Building memory){
        return townSchemaByTownId[_townTypeId].buildings[_buildingTypeId];
    }

    function addUnit(CreateUnitArgs memory args) public {
        requireTownType(args.townTypeId);
        requireUnitType(args.unitTypeId);
       
        townSchemaByTownId[args.townTypeId].units[args.unitTypeId] = Unit(
            args.unitTypeId,
            args.townTypeId,
            args.defense,
            args.attack,
            args.health,
            args.speed,
            args.resourceCost,
            args.name
        );
    }

     function getUnitFromSchema(uint256 _unitTypeId, uint256 _townTypeId) public view returns (Unit memory){
        return townSchemaByTownId[_townTypeId].units[_unitTypeId];
    }

    function addTownType(string calldata _townType) public {
        uint256 townTypeId = _townTypeIdCounter.current();
        _townTypeIdCounter.increment();
        townTypeIds.push(townTypeId);
        townTypeById[townTypeId] = _townType;
        townTypeExists[townTypeId] = true;
    }

    function addTownTypes(string[] calldata _townTypes) public {
        uint256 length = _townTypes.length;
        for(uint256 i; i < length; i++){
            addTownType(_townTypes[i]);
        }
    }

    function addBuildingType(string calldata _buildingType) public {
        uint256 buildingTypeId = _buildingTypeIdCounter.current();
        _buildingTypeIdCounter.increment();
        buildingTypeIds.push(buildingTypeId);
        buildingTypeById[buildingTypeId] = _buildingType;
        buildingTypeExists[buildingTypeId] = true;
    }

    function addBuildingTypes(string[] calldata _buildingTypes) public {
        uint256 length = _buildingTypes.length;
        for(uint256 i; i < length; i++){
            addBuildingType(_buildingTypes[i]);
        }
    }

    function addUnitType(string calldata _unitType) public {
        uint256 unitTypeId = _unitTypeIdCounter.current();
        _unitTypeIdCounter.increment();
        unitTypeIds.push(unitTypeId);
        unitTypeById[unitTypeId] = _unitType;
        unitTypeExists[unitTypeId] = true;
    }

    function addUnitTypes(string[] calldata _unitTypes) public {
        uint256 length = _unitTypes.length;
        for(uint256 i; i < length; i++){
            addUnitType(_unitTypes[i]);
        }
    }

    function getAllTownNames() public view returns (string[] memory){
        uint256 length = townTypeIds.length;
        string[] memory townNames = new string[](length);
        for(uint256 i; i < length; i++){
            townNames[i] = townTypeById[townTypeIds[i]];
        }
        return townNames;
    }
    
}
