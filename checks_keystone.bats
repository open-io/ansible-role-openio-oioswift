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
}

@test 'Stat account - keystoneauth' {
  TOKEN=$(curl -i  -H "Content-Type: application/json"  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"travis","domain":{"id":"default"},"password":"TRAVIS_PASS"}}},"scope":{"project":{"name":"CI","domain":{"id":"default"}}}}}' http://${SUT_IP}:5000/v3/auth/tokens | grep X-Subject-Token: | awk '{sub(/\r/, ""); print $2}')
  STORAGE_URL=$(curl -s  -H "Content-Type: application/json"  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"travis","domain":{"id":"default"},"password":"TRAVIS_PASS"}}},"scope":{"project":{"name":"CI","domain":{"id":"default"}}}}}' http://${SUT_IP}:5000/v3/auth/tokens |  python -mjson.tool | grep http://172.17.0.2:6007/v1/AUTH_ | sort -u | awk '{sub(/\r/, ""); gsub(/"/, "", $2);  print $2}')
  run curl -i ${STORAGE_URL} -X GET -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 500 Internal Error' ]]
}
