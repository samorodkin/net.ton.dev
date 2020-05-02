#!/bin/bash -eE

# Copyright 2018-2020 TON DEV SOLUTIONS LTD.
#
# Licensed under the SOFTWARE EVALUATION License (the "License"); you may not use
# this file except in compliance with the License.  You may obtain a copy of the
# License at:
#
# https://www.ton.dev/licenses
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific TON DEV software governing permissions and limitations
# under the License.
#

#DEBUG="yes"

if [ "$DEBUG" = "yes" ]; then
    set -x
fi

echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date)"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

stake="${1:-100000}"

prefix="${KEYS_DIR}"
msig_addr="$prefix/${VALIDATOR_NAME}.addr"

nanostake=$("${TON_BUILD_DIR}/utils/tonos-cli" convert tokens "$stake")

"${TON_BUILD_DIR}/lite-client/lite-client" \
    -p "$prefix/liteserver.pub" \
    -a 127.0.0.1:3031 \
    -rc "getconfig 1" -rc "quit" \
    &>"$prefix/elector-addr"

awk -v prefix="$prefix" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
    if (substr($1, length($1)-13) == "ConfigParam(1)") {
        printf TON_BUILD_DIR "/lite-client/lite-client ";
        printf "-p " prefix "/liteserver.pub -a 127.0.0.1:3031 ";
        printf "-rc \"runmethod -1:" substr($4, 15, 64) " ";
        print  "active_election_id\" -rc \"quit\" &> " prefix "/elector-state"
        printf substr($4, 15, 64) " > " prefix "/elector-addr-base64"
    }
}' "$prefix/elector-addr" >"$prefix/elector-run"

bash "$prefix/elector-run"

awk '{
    if ($1 == "result:") {
        print $3
    }
}' "$prefix/elector-state" >"$prefix/election-id"

election_id=$(cat "$prefix/election-id")

if [ "$election_id" == "0" ]; then
    date +"%F %T No current elections"
    awk -v prefix="$prefix" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
        if (($1 == "new") && ($2 == "wallet") && ($3 == "address")) {
            addr = substr($5, 4)
        } else if (substr($1, length($1)-13) == "ConfigParam(1)") {
            printf TON_BUILD_DIR "/lite-client/lite-client ";
            printf "-p " prefix "/liteserver.pub -a 127.0.0.1:3031 ";
            printf "-rc \"runmethod -1:" substr($4, 15, 64);
            printf " compute_returned_stake 0x" addr "\" ";
            print  " -rc \"quit\" &> " prefix "/recover-state"
        }
    }' "$prefix/${VALIDATOR_NAME}-dump" "$prefix/elector-addr" >"$prefix/recover-run"

    bash "$prefix/recover-run"

    awk '{
        if ($1 == "result:") {
            print $3
        }
    }' "$prefix/recover-state" >"$prefix/recover-amount"

    recover_amount=$(cat "$prefix/recover-amount")

    if [ "$recover_amount" != "0" ]; then
        awk -v prefix="$prefix" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
            if ($1 == "Bounceable") {
                printf TON_BUILD_DIR "/lite-client/lite-client ";
                printf "-p " prefix "/liteserver.pub -a 127.0.0.1:3031 ";
                print  "-rc \"getaccount " $6 "\" -rc \"quit\" &> " prefix "/recover-state"
            }
        }' "$prefix/${VALIDATOR_NAME}-dump" >"$prefix/recover-run1"

        bash "$prefix/recover-run1"

        elector_addr=$(cat "$prefix/elector-addr-base64")

        "${TON_BUILD_DIR}/crypto/fift" -I "${TON_BUILD_DIR}/crypto/lib:${TON_BUILD_DIR}/crypto/smartcont" -s recover-stake.fif "$prefix/recover-query.boc"

        recover_query_boc=$(xxd -pc 180 "$prefix/recover-query.boc" | base64 --wrap=0)

        "${TON_BUILD_DIR}/utils/tonos-cli" call "${msig_addr}" submitTransaction \
            "{\"dest\":\"${elector_addr}\",\"value\":\"1000000000\",\"bounce\":true,\"allBalance\":false,\"payload\":\"${recover_query_boc}\"}" \
            --abi MultisigWallet.abi.json \
            --sign msig.keys.json \
            >recover_stake.transId

        transactionId=$(grep transId "${prefix}/recover_stake.transId")
        echo "INFO: transactionId = $transactionId" # send to other custodians for confirmation
        date +"INFO: %F %T Recover of $recover_amount GR requested"
    fi

    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
    exit
fi

if [ -f "$prefix/stop-election" ]; then
    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
    exit
fi

if [ -f "$prefix/active-election-id" ]; then
    active_election_id=$(cat "$prefix/active-election-id")
    if [ "$active_election_id" == "$election_id" ]; then
        #        date +"%F %T Elections $election_id, already submitted"
        echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
        exit
    fi
fi

cp "$prefix/election-id" "$prefix/active-election-id"
date +"INFO: %F %T Elections $election_id"

"${TON_BUILD_DIR}/validator-engine-console/validator-engine-console" \
    -k "$prefix/client" \
    -p "$prefix/server.pub" \
    -a 127.0.0.1:3030 \
    -c "newkey" -c "quit" \
    &>"$prefix/${VALIDATOR_NAME}-election-key"

