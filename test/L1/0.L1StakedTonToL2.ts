import { expect } from '../shared/expect'
import { ethers, network } from 'hardhat'

import { Signer } from 'ethers'
import { stakedTonSyncFixture } from '../shared/fixtures'
import { StakedTonSyncFixture } from '../shared/fixtureInterfaces'

describe('L1StakedTonToL2', () => {
    let deployer: Signer, addr1: Signer, addr2:Signer;
    let deployed: StakedTonSyncFixture

    before('create fixture loader', async () => {
        deployed = await stakedTonSyncFixture()
        deployer = deployed.deployer;
        addr1 = deployed.addr1;
        addr2 = deployed.addr2;
    })

    describe('# L1ERC20A_TokenFactory: not mint-able token', () => {
        let tokenInfo = {
            name: "TEST_TOKEN",
            symbol: "TST",
            initialSupply: ethers.utils.parseEther("100000"),
            owner: '',
            tokenAddress: ''
        }

        it('create non mint-able token', async () => {

            tokenInfo.owner = await addr1.getAddress()

            const topic = deployed.l1ERC20A_TokenFactory.interface.getEventTopic('CreatedERC20A');

            const receipt = await (await  deployed.l1ERC20A_TokenFactory.connect(addr1).create(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.initialSupply,
                    tokenInfo.owner
            )).wait();

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l1ERC20A_TokenFactory.interface.parseLog(log);
            tokenInfo.tokenAddress = deployedEvent.args.contractAddress;

            expect(deployedEvent.args.contractAddress).to.not.eq(ethers.constants.AddressZero);
            expect(deployedEvent.args.name).to.eq(tokenInfo.name);
            expect(deployedEvent.args.symbol).to.eq(tokenInfo.symbol);
            expect(deployedEvent.args.initialSupply).to.eq(tokenInfo.initialSupply);
            expect(deployedEvent.args.to).to.eq(tokenInfo.owner);
        });

        it('Tokens cannot be minted.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20A.abi, tokenInfo.tokenAddress, addr1);
            expect(await tokenContract.totalSupply()).to.be.eq(tokenInfo.initialSupply)
            expect(await tokenContract.balanceOf(tokenInfo.owner)).to.be.eq(tokenInfo.initialSupply)

            try {
                await tokenContract.connect(addr1).mint(tokenInfo.owner, tokenInfo.initialSupply)
            } catch(err){
                expect(err).to.not.null;
            }
        })

    });

    describe('# L1ERC20B_TokenFactory : mint-able token', () => {
        let tokenInfo = {
            name: "TEST_TOKEN",
            symbol: "TST",
            initialSupply: ethers.utils.parseEther("100000"),
            owner: '',
            tokenAddress: ''
        }

        it('create mint-able token', async () => {

            tokenInfo.owner = await addr1.getAddress()

            const topic = deployed.l1ERC20B_TokenFactory.interface.getEventTopic('CreatedERC20B');

            const receipt = await (await deployed.l1ERC20B_TokenFactory.connect(addr1).create(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.initialSupply,
                    tokenInfo.owner
            )).wait();

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l1ERC20B_TokenFactory.interface.parseLog(log);
            tokenInfo.tokenAddress = deployedEvent.args.contractAddress;

            expect(deployedEvent.args.contractAddress).to.not.eq(ethers.constants.AddressZero);
            expect(deployedEvent.args.name).to.eq(tokenInfo.name);
            expect(deployedEvent.args.symbol).to.eq(tokenInfo.symbol);
            expect(deployedEvent.args.initialSupply).to.eq(tokenInfo.initialSupply);
            expect(deployedEvent.args.owner).to.eq(tokenInfo.owner);
        });

        it('Tokens can be minted by owner.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20B.abi, tokenInfo.tokenAddress, addr1);
            expect(await tokenContract.totalSupply()).to.be.eq(tokenInfo.initialSupply)
            expect(await tokenContract.balanceOf(tokenInfo.owner)).to.be.eq(tokenInfo.initialSupply)
            await tokenContract.connect(addr1).mint(tokenInfo.owner, tokenInfo.initialSupply)
        })

        it('Tokens cannot be minted by not owner.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20B.abi, tokenInfo.tokenAddress, addr1);

            await expect(tokenContract.connect(addr2).mint(tokenInfo.owner, tokenInfo.initialSupply))
                .to.be.reverted ;

        })

    });

    describe('# L1ERC20C_TokenFactory: not mint-able and snapshot-able token', () => {
        let tokenInfo = {
            name: "TEST_TOKEN",
            symbol: "TST",
            initialSupply: ethers.utils.parseEther("100000"),
            owner: '',
            tokenAddress: ''
        }
        let snapshots = [];

        it('create non mint-able and snapshot token', async () => {

            tokenInfo.owner = await addr1.getAddress()

            const topic = deployed.l1ERC20C_TokenFactory.interface.getEventTopic('CreatedERC20C');

            const receipt = await (await  deployed.l1ERC20C_TokenFactory.connect(addr1).create(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.initialSupply,
                    tokenInfo.owner
            )).wait();

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l1ERC20C_TokenFactory.interface.parseLog(log);
            tokenInfo.tokenAddress = deployedEvent.args.contractAddress;

            expect(deployedEvent.args.contractAddress).to.not.eq(ethers.constants.AddressZero);
            expect(deployedEvent.args.name).to.eq(tokenInfo.name);
            expect(deployedEvent.args.symbol).to.eq(tokenInfo.symbol);
            expect(deployedEvent.args.initialSupply).to.eq(tokenInfo.initialSupply);
            expect(deployedEvent.args.to).to.eq(tokenInfo.owner);
        });

        it('Tokens cannot be minted.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20C.abi, tokenInfo.tokenAddress, addr1);
            expect(await tokenContract.totalSupply()).to.be.eq(tokenInfo.initialSupply)
            expect(await tokenContract.balanceOf(tokenInfo.owner)).to.be.eq(tokenInfo.initialSupply)

            try {
                await tokenContract.connect(addr1).mint(tokenInfo.owner, tokenInfo.initialSupply)
            } catch(err){
                expect(err).to.not.null;
            }
        })

        it('Only owner can snapshot', async () => {
            const tokenContract = await ethers.getContractAt(ERC20C.abi, tokenInfo.tokenAddress, addr1);

            const topic = tokenContract.interface.getEventTopic('Snapshot');

            const receipt = await (await tokenContract.connect(addr1).snapshot()).wait();
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = tokenContract.interface.parseLog(log);

            const addr1Address = await addr1.getAddress()
            const addr2Address = await addr2.getAddress()

            const balanceOf = await tokenContract.balanceOf(addr1Address);

            snapshots.push({
                id: deployedEvent.args.id,
                balanceOf: balanceOf
            })

            await tokenContract.connect(addr1).transfer(addr2Address, ethers.utils.parseEther("1"));
            expect(await tokenContract.balanceOf(addr1Address)).to.be.eq(balanceOf.sub(ethers.utils.parseEther("1")))
            expect(await tokenContract.balanceOfAt(addr1Address, deployedEvent.args.id)).to.be.eq(balanceOf)

        })

        it('User cannot snapshot', async () => {
            const tokenContract = await ethers.getContractAt(ERC20C.abi, tokenInfo.tokenAddress, addr1);

            await expect(tokenContract.connect(addr2).snapshot()).to.be.reverted;
        })
    });

    describe('# L1ERC20D_TokenFactory : mint-able and snapshot-able token', () => {
        let tokenInfo = {
            name: "TEST_TOKEN",
            symbol: "TST",
            initialSupply: ethers.utils.parseEther("100000"),
            owner: '',
            tokenAddress: ''
        }
        let snapshots = [];

        it('create mint-able token', async () => {

            tokenInfo.owner = await addr1.getAddress()

            const topic = deployed.l1ERC20D_TokenFactory.interface.getEventTopic('CreatedERC20D');

            const receipt = await (await deployed.l1ERC20D_TokenFactory.connect(addr1).create(
                    tokenInfo.name,
                    tokenInfo.symbol,
                    tokenInfo.initialSupply,
                    tokenInfo.owner
            )).wait();

            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = deployed.l1ERC20D_TokenFactory.interface.parseLog(log);
            tokenInfo.tokenAddress = deployedEvent.args.contractAddress;

            expect(deployedEvent.args.contractAddress).to.not.eq(ethers.constants.AddressZero);
            expect(deployedEvent.args.name).to.eq(tokenInfo.name);
            expect(deployedEvent.args.symbol).to.eq(tokenInfo.symbol);
            expect(deployedEvent.args.initialSupply).to.eq(tokenInfo.initialSupply);
            expect(deployedEvent.args.owner).to.eq(tokenInfo.owner);
        });

        it('Tokens can be minted by owner.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20D.abi, tokenInfo.tokenAddress, addr1);
            expect(await tokenContract.totalSupply()).to.be.eq(tokenInfo.initialSupply)
            expect(await tokenContract.balanceOf(tokenInfo.owner)).to.be.eq(tokenInfo.initialSupply)
            await tokenContract.connect(addr1).mint(tokenInfo.owner, tokenInfo.initialSupply)
        })

        it('Tokens cannot be minted by not owner.', async () => {
            const tokenContract = await ethers.getContractAt(ERC20D.abi, tokenInfo.tokenAddress, addr1);

            await expect(tokenContract.connect(addr2).mint(tokenInfo.owner, tokenInfo.initialSupply))
                .to.be.reverted ;
        })

        it('Only owner can snapshot', async () => {
            const tokenContract = await ethers.getContractAt(ERC20D.abi, tokenInfo.tokenAddress, addr1);

            const topic = tokenContract.interface.getEventTopic('Snapshot');

            const receipt = await (await tokenContract.connect(addr1).snapshot()).wait();
            const log = receipt.logs.find(x => x.topics.indexOf(topic) >= 0);
            const deployedEvent = tokenContract.interface.parseLog(log);

            const addr1Address = await addr1.getAddress()
            const addr2Address = await addr2.getAddress()

            const balanceOf = await tokenContract.balanceOf(addr1Address);

            snapshots.push({
                id: deployedEvent.args.id,
                balanceOf: balanceOf
            })

            await tokenContract.connect(addr1).transfer(addr2Address, ethers.utils.parseEther("1"));
            expect(await tokenContract.balanceOf(addr1Address)).to.be.eq(balanceOf.sub(ethers.utils.parseEther("1")))
            expect(await tokenContract.balanceOfAt(addr1Address, deployedEvent.args.id)).to.be.eq(balanceOf)

        })

        it('User cannot snapshot', async () => {
            const tokenContract = await ethers.getContractAt(ERC20D.abi, tokenInfo.tokenAddress, addr1);

            await expect(tokenContract.connect(addr2).snapshot()).to.be.reverted;
        })
    });
});

