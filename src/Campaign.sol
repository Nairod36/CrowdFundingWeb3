// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CROWDTKToken.sol";

contract Campaign {
    address public initiator;
    IERC20 public token;
    uint256 public tokenTargetMinAmount;
    uint256 public tokenTargetMaxAmount;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public totalFunds;
    bool public isSuccess;

    mapping(address => uint256) public contributions;

    enum Status {
        Pending,
        Accepted,
        Rejected
    }
    Status public status;

    modifier onlyInitiator() {
        require(msg.sender == initiator, "Only initiator can claim funds");
        _;
    }

    constructor(
        address _initiator,
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate,
        IERC20 _token
    ) {
        initiator = _initiator;
        tokenTargetMinAmount = _tokenTargetMinAmount;
        tokenTargetMaxAmount = _tokenTargetMaxAmount;
        startDate = _startDate;
        endDate = _endDate;
        token = _token;
        status = Status.Pending;
    }

    function acceptCampaign() public {
        require(status == Status.Pending, "Campaign already reviewed");
        status = Status.Accepted;
    }

    function contribute(uint256 _amount) public {
        require(status == Status.Accepted, "Campaign not accepted");
        require(
            block.timestamp >= startDate && block.timestamp <= endDate,
            "Campaign not active"
        );
        require(
            totalFunds + _amount <= tokenTargetMaxAmount,
            "Exceeds target max amount"
        );

        token.transferFrom(msg.sender, address(this), _amount);
        contributions[msg.sender] += _amount;
        totalFunds += _amount;
    }

    function claimFunds() public onlyInitiator {
        require(
            block.timestamp > endDate || totalFunds >= tokenTargetMaxAmount,
            "Campaign still active"
        );
        require(totalFunds >= tokenTargetMinAmount, "Target not met");

        token.transfer(initiator, totalFunds);
        isSuccess = true;
    }

    function refund() public {
        require(totalFunds < tokenTargetMinAmount, "Target met, no refunds");
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        token.transfer(msg.sender, contribution);
    }
}
