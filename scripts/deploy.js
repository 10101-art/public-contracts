// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require("dotenv").config({path: "../.env"});

const fs = require("fs");

async function main() {
    console.log("Start deploy...");


    if (!fs.existsSync('./deploy')) {
        fs.mkdirSync('./deploy');
    }



    const Airdrop = await hre.ethers.getContractFactory("Airdrop");
    const airdrop = await Airdrop.deploy();
    await airdrop.deployed();

    console.log("Airdrop " + airdrop.address);
    console.log('Add admin "Deployer" in Airdrop..');

    await airdrop.addAdmin(process.env.DEPLOYER_ADMIN_MAINNET);

    console.log("Admin added in Airdrop!");

    fs.writeFileSync('./deploy/Airdrop.json', JSON.stringify(airdrop));

    const Presale = await hre.ethers.getContractFactory("Presale");
    const presale = await Presale.deploy(process.env.BENEFICIARY_PRESALE_MAINNET);
    await presale.deployed();

    console.log("Presale " + presale.address);
    console.log('Add admin "Deployer" in Presale..');

    await presale.addAdmin(process.env.DEPLOYER_ADMIN_MAINNET);

    console.log("Admin added in Presale!");

    fs.writeFileSync('./deploy/Presale.json', JSON.stringify(presale));

    const ERC721Factory = await hre.ethers.getContractFactory("ERC721Factory");
    const erc721Factory = await ERC721Factory.deploy(
        presale.address,
        airdrop.address,
        hre.ethers.constants.AddressZero
    );

    await erc721Factory.deployed();

    console.log("ERC721Factory " + erc721Factory.address);

    fs.writeFileSync('./deploy/ERC721Factory.json', JSON.stringify(erc721Factory));

    const PresalesFactory = await hre.ethers.getContractFactory("PresalesFactory");
    const presalesFactory = await PresalesFactory.deploy();
    await presalesFactory.deployed();
    console.log("PresalesFactory " + presalesFactory.address);

    fs.writeFileSync('./deploy/PresalesFactory.json', JSON.stringify(presalesFactory));

    await presale.addAdmin(presalesFactory.address);



    console.log("Completed deploy!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
