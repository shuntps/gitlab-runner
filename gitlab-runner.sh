#! /bin/bash

# Constant
readonly CONFIG_FILE='.gr_config'

load_config() {
  if [[ -e ${CONFIG_FILE} ]]; then
    source ${CONFIG_FILE}
  else
    create_config
  fi
}

create_config(){
  echo "There is no file!"

  echo "What is the GitLab URL :"
  read -r gitlab_url

  echo "What is the GitLab registration token :"
  read -rs gitlab_registration_token

  echo "gitlab_url=\"${gitlab_url}\"" > ${CONFIG_FILE}
  echo "gitlab_registration_token=\"${gitlab_registration_token}\"" >> ${CONFIG_FILE}

  echo "The file ${CONFIG_FILE} was created with this content."
  echo "Please add the line below on your .gitignore"
  echo "${CONFIG_FILE}"
}

runner_register() {
  docker volume create gitlab-runner-config
  docker volume create gitlab-runner-home

  docker run --rm -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:alpine register \
    --non-interactive \
    --url "${gitlab_url}" \
    --registration-token "${gitlab_registration_token}" \
    --executor "docker" \
    --docker-image tmaier/docker-compose \
    --description "My GitLab Runner docker" \
    --tag-list "$(hostname -a)-docker" \
    --run-untagged="false" \
    --docker-privileged \
    --docker-volumes "/certs/client"
    # --access-level="not_protected"
    # --locked="false" \
}

runner_start() {
  runner_name="gitlab-runner-$(hostname -a)"
  docker run -d --name "${runner_name}" --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    -v gitlab-runner-home:/home/gitlab-runner \
    gitlab/gitlab-runner:alpine
}

main() {
  echo "My GitLab Runner"
  load_config
  runner_register
  runner_start
}

main "$@"