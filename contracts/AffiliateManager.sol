// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./bettoken.sol";  // Bettoken kontratınızı burada içe aktarın

contract AffiliateManager is Ownable(msg.sender), ReentrancyGuard, Pausable {
    uint public rewardAmount;
    Bettoken public bettoken;

    mapping(address => string) public affiliateCodes;
    mapping(string => address) public codeOwners;
    mapping(string => uint) public codeUsage;

    event AffiliateCodeCreated(address indexed affiliate, string code);
    event AffiliateCodeUpdated(address indexed affiliate, string oldCode, string newCode);
    event AffiliateCodeRemoved(address indexed affiliate, string code);
    event RewardSent(address indexed affiliate, uint amount);

    modifier onlyAffiliateManager() {
        require(msg.sender == owner(), "Only the affiliate manager can perform this action");
        _;
    }

    constructor(address payable _bettokenAddress, uint _rewardAmount) {
        bettoken = Bettoken(_bettokenAddress);
        rewardAmount = _rewardAmount;
        transferOwnership(bettoken.owner()); // AffiliateManager kontratının sahibini Bettoken sahibine ayarla
    }

    function createAffiliateCode(address _affiliate, string memory _code) public onlyAffiliateManager whenNotPaused {
        require(bytes(affiliateCodes[_affiliate]).length == 0, "Affiliate already has a code");
        require(codeOwners[_code] == address(0), "Code is already in use");

        affiliateCodes[_affiliate] = _code;
        codeOwners[_code] = _affiliate;

        emit AffiliateCodeCreated(_affiliate, _code);
    }

    function updateAffiliateCode(address _affiliate, string memory _newCode) public onlyAffiliateManager whenNotPaused {
        require(bytes(affiliateCodes[_affiliate]).length != 0, "Affiliate does not have a code");
        require(codeOwners[_newCode] == address(0), "New code is already in use");

        string memory oldCode = affiliateCodes[_affiliate];
        codeOwners[oldCode] = address(0); // Eski kodu sıfırla
        affiliateCodes[_affiliate] = _newCode;
        codeOwners[_newCode] = _affiliate;

        emit AffiliateCodeUpdated(_affiliate, oldCode, _newCode);
    }

    function removeAffiliateCode(address _affiliate) public onlyAffiliateManager whenNotPaused {
        require(bytes(affiliateCodes[_affiliate]).length != 0, "Affiliate does not have a code");

        string memory codeToRemove = affiliateCodes[_affiliate];
        delete affiliateCodes[_affiliate];
        delete codeOwners[codeToRemove];

        emit AffiliateCodeRemoved(_affiliate, codeToRemove);
    }

    function purchaseWithCode(string memory _code) public payable nonReentrant whenNotPaused {
        // Checks: Girdileri ve koşulları doğrulama
        address affiliate = codeOwners[_code];
        require(affiliate != address(0), "Invalid affiliate code");
        require(msg.value > 0, "Payment is required to purchase");

        // Effects: Durum değişkenlerini güncelleme
        codeUsage[_code] += 1; // Affiliate kodu kullanım sayısını artır

        // Interactions: Dış etkileşimleri gerçekleştirme (örneğin, fon transferi)
        (bool sent, ) = affiliate.call{value: rewardAmount}("");
        require(sent, "Failed to send reward to affiliate");

        emit RewardSent(affiliate, rewardAmount);
    }


    function setRewardAmount(uint _newRewardAmount) public onlyAffiliateManager whenNotPaused {
        require(_newRewardAmount <= address(this).balance, "Reward amount exceeds contract balance");
        rewardAmount = _newRewardAmount;
    }

    function getCodeUsage(string memory _code) public view returns (uint) {
        return codeUsage[_code];
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}
}
