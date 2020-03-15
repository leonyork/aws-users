var AWS = require("aws-sdk");

(async() => {
    const iam = new AWS.IAM()
    const userName = process.argv[2]
    if (!userName) {
        throw "Username not supplied. This should be supplied as the first argument"
    }

    const response = await iam.listAccessKeys({UserName: userName}).promise()
    if (response.AccessKeyMetadata.length > 1) {
        const earliestAccessKey = response.AccessKeyMetadata.reduce((a, b) => a.CreateDate < b.CreateDate ? a : b)
        await iam.deleteAccessKey({UserName: userName, AccessKeyId: earliestAccessKey.AccessKeyId}).promise()
    }
    const newAccessKey = await iam.createAccessKey({UserName: userName}).promise()
    console.log(JSON.stringify(newAccessKey.AccessKey))
    process.exit(0)
})().catch((err) => {
    console.error(err)
    process.exit(1)
})
