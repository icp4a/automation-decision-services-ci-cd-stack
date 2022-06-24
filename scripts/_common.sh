# Helper functions for main install scripts.

DEBUG=

# Wait for the given deployments to reach the `ready` state.
#
# args: <command> <namespace> <timeout> <deployment name> <deployment name> ...
#   <command> is the kubectl-like command to use for interaction with the kubernetes server  (kubectl or oc)
#   <namespace> is the name of namespace of the deployments
#   <timeout> in seconds
#   <deployment names>  is a list of tokens which identify deployment objects in the `kubectl get deployments` output
# returns 0 if deployments get ready before timeout, 1 otherwise
function wait_deployments() {

    local ctl_command=$1
    shift
    local namespace=$1
    shift
    local timeout_seconds=$1
    shift
    local deployments=("$@")  # array of names of deployments

    elapsed=0  #$((timeout_seconds / 5 ))
    while [[ $elapsed -lt $timeout_seconds ]]  ; do
        echo "Waiting for start... (elapsed ${elapsed}s, timeout at ${timeout_seconds}s)"
        sleep 5
        elapsed=$((elapsed + 5))

        ready_count=0
        for dep in ${deployments[@]} ; do
            [[ -n ${DEBUG} ]] && echo "DEBUG: checking $dep" >&2
            dep_status=( $($ctl_command get deployments -n $namespace | awk "/$dep/ { print \$2, \$3, \$4, \$5 ; } ") )  # fields are DESIRED CURRENT UP-TO-DATE AVAILABLE
            [[ -n ${DEBUG} ]] && echo "DEBUG: status is ${dep_status[@]}" >&2
            dep_ready=true
            for a in ${dep_status[@]:1} ; do
                if [[ $a -ne ${dep_status[0]} ]] ; then
                    dep_ready=false
                fi
            done
            if [[ $dep_ready == true ]] ; then
                ready_count=$((ready_count + 1))
            fi
        done
        echo "Ready: $ready_count / ${#deployments[@]}"
        if [[ $ready_count -eq ${#deployments[@]} ]] ; then
            return 0
        fi
    done
    return 1
}
