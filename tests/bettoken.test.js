const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Bettoken Contract", function () {
  let Bettoken, bettoken, owner, addr1, addr2;

  beforeEach(async function () {
    Bettoken = await ethers.getContractFactory("Bettoken");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    bettoken = await Bettoken.deploy();
    await bettoken.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await bettoken.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply to the contract itself", async function () {
      const totalSupply = await bettoken.TOTAL_SUPPLY();
      expect(await bettoken.balanceOf(bettoken.address)).to.equal(totalSupply);
    });
  });

  describe("Whitelist Functions", function () {
    it("Should allow owner to add to whitelist", async function () {
      await bettoken.addToWhitelist(addr1.address);
      expect(await bettoken.isWhitelisted(addr1.address)).to.be.true;
    });

    it("Should not allow non-owner to add to whitelist", async function () {
      await expect(
        bettoken.connect(addr1).addToWhitelist(addr2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow owner to remove from whitelist", async function () {
      await bettoken.addToWhitelist(addr1.address);
      await bettoken.removeFromWhitelist(addr1.address);
      expect(await bettoken.isWhitelisted(addr1.address)).to.be.false;
    });
  });

  describe("Private Sale", function () {
    beforeEach(async function () {
      await bettoken.addToWhitelist(addr1.address);
    });

    it("Should allow whitelisted address to buy tokens in private sale", async function () {
      await bettoken.connect(addr1).buyTokensPrivateSale(ethers.utils.parseUnits("1000", 18), "");
      expect(await bettoken.balanceOf(addr1.address)).to.be.gt(0);
    });

    it("Should not allow non-whitelisted address to buy tokens in private sale", async function () {
      await expect(
        bettoken.connect(addr2).buyTokensPrivateSale(ethers.utils.parseUnits("1000", 18), "")
      ).to.be.revertedWith("Address not whitelisted");
    });
  });

  describe("Staking", function () {
    beforeEach(async function () {
      await bettoken.transfer(addr1.address, ethers.utils.parseUnits("1000", 18));
    });

    it("Should allow user to stake tokens", async function () {
      await bettoken.connect(addr1).approve(bettoken.address, ethers.utils.parseUnits("500", 18));
      await bettoken.connect(addr1).stakeTokens(ethers.utils.parseUnits("500", 18));
      expect(await bettoken.stakes(addr1.address)).to.equal(ethers.utils.parseUnits("500", 18));
    });

    it("Should not allow staking more tokens than balance", async function () {
      await expect(
        bettoken.connect(addr1).stakeTokens(ethers.utils.parseUnits("2000", 18))
      ).to.be.revertedWith("Invalid or insufficient balance to stake");
    });
  });

  describe("Emergency Pause", function () {
    it("Should allow owner to pause and unpause the contract", async function () {
      await bettoken.emergencyPause();
      expect(await bettoken.paused()).to.be.true;
      await bettoken.unpause();
      expect(await bettoken.paused()).to.be.false;
    });

    it("Should not allow non-owner to pause the contract", async function () {
      await expect(bettoken.connect(addr1).emergencyPause()).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Withdraw Functions", function () {
    it("Should allow owner to withdraw tokens from the contract", async function () {
      const contractBalance = await bettoken.balanceOf(bettoken.address);
      await bettoken.withdrawTokens(ethers.utils.parseUnits("1000", 18));
      expect(await bettoken.balanceOf(owner.address)).to.equal(ethers.utils.parseUnits("1000", 18));
      expect(await bettoken.balanceOf(bettoken.address)).to.equal(contractBalance.sub(ethers.utils.parseUnits("1000", 18)));
    });

    it("Should not allow non-owner to withdraw tokens", async function () {
      await expect(bettoken.connect(addr1).withdrawTokens(ethers.utils.parseUnits("1000", 18))).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});