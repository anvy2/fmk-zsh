# Runs on every cd and activates the conda env if the trigger file exists
function chpwd {
	TRIGGER_FILE="./.condaenv"
  if [[ -f $TRIGGER_FILE ]];
    then
	source ./$TRIGGER_FILE
	conda activate $ENV_NAME
	unset ENV_NAME
	unset TRIGGER_FILE
  elif [[ $CONDA_DEFAULT_ENV != "base" ]];
    then    
	conda activate base
  fi
}

zsh-defer chpwd