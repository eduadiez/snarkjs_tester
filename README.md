### Build

```
docker build -t eduadiez/snarkjs_tester .
```

### Run the tests

```
$ docker run --rm eduadiez/snarkjs_tester
or
$ docker run --rm --env VERBOSE=true eduadiez/snarkjs_tester
```

#### Expected result

```
$ docker run --rm eduadiez/snarkjs_tester
#############################################
Node version:           v14.7.0
Circom version:         0.5.17
Snarkjs version:        0.3.12
#############################################
New bn128...                                               [  OK  ]
First contribution...                                      [  OK  ]
Second contribution...                                     [  OK  ]
Export challenge...                                        [  OK  ]
Challenge contribution...                                  [  OK  ]
Third contribution...                                      [  OK  ]
Verify the protocol so far                                 [  OK  ]
Apply a random beacon...                                   [  OK  ]
Prepare phase2...                                          [  OK  ]
Verify the final ptau...                                   [  OK  ]
Create the circuit...                                      [  OK  ]
Compile the circuit...                                     [  OK  ]
View information about the circuit...                      [  OK  ]
Print the constraints...                                   [  OK  ]
Export r1cs to json...                                     [  OK  ]
Generate the reference zkey without phase 2 contributions..[  OK  ]
Contribute to the phase 2 ceremony...                      [  OK  ]
Provide a second contribution...                           [  OK  ]
Provide a third contribution using third party software    [  OK  ]
Verify the latest zkey...                                  [  OK  ]
Apply a random beacon...                                   [  OK  ]
Verify the final zkey...                                   [  OK  ]
Export the verification key                                [  OK  ]
Calculate the witness...                                   [  OK  ]
Debug the final witness calculation...                     [  OK  ]
Create the proof...                                        [  OK  ]
Verify the proof...                                        [  OK  ]
Turn the verifier into a smart contract...                 [  OK  ]
Simulate a verification call                               [  OK  ]
```
