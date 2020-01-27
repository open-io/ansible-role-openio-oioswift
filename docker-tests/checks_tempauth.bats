#! /usr/bin/env bats

# Variable SUT_IP should be set outside this script and should contain the IP
# address of the System Under Test.

# Tests
run_only_test() {
  if [[ "$SUT_IP" != "$1" ]]; then
    skip
  fi
}

setup() {
  run_only_test "172.17.0.4"
  TOKEN=$(curl -v -H 'X-Storage-User: travis:ci' -H 'X-Storage-Pass: TRAVIS_PASS' http://${SUT_IP}:6007/auth/v1.0  2>&1 | grep X-Auth-Token: | awk '{sub(/\r/, ""); print $3}')
  STORAGE_URL=$(curl -v -H 'X-Storage-User: travis:ci' -H 'X-Storage-Pass: TRAVIS_PASS' http://${SUT_IP}:6007/auth/v1.0  2>&1 | grep X-Storage-Url | awk '{sub(/\r/, ""); print $3}')
}

@test 'Auth - tempauth' {
  run curl -v -H 'X-Storage-User: travis:ci' -H 'X-Storage-Pass: TRAVIS_PASS' http://${SUT_IP}:6007/auth/v1.0
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 200 OK' ]]
  [[ "${output}" =~ "X-Storage-Url: http://${SUT_IP}:6007/v1/AUTH_travis" ]]
  [[ "${output}" =~ 'X-Auth-Token:' ]]
}

@test 'Stat account - tempauth' {
  run curl -i ${STORAGE_URL} -X GET -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'X-Account-Object-Count: 0' ]]
  [[ "${output}" =~ 'X-Account-Container-Count: 0' ]]
}

@test 'Create container - tempauth' {
  run curl -i ${STORAGE_URL}/test_container -X POST -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 201 Created' ]]
}


@test 'Upload object - tempauth' {
  echo travis is my life > CI
  run curl -i -T CI -X PUT -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 201 Created' ]]
}

@test 'List content of container - tempauth' {
  run curl -i -X GET -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 200 OK' ]]
  [[ "${output}" =~ 'Content-Length: 3' ]]
  [[ "${output}" =~ 'X-Container-Object-Count: 1' ]]
}

@test 'Download object - tempauth' {
  run curl -i  -X GET -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 200 OK' ]]
  [[ "${output}" =~ 'Content-Length: 18' ]]
}

@test 'Delete object - tempauth' {
  run curl -i -X DELETE -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'Content-Length: 0' ]]
}

@test 'Delete container - tempauth' {
  run curl -i -X DELETE -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'Content-Length: 0' ]]
}