"${TON_BUILD_DIR}/validator-engine-console/validator-engine-console" \
    -k "$prefix/client" \
    -p "$prefix/server.pub" \
    -a 127.0.0.1:3030 \
    -c "newkey" -c "quit" \
    &>"$prefix/${VALIDATOR_NAME}-election-adnl-key"

"${TON_BUILD_DIR}/lite-client/lite-client" \
    -p "$prefix/liteserver.pub" \
    -a 127.0.0.1:3031 \
    -rc "getconfig 15" -rc "quit" \
    &>"$prefix/elector-params"

awk -v validator="${VALIDATOR_NAME}" -v prefix="$prefix" -v wallet_addr="$msig_addr" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
    if (NR == 1) {
        election_start = $1 + 0
    } else if (($1 == "created") && ($2 == "new") && ($3 == "key")) {
        if (length(key) == 0) {
            key = $4
        } else {
            key_adnl = $4
        }
    } else if (substr($1, length($1)-14) == "ConfigParam(15)") {
        time = election_start + 1000;
        split($4, t, ":");
        time = time + t[2] + 0;
        split($5, t, ":");
        time = time + t[2] + 0;
        split($6, t, ":");
        time = time + t[2] + 0;
        split($7, t, ":");
        time = time + t[2] + 0;
        election_stop = time;
        printf TON_BUILD_DIR "/validator-engine-console/validator-engine-console ";
        printf "-k " prefix "/client -p " prefix "/server.pub -a 127.0.0.1:3030 ";
        printf "-c \"addpermkey " key " " election_start " " election_stop "\" ";
        printf "-c \"addtempkey " key " " key " " election_stop "\" ";
        printf "-c \"addadnl " key_adnl " 0\" ";
        printf "-c \"addvalidatoraddr " key " " key_adnl " " election_stop "\" ";
        print  "-c \"quit\"";
        printf TON_BUILD_DIR "/crypto/fift ";
        printf "-I " TON_BUILD_DIR "/crypto/lib:" TON_BUILD_DIR "/crypto/smartcont ";
        printf "-s validator-elect-req.fif " " wallet_addr;
        printf " " election_start " 2 " key_adnl " " prefix "/validator-to-sign.bin ";
        print  "> " prefix "/" validator "-request-dump"
    }
}' "$prefix/election-id" "$prefix/${VALIDATOR_NAME}-election-key" \
    "$prefix/${VALIDATOR_NAME}-election-adnl-key" "$prefix/elector-params" >"$prefix/elector-run1"

bash "$prefix/elector-run1"

awk -v validator="${VALIDATOR_NAME}" -v prefix="$prefix" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
    if (NR == 2) {
        request = $1
    } else if (($1 == "created") && ($2 == "new") && ($3 == "key")) {
        printf TON_BUILD_DIR "/validator-engine-console/validator-engine-console ";
        printf "-k " prefix "/client -p " prefix "/server.pub -a 127.0.0.1:3030 ";
        printf "-c \"exportpub " $4 "\" ";
        print  "-c \"sign " $4 " " request "\" &> " prefix "/" validator "-request-dump1"
   }
}' "$prefix/${VALIDATOR_NAME}-request-dump" "$prefix/${VALIDATOR_NAME}-election-key" >"$prefix/elector-run2"

bash "$prefix/elector-run2"

awk -v validator="${VALIDATOR_NAME}" -v prefix="$prefix" -v wallet_addr="$msig_addr" -v TON_BUILD_DIR="${TON_BUILD_DIR}" '{
    if (NR == 1) {
        election_start = $1 + 0
    } else if (($1 == "got") && ($2 == "public") && ($3 == "key:")) {
        key = $4
    } else if (($1 == "got") && ($2 == "signature")) {
        signature = $3
    } else if (($1 == "created") && ($2 == "new") && ($3 == "key")) {
        printf TON_BUILD_DIR "/crypto/fift ";
        printf "-I " TON_BUILD_DIR "/crypto/lib:" TON_BUILD_DIR "/crypto/smartcont ";
        printf "-s validator-elect-signed.fif " " wallet_addr " election_start " 2 " $4;
        printf " " key " " signature " " prefix "/validator-query.boc ";
        print  "> " prefix "/" validator "-request-dump2"
    }
}' "$prefix/election-id" "$prefix/${VALIDATOR_NAME}-request-dump1" "$prefix/${VALIDATOR_NAME}-election-adnl-key" >"$prefix/elector-run3"

bash "$prefix/elector-run3"

#send validator query to elector contract using multisig
validator_query_boc=$(xxd -pc 180 "$prefix/validator-query.boc" | base64 --wrap=0)
elector_addr=$(cat "$prefix/elector-addr-base64")

"${TON_BUILD_DIR}/utils/tonos-cli" call "${msig_addr}" submitTransaction \
    "{\"dest\":\"${elector_addr}\",\"value\":\"${nanostake}\",\"bounce\":true,\"allBalance\":false,\"payload\":\"${validator_query_boc}\"" \
    --abi MultisigWallet.abi.json \
    --sign msig.keys.json \
    >process_new_stake.transId

#TODO: add check if tonos-cli is failed
transactionId=$(grep transId "$prefix/process_new_stake.transId")
echo "INFO: transactionId = $transactionId" # send to other custodians for confirmation

date +"INFO: %F %T prepared for elections"

echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
