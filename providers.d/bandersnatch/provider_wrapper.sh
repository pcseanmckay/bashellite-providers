bashelliteProviderWrapperBandersnatch() {

  # Perform some pre-sync checks
  read _ pypi_status_code _ < <(curl -sI "${_n_repo_url}");

  if [[ "${pypi_status_code:0:1}" < "4" ]]; then
    utilMsg INFO "$(utilTime)" "The pypi mirror appears to be up; sync should work...";
  else
    utilMsg FAIL "$(utilTime)" "The pypi mirror appears to be down/invalid/inaccessible; exiting...";
    return 1;
  fi

  local directory_parameter="$(grep -oP "(?<=(^directory = )).*" ${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf)"
  if [[  "${directory_parameter}" != "${_r_mirror_tld}/${_n_repo_name}" ]]; then
    utilMsg WARN "$(utilTime)" "The \"directory\" parameter (${directory_parameter}) in provider.conf does not match mirror location (${_r_mirror_tld}/${_n_repo_name})..."
  fi

  local config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"
  local tmp_config_file="${HOME}/.bashellite/tmp_${_n_repo_name}_provider.conf"

  cat /dev/null > ${tmp_config_file}

  IFS=$'\n'
  for line in $(cat ${config_file}); do
    if [[ ${line} =~ ^directory[[:blank:]]*[=][[:blank:]]*[[:alnum:]/]+ ]]; then
      echo "directory = ${_r_mirror_tld}/${_n_repo_name}" >> ${tmp_config_file}
    else
      echo "${line}" >> ${tmp_config_file}
    fi
  done
  unset IFS

  utilMsg INFO "$(utilTime)" "Proceeding with sync of repo (${_n_repo_name})..."
  # If dryrun is true, perform dryrun
  if [[ ${_r_dryrun} ]]; then
    utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error..."
  # If dryrun is not true, perform real run
  else
    ${_r_providers_tld}/bandersnatch/exec/bin/bandersnatch -c "${tmp_config_file}" mirror;
    if [[ "${?}" == "0" ]]; then
      utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error...";
    else
      utilMsg WARN "$(utilTime)" "Sync of repo (${_n_repo_name}) did NOT complete without error...";
    fi
  fi

}
