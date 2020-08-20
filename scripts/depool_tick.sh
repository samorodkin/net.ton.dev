#
# Forced tick of DePool SC to update its inner state
# Method (c) Tkachenko-Tyurin
#

tonos-cli call $(cat validator.addr) submitTransaction "{\"dest\":\"$(cat depool.addr)\",\"value\":1000000000,\"bounce\":false,\"allBalance\":\"false\",\"payload\":\"te6ccgEBAQEABgAACCiAmCM=\"}" \
    --abi ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
    --sign ${KEYS_DIR}/msig.keys.json > tick.log
cat tick.log

tr=$(cat tick.log | grep \"transId\" | awk '{ print $2 }')

tonos-cli call $(cat validator.addr) confirmTransaction "{\"transactionId\":$tr}" --abi ${CONFIGS_DIR}/SafeMultisigWallet.abi.json --sign ${KEYS_DIR}/msig.keys2.json

