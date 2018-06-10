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
  run_only_test "172.17.0.3"
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
  TOKEN=$(curl -v -H 'X-Storage-User: travis:ci' -H 'X-Storage-Pass: TRAVIS_PASS' http://${SUT_IP}:6007/auth/v1.0  2>&1 | grep X-Auth-Token: | awk '{sub(/\r/, ""); print $3}')
  STORAGE_URL=$(curl -v -H 'X-Storage-User: travis:ci' -H 'X-Storage-Pass: TRAVIS_PASS' http://${SUT_IP}:6007/auth/v1.0  2>&1 | grep X-Storage-Url | awk '{sub(/\r/, ""); print $3}')
  run curl -i ${STORAGE_URL} -X GET -H "X-Auth-Token: ${TOKEN}"

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'HTTP/1.1 500 Internal Error' ]]
}
#> Statistics of an Account:
#curl -i $STORAGE_URL -X GET -H “X-Auth-Token:$TOKEN”
#
#> Create a Container:
#curl -i $STORAGE_URL/container1 -X PUT -H “X-Auth-Token:$TOKEN”
#
#> stat of the container/listing of a container:
#curl -i $STORAGE_URL/container1  -X GET -H “Content-Length: 0” -H “X-Auth-Token:$TOKEN”
#
#>upload a object(photo.jpg inside container1):
#curl -X PUT -i -H “X-Auth-Token: $TOKEN” -T photo.jpg $STORAGE_URL/container1/photo.jpg
#> download a object:
#curl -X GET -i  -H  “X-Auth-Token: $TOKEN”  $STORAGE_URL/container1/photo.jpg
#or (if every one has the permission to read/download it)
#
#wget $STORAGE_URL/steven/photo.jpg
