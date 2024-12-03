// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

interface IBurrPool {
    function viewParameters()
        external
        view
        returns (
            uint256 alpha_,
            uint256 beta_,
            uint256 delta_,
            uint256 epsilon_,
            uint256 lambda_
        );

    function liquidity()
        external
        view
        returns (uint256 total_, uint256[] memory individual_);
    function assimilator(
        address _token
    ) external view returns (address assimilator_);

    function derivatives(uint256 index) external view returns (address);

    function viewDeposit(
        uint256 totalDepositNumeraire
    ) external view returns (uint256, uint256[] memory);

    function viewWithdraw(
        uint256 _curvesToBurn
    ) external view returns (uint256[] memory);
}

interface IAssimilator {
    function oracle() external returns (address);
    // assimilator getRate returns the oracle price (it calls IAggregator.latestAnswer())
    function getRate() external returns (uint256);
}

interface IAggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract BurrIntegrationTest is Test {
    IBurrPool burrPool;

    // pin to a specific block to make test faster to run
    uint256 constant BLOCK_NUMBER = 7628919;

    function setUp() public {
        vm.createSelectFork("https://bartio.rpc.berachain.com", BLOCK_NUMBER);

        address burrNectUsdc = 0x39FCa0A506d01ff9cb727FE8EDf088e10F6b431A;
        burrPool = IBurrPool(burrNectUsdc);
    }

    function test_burrInterface() public {
        console.log("burrPool", address(burrPool));
        // burr pool derivatives are the tokens in the pool
        // derivatives[0] is always the base token
        // derivatives[1] is always the quote token
        address baseToken = burrPool.derivatives(0);
        address quoteToken = burrPool.derivatives(1);
        console.log("baseToken", baseToken);
        console.log("quoteToken", quoteToken);

        address baseAssimilator = burrPool.assimilator(baseToken);
        address quoteAssimilator = burrPool.assimilator(quoteToken);
        console.log("baseAssimilator", baseAssimilator);
        console.log("quoteAssimilator", quoteAssimilator);

        uint256 baseRate = IAssimilator(baseAssimilator).getRate();
        uint256 quoteRate = IAssimilator(quoteAssimilator).getRate();
        console.log("baseRate", baseRate);
        console.log("quoteRate", quoteRate);

        address baseOracle = IAssimilator(baseAssimilator).oracle();
        address quoteOracle = IAssimilator(quoteAssimilator).oracle();
        console.log("baseOracle", baseOracle);
        console.log("quoteOracle", quoteOracle);

        (, int256 baseAnswer, , , ) = IAggregator(baseOracle).latestRoundData();
        (, int256 quoteAnswer, , , ) = IAggregator(quoteOracle)
            .latestRoundData();
        console.log("baseAnswer", baseAnswer);
        console.log("quoteAnswer", quoteAnswer);

        // liquidity is the total liquidity in the pool and the liquidity for each token
        // individual[0] is the liquidity for the base token
        // individual[1] is the liquidity for the quote token
        // liquidity is expressed in `numeraire` (in 18 decimals) which is the denominator unit
        // in the oracles - the vast majority of the time this will be USD value
        (uint256 total, uint256[] memory individual) = burrPool.liquidity();
        console.log("total", total);
        console.log("baseTokenLiquidity", individual[0]);
        console.log("quoteTokenLiquidity", individual[1]);

        (
            uint256 alpha,
            uint256 beta,
            uint256 delta,
            uint256 epsilon,
            uint256 lambda
        ) = burrPool.viewParameters();
        console.log("alpha", alpha);
        console.log("beta", beta);
        console.log("delta", delta);
        console.log("epsilon", epsilon);
        console.log("lambda", lambda);
    }
}
