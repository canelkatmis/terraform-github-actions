#!/bin/bash

function terraformDestroy {
  # Gather the output of `terraform destroy`.
  echo "apply: info: destroying Terraform configuration in ${tfWorkingDir}"
  destroyOutput=$(terraform destroy -auto-approve -input=false 2>&1)
  destroyExitCode=${?}

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${destroyExitCode} -eq 0 ]; then
    echo "destroy: info: successfully destroy Terraform configuration in ${tfWorkingDir}"
    echo "${destroyOutput}"
    echo
    exit ${destroyExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "destroy: error: failed to destroy Terraform configuration in ${tfWorkingDir}"
  echo "${destroyOutput}"
  echo

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    destroyCommentWrapper="#### \`terraform destroy\` Failed
<details><summary>Show Output</summary>
\`\`\`
${destroyOutput}
\`\`\`
</details>
*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    destroyCommentWrapper=$(stripColors "${destroyCommentWrapper}")
    echo "destroy: info: creating JSON"
    destroyPayload=$(echo '{}' | jq --arg body "${destroyCommentWrapper}" '.body = $body')
    destroyCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "destroy: info: commenting on the pull request"
    curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${destroyPayload}" "${destroyCommentsURL}" > /dev/null
  fi

  exit ${destroyExitCode}
}
