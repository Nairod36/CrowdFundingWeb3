// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/CROWDTKToken.sol";
import "../src/Campaign.sol";
import "../src/CROWD.sol";

contract MockExchangeToken is ERC20 {
    constructor() ERC20("Mock Exchange Token", "MET") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}

contract CampaignTest is Test {
    CROWD public crowdPlatform;
    Campaign public campaign;
    CROWDTKToken public crowdToken;
    MockExchangeToken public exchangeToken;
    address public owner;
    address public initiator;
    address public contributor1;
    address public contributor2;
    uint256 public campaignId;

    uint256 public constant INITIAL_SUPPLY = 1000000000;
    uint256 public constant PLATFORM_SUPPLY = 500000000;
    uint256 public constant MIN_TARGET = 1000;
    uint256 public constant MAX_TARGET = 5000;
    uint256 public constant CAMPAIGN_DURATION = 7 days;
    uint256 public constant EXCHANGE_RATE = 100;

    function setUp() public {
        owner = makeAddr("owner");
        vm.startPrank(owner);

        // Deploy tokens
        crowdToken = new CROWDTKToken();
        exchangeToken = new MockExchangeToken();

        uint256 decimals = 10 ** crowdToken.decimals();

        // Mint avec un plus grand supply
        crowdToken.mint(owner, INITIAL_SUPPLY * decimals);

        // Deploy platform
        crowdPlatform = new CROWD(crowdToken, exchangeToken);
        crowdToken.transfer(address(crowdPlatform), PLATFORM_SUPPLY * decimals);

        // Transfer de tokens d'échange à la plateforme
        exchangeToken.transfer(
            address(crowdPlatform),
            PLATFORM_SUPPLY * decimals
        );
        vm.stopPrank();

        // Setup addresses
        initiator = makeAddr("initiator");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");

        // Initial exchange tokens for contributor1
        vm.startPrank(owner);
        exchangeToken.transfer(
            contributor1,
            100000 * 10 ** exchangeToken.decimals()
        );
        vm.stopPrank();

        // Create campaign as initiator
        vm.startPrank(initiator);
        campaignId = crowdPlatform.createCampaign(
            MIN_TARGET * 10 ** crowdToken.decimals(),
            MAX_TARGET * 10 ** crowdToken.decimals(),
            block.timestamp,
            block.timestamp + CAMPAIGN_DURATION
        );
        vm.stopPrank();

        campaign = Campaign(address(crowdPlatform.campaigns(campaignId)));
    }

    function testInitialSetup() public view {
        assertEq(crowdToken.name(), "CROWDTK");
        assertEq(crowdToken.symbol(), "CTK");
        assertEq(
            crowdToken.balanceOf(address(crowdPlatform)),
            PLATFORM_SUPPLY * 10 ** crowdToken.decimals()
        );
        assertEq(crowdToken.owner(), owner);
    }

    function testTokenExchange() public {
        vm.startPrank(contributor1);

        uint256 exchangeAmount = 10 * 10 ** exchangeToken.decimals();
        uint256 expectedCrowdTokens = exchangeAmount * EXCHANGE_RATE;

        exchangeToken.approve(address(crowdPlatform), exchangeAmount);

        uint256 initialExchangeBalance = exchangeToken.balanceOf(contributor1);
        uint256 initialCrowdBalance = crowdToken.balanceOf(contributor1);

        crowdPlatform.exchangeTokens(exchangeAmount);

        assertEq(
            exchangeToken.balanceOf(contributor1),
            initialExchangeBalance - exchangeAmount,
            "Exchange tokens not deducted correctly"
        );
        assertEq(
            crowdToken.balanceOf(contributor1),
            initialCrowdBalance + expectedCrowdTokens,
            "CROWD tokens not received correctly"
        );

        vm.stopPrank();
    }

    function testClaimFunds() public {
        // Setup and accept campaign
        vm.prank(owner);
        crowdPlatform.acceptCampaign(campaignId);

        // Get tokens through exchange instead of ETH
        vm.startPrank(contributor1);
        uint256 exchangeAmount = (MIN_TARGET / EXCHANGE_RATE) *
            10 ** exchangeToken.decimals();
        exchangeToken.approve(address(crowdPlatform), exchangeAmount);
        crowdPlatform.exchangeTokens(exchangeAmount);

        uint256 contributionAmount = MIN_TARGET * 10 ** crowdToken.decimals();
        crowdToken.approve(address(campaign), contributionAmount);
        campaign.contribute(contributionAmount);
        vm.stopPrank();

        // Time travel past end date
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        // Claim funds as initiator
        uint256 initialBalance = crowdToken.balanceOf(initiator);
        vm.prank(initiator);
        campaign.claimFunds();

        // Verify claim
        assertEq(
            crowdToken.balanceOf(initiator),
            initialBalance + contributionAmount
        );
        assertTrue(campaign.isSuccess());
    }

    function testFailExchangeWithoutApproval() public {
        vm.prank(contributor1);
        crowdPlatform.exchangeTokens(10 * 10 ** exchangeToken.decimals());
    }

    function testRefundIfTargetNotMet() public {
        // Setup contribution
        vm.prank(owner);
        crowdPlatform.acceptCampaign(campaignId);

        // Contribute using exchanged tokens
        vm.startPrank(contributor1);

        // Utiliser un montant inférieur au MIN_TARGET
        uint256 smallAmount = ((MIN_TARGET / 2) *
            10 ** exchangeToken.decimals()) / EXCHANGE_RATE;
        exchangeToken.approve(address(crowdPlatform), smallAmount);
        crowdPlatform.exchangeTokens(smallAmount);

        uint256 contributionAmount = smallAmount * EXCHANGE_RATE;
        crowdToken.approve(address(campaign), contributionAmount);
        campaign.contribute(contributionAmount);

        // Time travel past end date
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        // Verify initial state
        uint256 initialBalance = crowdToken.balanceOf(contributor1);

        // Request refund
        campaign.refund();

        // Verify refund
        assertEq(
            crowdToken.balanceOf(contributor1),
            initialBalance + contributionAmount,
            "Refund amount incorrect"
        );
        assertEq(
            campaign.contributions(contributor1),
            0,
            "Contribution not reset"
        );
        vm.stopPrank();
    }

    function testWithdrawExchangeTokens() public {
        // Transfer initial tokens to platform
        vm.startPrank(owner);
        uint256 platformInitialBalance = 1000 * 10 ** exchangeToken.decimals();
        exchangeToken.transfer(address(crowdPlatform), platformInitialBalance);
        vm.stopPrank();

        // Faire un échange d'abord
        vm.startPrank(contributor1);
        uint256 exchangeAmount = 10 * 10 ** exchangeToken.decimals();
        exchangeToken.approve(address(crowdPlatform), exchangeAmount);
        crowdPlatform.exchangeTokens(exchangeAmount);
        vm.stopPrank();

        // Retirer les tokens en tant que owner
        uint256 initialOwnerBalance = exchangeToken.balanceOf(owner);
        uint256 platformBalance = exchangeToken.balanceOf(
            address(crowdPlatform)
        );

        vm.prank(owner);
        crowdPlatform.withdrawExchangeTokens();

        assertEq(
            exchangeToken.balanceOf(owner),
            initialOwnerBalance + platformBalance,
            "Exchange tokens not withdrawn correctly"
        );
        assertEq(
            exchangeToken.balanceOf(address(crowdPlatform)),
            0,
            "Platform balance should be 0 after withdrawal"
        );
    }

    function testFailContributeAfterEndDate() public {
        vm.prank(owner);
        crowdPlatform.acceptCampaign(campaignId);

        // Time travel past end date
        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        vm.startPrank(contributor1);
        uint256 exchangeAmount = 10 * 10 ** exchangeToken.decimals();
        exchangeToken.approve(address(crowdPlatform), exchangeAmount);
        crowdPlatform.exchangeTokens(exchangeAmount);

        crowdToken.approve(address(campaign), exchangeAmount * EXCHANGE_RATE);
        campaign.contribute(exchangeAmount * EXCHANGE_RATE);
    }
}
