#!/usr/bin/env bash

suite="$1"
shift

export colorred=$(tput setaf 1)
export colorgreen=$(tput setaf 2)
export coloryellow=$(tput setaf 3)
export colordefault=$(tput sgr0)
export colorrev=$(tput rev)

this=$(readlink -f "$0")
export basename=$(dirname "$this")
export basedir=$(cd "$basename" && pwd)
cd $basedir

failed=0
logfail() {
	echo "${colordefault}${colorred}${colorrev} FAIL ${colordefault}${colorred} ${test}${colordefault}"
	((failed++))
}

passed=0
logpass() {
	echo "${colordefault}${colorgreen}${colorrev} PASS ${colordefault}${colorgreen} ${test}${colordefault}"
	((passed++))
}

log() {
	echo "${colordefault}${coloryellow} ===> $* ${colordefault}"
}

logsummary() {
	((total = failed + passed))
	echo "-------------------------------------------------------------"
	echo "${colordefault}  ${colorgreen}${passed} PASS ${colorred}${failed} FAIL ${colordefault} out of ${total} run"
	echo "-------------------------------------------------------------"
}

if [ -z "$suite" ]
then
	suites=$(find ${basedir}/ -type f -name '*-Dockerfile' -printf '%f\n' | cut -d - -f 1 | sort)
	echo "${colordefault}${colorred}Missing suite name argument, listing suite names${colordefault}" >&2
	echo $suites
	exit -1
fi

imgname=dotmate-test-$suite
tests="$@"
if [ -z "$tests" ]
then
	tests=$(find ${basedir}/ -type f -name 'test-*' -printf '%f\n' | cut -d - -f 2- | sort)
fi
if [ -z "$TEST_SKIP_BUILD" ]
then
	log Building image for $suite
	docker build -t $imgname -f $suite-Dockerfile ..
fi
for test in $tests
do
	args=". /opt/dotmate/tests/harness /opt/dotmate/tests/test-${test}"
	log Running $test
	docker run --rm $imgname /bin/bash -c "$args"
	result="$?"
	if [ "$result" -eq 0 ]
	then
		logpass
	else
		logfail
	fi
done
logsummary
if [ -z "$TEST_KEEP_IMAGE" ]
then
	log Removing image for $suite
	docker image remove $imgname
fi
log DONE
exit $failed

