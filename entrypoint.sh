#!/bin/bash

NVM_DIR=/usr/bin
. "$NVM_DIR/nvm.sh" 

# Use step(), try(), and next() to perform a series of commands and print
# [  OK  ] or [FAILED] at the end. The step as a whole fails if any individual
# command fails.
#
# Example:
#     step "Remounting / and /boot as read-write:"
#     try mount -o remount,rw /
#     try mount -o remount,rw /boot
#     next
step() {
    echo -n "$@"

    STEP_OK=0
    [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$
}

try() {
    # Check for `-b' argument to run command in the background.
    local BG=

    [[ $1 == -b ]] && { BG=1; shift; }
    [[ $1 == -- ]] && {       shift; }

    # Run the command.
    if [[ -z $BG ]]; then
        "$@"
    else
        "$@" &
    fi

    # Check if command failed and update $STEP_OK if so.
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        STEP_OK=$EXIT_CODE
        [[ -w /tmp ]] && echo $STEP_OK > /tmp/step.$$

        if [[ -n $LOG_STEPS ]]; then
            local FILE=$(readlink -m "${BASH_SOURCE[1]}")
            local LINE=${BASH_LINENO[0]}

            echo "$FILE: line $LINE: Command \`$*' failed with exit code $EXIT_CODE." >> "$LOG_STEPS"
        fi
    fi

    return $EXIT_CODE
}

next() {
    [[ -f /tmp/step.$$ ]] && { STEP_OK=$(< /tmp/step.$$); rm -f /tmp/step.$$; }
    [[ $STEP_OK -eq 0 ]]  && echo_success || echo_failure
    echo

    return $STEP_OK
}

BOOTUP=color
RES_COL=60
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_WARNING="echo -en \\033[1;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

echo_success() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
    echo -n $"  OK  "
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}

echo_failure() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
    echo -n $"FAILED"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}

echo_passed() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo -n $"PASSED"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}

echo_warning() {
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo -n $"WARNING"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
} 

TEST_DIR=/tmp/snarkjs_tests 
LOG=snarkjs_test.log

mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

CIRCOM_VERSION=$(circom --version)
SNARKJS_VERSION=$(snarkjs --version | grep "snarkjs@" | sed 's/snarkjs@//g')
NODE_VERSION=$(node -v)

echo -e "#############################################"
echo -e "Node version:\t\t\e[32m$NODE_VERSION\e[0m"
echo -e "Circom version:\t\t\e[32m$CIRCOM_VERSION\e[0m"
echo -e "Snarkjs version:\t\e[32m$SNARKJS_VERSION\e[0m"
echo -e "#############################################"

step "New bn128..."
try /usr/bin/versions/node/v14.7.0/bin/snarkjs powersoftau new bn128 12 pot12_0000.ptau -v 2>1 >>${LOG}
next

step "First contribution..."
try /usr/bin/versions/node/v14.7.0/bin/snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau -e="random" --name="First contribution" -v 2>1 >>${LOG}
next

step "Second contribution..."
try snarkjs powersoftau contribute pot12_0001.ptau pot12_0002.ptau --name="Second contribution" -v -e="some random text" -v 2>1 >>${LOG}
next

step "Export challenge..."
try snarkjs powersoftau export challenge pot12_0002.ptau challenge_0003 -v 2>1 >>${LOG}
next

step "Challenge contribution..."
try snarkjs powersoftau challenge contribute bn128 challenge_0003 response_0003 -e="some random text" -v 2>1 >>${LOG}
next

step "Third contribution..."
try snarkjs powersoftau import response pot12_0002.ptau response_0003 pot12_0003.ptau -n="Third contribution name" -v 2>1 >>${LOG}
next

step "Verify the protocol so far"
try snarkjs powersoftau verify pot12_0003.ptau -v 2>1 >>${LOG}
next

