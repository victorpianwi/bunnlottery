console.log('yesssssss');
const { network } = require("hardhat");
const { verify } = require("../utils/verify");
require("dotenv").config();

module.exports = async({getNamedAccounts, deployments}) => {
    const { deployer } = await getNamedAccounts()
    const { deploy } = deployments

    // deploy our contract
    const BUNNLottery = await deploy("BadassDev", {
        from: deployer,
        args: [5793],
        log: true,
        waitConfirmations: network.config.blockConfirmations,
    })

    // verify our contract
    const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
    if(network.config.chainId != 31337 && ETHERSCAN_API_KEY){
        await verify(
            BUNNLottery.address,
            [5793],
            "contracts/BUNNLottery.sol:BUNNLottery"
        )
    }
}

module.exports.tags = ["all", "nft"]