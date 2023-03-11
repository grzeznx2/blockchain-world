// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Land.sol";

contract LandTest is Test {
    Land public land;

    function setUp() public {
        land = new Land();
    }
}
