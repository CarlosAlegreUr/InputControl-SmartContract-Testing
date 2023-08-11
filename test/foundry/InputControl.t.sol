// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../../lib/forge-std/src/Test.sol";

// Inheritance version
import {InputControl} from "../../contracts/InputControl.sol";
import {UseCaseContract} from "../../contracts/UseCaseContract.sol";

contract CounterTest is Test {
    address public ownerAddress = makeAddr("owner");
    UseCaseContract public c;
    InputControl inputC;

    function setUp() public {
        vm.startPrank(ownerAddress);
        c = new UseCaseContract();
    }

    function testIncrement() public {}
}
