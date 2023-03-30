// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Town.sol";

contract TownTest is Test {
    Town public town;

    function setUp() public {
        town = new Town();
    }
}
