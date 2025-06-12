const hre = require("hardhat");
const { ethers } = hre;
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ClaimERC20 Check Test on Sepolia", () => {
    let daoCommittee;
    let daoVault;
    let ton;
    let wton;
    let daoAgendaManager;
    let owner;
    let user1;

    const TON_ADDRESS = "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044";
    const WTON_ADDRESS = "0x79e0d92670106c85e9067b56b8f674340dca0bbd";
    const DAO_VAULT_ADDRESS = "0xB9F6c9E75418D7E5a536ADe08f0218196BB3eBa4";
    const DAO_AGENDA_MANAGER_ADDRESS = "0x1444f7a8bC26a3c9001a13271D56d6fF36B44f08";
    const DAO_COMMITTEE_PROXY_ADDRESS = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";

    before(async () => {
        [owner, user1] = await ethers.getSigners();

        // Contract instances
        daoCommittee = await ethers.getContractAt("DAOCommittee_V3", DAO_COMMITTEE_PROXY_ADDRESS);
        daoVault = await ethers.getContractAt("DAOVault", DAO_VAULT_ADDRESS);
        ton = await ethers.getContractAt("TON", TON_ADDRESS);
        wton = await ethers.getContractAt("WTON", WTON_ADDRESS);
        daoAgendaManager = await ethers.getContractAt("DAOAgendaManager", DAO_AGENDA_MANAGER_ADDRESS);
    });

    describe("ClaimERC20 Check Tests", () => {
        it("should revert when trying to create agenda with claimERC20 for TON", async () => {
            const target = [DAO_VAULT_ADDRESS];
            const functionBytecode = [
                // claimERC20 function call with TON address
                ethers.utils.defaultAbiCoder.encode(
                    ['address', 'uint256'],
                    [TON_ADDRESS, ethers.utils.parseEther('1')]
                )
            ];

            // Approve TON for agenda creation fee
            const agendaFee = await daoAgendaManager.createAgendaFees();
            await ton.approve(daoCommittee.address, agendaFee);

            // Try to create agenda
            await expect(
                daoCommittee.createAgenda(
                    target,
                    [3600], // noticePeriodSeconds
                    [3600], // votingPeriodSeconds
                    true,   // atomicExecute
                    functionBytecode,
                    "Test Agenda"
                )
            ).to.be.revertedWith("claimERC20 ton dont use");
        });

        it("should allow creating agenda with claimERC20 for other tokens", async () => {
            const MOCK_TOKEN_ADDRESS = "0x1234567890123456789012345678901234567890"; // Example address
            const target = [DAO_VAULT_ADDRESS];
            const functionBytecode = [
                // claimERC20 function call with other token address
                ethers.utils.defaultAbiCoder.encode(
                    ['address', 'uint256'],
                    [MOCK_TOKEN_ADDRESS, ethers.utils.parseEther('1')]
                )
            ];

            // Approve TON for agenda creation fee
            const agendaFee = await daoAgendaManager.createAgendaFees();
            await ton.approve(daoCommittee.address, agendaFee);

            // Create agenda should succeed
            await expect(
                daoCommittee.createAgenda(
                    target,
                    [3600], // noticePeriodSeconds
                    [3600], // votingPeriodSeconds
                    true,   // atomicExecute
                    functionBytecode,
                    "Test Agenda"
                )
            ).to.not.be.reverted;
        });

        it("should allow creating agenda with other functions", async () => {
            const target = [DAO_VAULT_ADDRESS];
            const functionBytecode = [
                // Some other function call
                ethers.utils.defaultAbiCoder.encode(
                    ['uint256'],
                    [ethers.utils.parseEther('1')]
                )
            ];

            // Approve TON for agenda creation fee
            const agendaFee = await daoAgendaManager.createAgendaFees();
            await ton.approve(daoCommittee.address, agendaFee);

            // Create agenda should succeed
            await expect(
                daoCommittee.createAgenda(
                    target,
                    [3600], // noticePeriodSeconds
                    [3600], // votingPeriodSeconds
                    true,   // atomicExecute
                    functionBytecode,
                    "Test Agenda"
                )
            ).to.not.be.reverted;
        });
    });
}); 