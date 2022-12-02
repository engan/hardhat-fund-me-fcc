// function deployFunc(hre) {
//     console.log("Hi!")
// }
// module.exports.default = deployFunc

// // Nearly identical, without async
// module.exports = async (hre) => {}

const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network } = require("hardhat")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // if chainId is X use address Y
    // if chainId is Z use address A
    // yarn hardhat deploy --network goerli
    // yarn hardhat deploy --network polygon
    // See also hardhat.config.js, module.exports, networks

    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        // In not on a development chain or a mock
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // if the contracts doesn't exist, we deploy a minimal version of
    // for our local testing

    // What happens when we want to change chains?
    // when going for localhost or hardhat network we want to use a mock
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // price feed address
        log: true,
        // we need to wait if on a live network so we can verify properly
        // if no blockConfirmations is given in hardhat.config.js
        // (blockConfirmations: 6), we are waiting for 1 block
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    // helper-hardhat-config.js: const developmentChains = ["hardhat", "localhost"]
    // Example: yarn hardhat deploy --network goerli    <= is NOT hardhat or localhost
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        // Verify codes in utils/verify.js
        await verify(fundMe.address, args)
    }
    log("---------------------------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
