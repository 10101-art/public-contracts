require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("dotenv").config();

const {
    API_KEY,
    METAMASK_PRIVATE_KEY,
    CONFIG_URL_GOERLI,
    CONFIG_API_URL_GOERLI,
    CONFIG_BROWSER_URL_GOERLI,
    CONFIG_API_URL_MAINNET,
    CONFIG_BROWSER_URL_MAINNET,
    CONFIG_URL_MAINNET,
    CONFIG_API_URL_SEPOLIA,
    CONFIG_BROWSER_URL_SEPOLIA,
    CONFIG_URL_SEPOLIA,

} = process.env;

const METAMASK_ACCOUNT_deploy_private =
    process.env.METAMASK_ACCOUNT_deploy_private;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.9",
    gasReporter: {
        enabled: true,
    },
    optimizer: {
        enabled: true,
        runs: 200,
    },

    networks: {
        hardhat: {
            blockGasLimit: 60000000000, // Network block gasLimit
        },
        goerli: {
            urls: {
                apiURL: CONFIG_API_URL_GOERLI,
                browserURL: CONFIG_BROWSER_URL_GOERLI,
            },
            url: CONFIG_URL_GOERLI,
            accounts: [METAMASK_PRIVATE_KEY],
        },
        sepolia: {
            urls: {
                apiURL: CONFIG_API_URL_SEPOLIA,
                browserURL: CONFIG_BROWSER_URL_SEPOLIA,
            },
            url: CONFIG_URL_SEPOLIA,
            accounts: [METAMASK_ACCOUNT_deploy_private],

        },
        mainnet: {
            urls: {
                apiURL: CONFIG_API_URL_MAINNET,
                browserURL: CONFIG_BROWSER_URL_MAINNET,
            },
            url: CONFIG_URL_MAINNET,
            accounts: [METAMASK_ACCOUNT_deploy_private],
        },
        bsctest: {
            urls: {
                apiURL: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
                browserURL: '',
            },
            url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
            accounts: [METAMASK_ACCOUNT_deploy_private],
        },
        bsc: {
            urls: {
                apiURL: 'https://bsc-dataseed.binance.org/',
                browserURL: '',
            },
            url: 'https://bsc-dataseed.binance.org/',
            accounts: [METAMASK_ACCOUNT_deploy_private],
        },
        local: {
            urls: {
                apiURL: 'http://127.0.0.1:8545/',
                browserURL: '',
            },
            url: 'http://127.0.0.1:8545/',
            accounts: ['0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e'],
        },
    },
    etherscan: {
        apiKey: API_KEY,
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: false,
        only: [],
    },
};
