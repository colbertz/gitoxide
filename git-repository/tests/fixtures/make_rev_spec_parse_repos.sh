#!/bin/bash
set -eu -o pipefail

ROOT="$PWD"

function baseline() {
  local spec=${1:?first argument is the spec to test}
  {
    echo "$spec"
    git rev-parse -q --verify "$spec" 2>/dev/null || echo $?
  }>> "$ROOT/baseline.git"
}

# The contents of this file is based on https://github.com/git/git/blob/8168d5e9c23ed44ae3d604f392320d66556453c9/t/t1512-rev-parse-disambiguation.sh#L38
git init --bare blob.prefix
(
  cd blob.prefix
  # Both start with "dead..", under both SHA-1 and SHA-256
  echo brocdnra | git hash-object -w --stdin
  echo brigddsv | git hash-object -w --stdin
  # Both start with "beef.."
  echo 1agllotbh | git hash-object -w --stdin
  echo 1bbfctrkc | git hash-object -w --stdin

  baseline "dead"
  baseline "beef"
)


git init --bare blob.bad
(
  cd blob.bad
  # Both have the prefix "bad0"
  # Maybe one day we have a test to see how disambiguation reporting deals with this.
  echo xyzfaowcoh | git hash-object -t bad -w --stdin --literally
  echo xyzhjpyvwl | git hash-object -t bad -w --stdin --literally
  baseline "bad0"

  echo 1bbfctrkc | git hash-object -t bad -w --stdin --literally
  baseline "e328"
  baseline "e328^{object}"
)

function oid_to_path() {
  local basename=${1#??}
  echo "${1%$basename}/$basename"
}

git init --bare blob.corrupt
(
  cd blob.corrupt
  # Both have the prefix "cafe".
  # Maybe one day we have a test to see how disambiguation reporting deals with this.
  echo bnkxmdwz | git hash-object -w --stdin
  oid=$(echo bmwsjxzi | git hash-object -w --stdin)
  oidf=objects/$(oid_to_path "$oid")
  chmod 755 $oidf
  echo broken >$oidf

  baseline "cafea"
  baseline "cafea^{object}"
)

# This function writes out its parameters, one per line
function write_lines () {
  	printf "%s\n" "$@"
}

git init ambiguous_blob_and_tree
(
  cd ambiguous_blob_and_tree
  (
    write_lines 0 1 2 3 4 5 6 7 8 9
    echo
    echo b1rwzyc3
  ) >a0blgqsjc
  # create one blob 0000000000b36
  git add a0blgqsjc
  # create one tree 0000000000cdc
  git write-tree

  baseline "0000000000"
  baseline "0000000000cdc:a0blgqsjc" # unambiguous by nature
  baseline "0000000000:a0blgqsjc"    # would be ambiguous, but only trees can have this syntax
)
