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
  run_only_test "172.17.0.2"
  TOKEN=$(curl -i  -H "Content-Type: application/json"  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"travis","domain":{"id":"default"},"password":"TRAVIS_PASS"}}},"scope":{"project":{"name":"CI","domain":{"id":"default"}}}}}' http://${SUT_IP}:5000/v3/auth/tokens | grep X-Subject-Token: | awk '{sub(/\r/, ""); print $2}')
  STORAGE_URL=$(curl -s  -H "Content-Type: application/json"  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"travis","domain":{"id":"default"},"password":"TRAVIS_PASS"}}},"scope":{"project":{"name":"CI","domain":{"id":"default"}}}}}' http://${SUT_IP}:5000/v3/auth/tokens |  python -mjson.tool | grep http://172.17.0.2:6007/v1/AUTH_ | sort -u | awk '{sub(/\r/, ""); gsub(/"/, "", $2);  print $2}')
}

@test 'Stat account - keystoneauth' {
  run curl -i ${STORAGE_URL} -X GET -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'X-Account-Object-Count: 0' ]]
  [[ "${output}" =~ 'X-Account-Container-Count: 0' ]]
}

@test 'Create container - keystoneauth' {
  run curl -i ${STORAGE_URL}/test_container -X POST -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 201 Created' ]]
}


@test 'Upload object - keystoneauth' {
  echo travis is my life > CI
  run curl -i -T CI -X PUT -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 201 Created' ]]
}

@test 'List content of container - keystoneauth' {
  run curl -i -X GET -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 200 OK' ]]
  [[ "${output}" =~ 'Content-Length: 3' ]]
  [[ "${output}" =~ 'X-Container-Object-Count: 1' ]]
}

@test 'Download object - keystoneauth' {
  run curl -i  -X GET -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 200 OK' ]]
  [[ "${output}" =~ 'Content-Length: 18' ]]
}

@test 'Delete object - keystoneauth' {
  run curl -i -X DELETE -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container/CI

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'Content-Length: 0' ]]
}

@test 'Delete container - keystoneauth' {
  run curl -i -X DELETE -H "X-Auth-Token: ${TOKEN}" ${STORAGE_URL}/test_container

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 204 No Content' ]]
  [[ "${output}" =~ 'Content-Length: 0' ]]
}