step "Apply a random beacon..."
try snarkjs powersoftau beacon pot12_0003.ptau pot12_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon" -v 2>1 >>${LOG}
next

step "Prepare phase2..."
try snarkjs powersoftau prepare phase2 pot12_beacon.ptau pot12_final.ptau -v -v 2>1 >>${LOG}
next

step "Verify the final ptau..."
try snarkjs powersoftau verify pot12_final.ptau -v 2>1 >>${LOG}
next

step "Create the circuit..."
try cat <<EOT > circuit.circom
template Multiplier(n) {
    signal private input a;
    signal private input b;
    signal output c;

    signal int[n];

    int[0] <== a*a + b;
    for (var i=1; i<n; i++) {
    int[i] <== int[i-1]*int[i-1] + b;
    }

    c <== int[n-1];
}

component main = Multiplier(1000);
EOT
next

step "Compile the circuit..."
try circom circuit.circom --r1cs --wasm --sym -v 2>1 >>${LOG}
next

step "View information about the circuit..."
try snarkjs r1cs info circuit.r1cs -v 2>1 >>${LOG}
next

step "Print the constraints..."
try snarkjs r1cs print circuit.r1cs circuit.sym -v 2>1 >>${LOG}
next

step "Export r1cs to json..."
try snarkjs r1cs export json circuit.r1cs circuit.r1cs.json -v 2>1 >>${LOG}
next

step "Generate the reference zkey without phase 2 contributions..."
try snarkjs zkey new circuit.r1cs pot12_final.ptau circuit_0000.zkey -v 2>1 >>${LOG}
next


step "Contribute to the phase 2 ceremony..."
try snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -e="random entropy" -v 2>1 >>${LOG}
next

step "Provide a second contribution..."
try snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Second contribution Name" -v -e="Another random entropy" 2>1 >>${LOG}
next

step "Provide a third contribution using third party software"
try snarkjs zkey export bellman circuit_0002.zkey  challenge_phase2_0003 -v 2>1 >>${LOG}
try snarkjs zkey bellman contribute bn128 challenge_phase2_0003 response_phase2_0003 -e="some random text" -v 2>1 >>${LOG}
try snarkjs zkey import bellman circuit_0002.zkey response_phase2_0003 circuit_0003.zkey -n="Third contribution name" -e="Another random text" -v 2>1 >>${LOG}
next

step "Verify the latest zkey..."
try snarkjs zkey verify circuit.r1cs pot12_final.ptau circuit_0003.zkey -v 2>1 >>${LOG}
next

step "Apply a random beacon..."
try snarkjs zkey beacon circuit_0003.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2" -v 2>1 >>${LOG}
next

step "Verify the final zkey..."
try snarkjs zkey verify circuit.r1cs pot12_final.ptau circuit_final.zkey -v 2>1 >>${LOG}
next

step "Export the verification key"
try snarkjs zkey export verificationkey circuit_final.zkey verification_key.json -v 2>1 >>${LOG}
next

step "Calculate the witness..."
try cat <<EOT > input.json
{"a": 3, "b": 11}
EOT
try snarkjs wtns calculate circuit.wasm input.json witness.wtns -v 2>1 >>${LOG}
next

step "Debug the final witness calculation..."
try snarkjs wtns debug circuit.wasm input.json witness.wtns circuit.sym --trigger --get --set -v 2>1 >>${LOG}
next

step "Create the proof..."
try snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json -v 2>1 >>${LOG}
next

step "Verify the proof..."
try snarkjs groth16 verify verification_key.json public.json proof.json -v 2>1 >>${LOG}
next

step "Turn the verifier into a smart contract..."
try snarkjs zkey export solidityverifier circuit_final.zkey verifier.sol -v 2>1 >>${LOG}
next

step "Simulate a verification call"
try snarkjs zkey export soliditycalldata public.json proof.json -v 2>1 >>${LOG}
next

if [ "${VERBOSE}" == true ];then
 cat ${LOG}
fi
