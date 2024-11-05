// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CROWDTKToken.sol";
import "./Campaign.sol";

contract CROWD {
    address public owner;
    CROWDTKToken public crowdToken;
    IERC20 public exchangeToken; // Le token contre lequel on échange
    uint256 public campaignCounter;
    mapping(uint256 => Campaign) public campaigns;

    // Nouveau taux d'échange: 1 token exchange = 100 CROWDTK
    uint256 public constant EXCHANGE_RATE = 100;

    event TokensExchanged(
        address indexed user,
        uint256 exchangeTokenAmount,
        uint256 crowdTokenAmount
    );
    event CampaignCreated(uint256 indexed campaignId, address campaignAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(CROWDTKToken _crowdToken, IERC20 _exchangeToken) {
        owner = msg.sender;
        crowdToken = _crowdToken;
        exchangeToken = _exchangeToken;
    }

    // Nouvelle fonction pour échanger des tokens
    function exchangeTokens(uint256 exchangeTokenAmount) public {
        require(exchangeTokenAmount > 0, "Amount must be greater than 0");
        uint256 crowdTokenAmount = exchangeTokenAmount * EXCHANGE_RATE;

        // Vérifier que le contrat a assez de CROWDTK tokens
        require(
            crowdToken.balanceOf(address(this)) >= crowdTokenAmount,
            "Insufficient CROWDTK token reserve"
        );

        // Transférer les tokens d'échange au contrat
        require(
            exchangeToken.transferFrom(
                msg.sender,
                address(this),
                exchangeTokenAmount
            ),
            "Exchange token transfer failed"
        );

        // Transférer les CROWDTK tokens à l'utilisateur
        require(
            crowdToken.transfer(msg.sender, crowdTokenAmount),
            "CROWDTK token transfer failed"
        );

        emit TokensExchanged(msg.sender, exchangeTokenAmount, crowdTokenAmount);
    }

    // Fonction pour retirer les tokens d'échange
    function withdrawExchangeTokens() public onlyOwner {
        uint256 balance = exchangeToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(exchangeToken.transfer(owner, balance), "Transfer failed");
    }

    function createCampaign(
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate
    ) public returns (uint256) {
        require(
            _startDate >= block.timestamp,
            "Start date must be in the future"
        );
        require(_endDate > _startDate, "End date must be after start date");

        campaignCounter++;
        Campaign newCampaign = new Campaign(
            msg.sender,
            _tokenTargetMinAmount,
            _tokenTargetMaxAmount,
            _startDate,
            _endDate,
            crowdToken
        );
        campaigns[campaignCounter] = newCampaign;

        emit CampaignCreated(campaignCounter, address(newCampaign));
        return campaignCounter;
    }

    function acceptCampaign(uint256 _campaignId) public onlyOwner {
        Campaign campaign = campaigns[_campaignId];
        campaign.acceptCampaign();
    }
}
