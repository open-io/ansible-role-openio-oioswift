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
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_ACCESS_KEY_ID="travis:ci"
  export AWS_SECRET_ACCESS_KEY="TRAVIS_PASS"
}

@test 'S3 - Make Bucket' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 mb s3://test
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'make_bucket: test' ]]
}

@test 'S3 - Make Bucket with same name' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 mb s3://test
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "1" ]]
  [[ "${output}" =~ 'BucketAlreadyOwnedByYou' ]]
}

@test 'S3 - Make Bucket with same name in other tenant (bucket DB)' {
  export AWS_ACCESS_KEY_ID="plop:user1"
  export AWS_SECRET_ACCESS_KEY="USER1_PASS"
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 mb s3://test
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "1" ]]
  [[ "${output}" =~ 'BucketAlreadyExists' ]]
}

@test 'S3 - Upload object' {
  echo travis is my life > CI
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 cp CI s3://test

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'upload: ./CI to s3://test/CI' ]]
}

@test 'S3 - Upload object public-read' {
  echo woosa > plop
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 cp plop s3://test --acl public-read

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'upload: ./plop to s3://test/plop' ]]
}

#@test 'S3 - Get public object in Virtual Hosted-Style and IAM' {
#  # NOT MANAGED
#  run curl --resolve test.s3.openio.io:6007:${SUT_IP} http://test.s3.openio.io:6007/plop
#
#  echo "output: "$output
#  echo "status: "$status
#  [[ "${status}" -eq "0" ]]
#  [[ "${output}" =~ 'woosa' ]]
#}

@test 'S3 - List buckets' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 ls s3://

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'test' ]]
}

@test 'S3 - List specified bucket' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 ls s3://test

  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'CI' ]]
}

@test 'S3 - Remove Object' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 rm s3://test/CI
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'delete: s3://test/CI' ]]
}

@test 'S3 - Remove Bucket' {
  run aws --endpoint-url http://${SUT_IP}:6007 --no-verify-ssl s3 rb s3://test --force
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ 'remove_bucket: test' ]]
}

