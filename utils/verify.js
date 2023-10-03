const { run } = require("hardhat");

const verify = async(contractAddress, args, contract) => {
    console.log("verifying contract........");

    try{
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
            contract: contract
        })
    }
    catch(error){
        if(error.message.toLowerCase().includes("already verified")){
            console.log("contract has already been verified")
        } else {
            console.log(error)
        }
    }
}

module.exports = {
    verify
}