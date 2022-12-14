alias aws_shell="$HOME/storage/ssh/connect.sh"
alias cls="clear"
alias shell="python manage.py shell"
alias runserver="python manage.py runserver"
alias mm="python manage.py makemigrations"
alias migrate="python manage.py migrate"
alias -g gcp="git cherry-pick"
alias -g vim="hx"
alias -g nvim="hx"
alias zshconf="hx $HOME/.zshrc"
alias fmk="code $HOME/.zsh/fmk"
# creates token for loggin in kubernetes dashboard for admin-user
alias ktoken="kubectl -n kubernetes-dashboard create token admin-user | tr -d '\n' | pbcopy"

# Custom functions

# Copies latest commit from current branch or the branch specified
function clc {
   COLOR_GREEN="\033[0;32m"
   COLOR_RESET="\033[0m"
   [[ -z $1 ]] && BRANCH=$(git rev-parse --abbrev-ref HEAD) || BRANCH=$1
   LAST_COMMIT_SHA=$(git rev-parse $BRANCH | tail -n 1)
   echo "$LAST_COMMIT_SHA" | tr -d '\n' | pbcopy
   echo "Copied ${COLOR_GREEN}${LAST_COMMIT_SHA} ${COLOR_RESET}from ${BRANCH}."
   unset COLOR_GREEN COLOR_RESET LAST_COMMIT_SHA BRANCH
}

# Prints latest commit from current branch or the branch specified
function cle {
    COLOR_GREEN="\033[0;32m"
    COLOR_RESET="\033[0m"
    [[ -z $1 ]] && BRANCH=$(git rev-parse --abbrev-ref HEAD) || BRANCH=$1
    LAST_COMMIT_SHA=$(git rev-parse $BRANCH | tail -n 1)
    echo "$LAST_COMMIT_SHA" | tr -d '\n'
    unset COLOR_GREEN COLOR_RESET LAST_COMMIT_SHA BRANCH
}

# Cherry pick the lastest commit of specified branch into current branch
pick() {
  if [[ $1 = *[!\ ]* ]];
    then
	cle $1 | xargs git cherry-pick
    else
  	echo "Specify a branch. Cannot cherry-pick from the same branch"
  fi
}


# AWS jumper with parameter for dev and prod environment
jumper() {
 if [[ -z "$1" ]] || [[ -z "$2" ]];
   then
	echo "jumper <env(dev/prod)> <ip>. Use this format"
 elif [[ $1 = "dev" ]];
   then
	ssh -J bastiondev -i ~/.ssh/wealthy-dev-mumbai.pem ec2-user@$2
 elif [[ $1 = "prod" ]];
   then
   	ssh -J bastionprod -i ~/.ssh/Production-Docker-Mumbai.pem ec2-user@$2
 else
	echo "No key exist for $1"
 fi
}

# Creating git PR with cli
cpr() {
  if [[ $1 = *[!\ ]* ]] && [[ -z "$2" ]] && [[ -z "$3" ]];
    then
        gh pr create --title $1 -B development -f -R wealthy/hydra
  elif [[ $2 = *[!\ ]* ]] && [[ -z "$3" ]];
    then
	gh pr create --title $1 -B $2 -f -R wealthy/hydra
  elif [[ $3 = *[!\ ]* ]];
    then
	gh pr create --title $1 -B $2 -f -R $3
  else
	echo "Specify <title> <branch_name> <remote>. Title is mandatory. Branch = development(default). remote = wealthy/hydra (default)"
  fi
}

# ssh into instance containing kubernetes pod
ssh_pod() {
DEFAULT_K_NAMESPACE=`kubectl config view --minify -o jsonpath='{..namespace}'` 
if [[ -z $1 ]] || [[ -z $2 ]];
 then
	echo "Need env name, pod id. Use ssh_pod <env(dev/prod)> <pod_id> <namespace>. namespace is optional($DEFAULT_K_NAMESPACE is used if not provided)"
elif [[ -z $3 ]];
 then
	node_ip=`kubectl describe pod $2 -n $DEFAULT_K_NAMESPACE | rg Node: | rg -oe '/([0-9].*)' -r '$1'`
	if [[ -z $node_ip ]];
         then
		echo "Found no $1 ip for $2 in $DEFAULT_K_NAMESPACE namespace"
		unset DEFAULT_K_NAMESPACE
		unset node_ip
		return 1
	fi
	echo "Connecting to pod $2 in $DEFAULT_K_NAMESPACE namespace in $1"
	jumper $1 $node_ip
	unset node_ip
else
	NODE_IP=`kubectl describe pod $2 -n $3 | rg Node: | rg -oe '/([0-9].*)' -r '$1'`
	if [[ -z $NODE_IP ]];
         then
                echo "Found no $1 ip for $2 in $3 namespace"
                unset DEFAULT_K_NAMESPACE
                unset NODE_IP
                return 1
        fi
	echo "Connecting to node of pod $2 in $3 namespace in $1 environment"
	jumper $1 $NODE_IP
	unset NODE_IP
fi
unset DEFAULT_K_NAMESPACE
}

# Switch kubernetes context
ctx() {
 case $1 in 
  local)
	kubectx kind-kind
	;;
  dev)
	kubectx arn:aws:eks:ap-south-1:614358145679:cluster/WealthyDevelopment
	;;
  prod)
	echo "Not configured yet"
	;;
  *)
	kubectx
	;;
 esac
}

# show/update/assign iam role to a ec2 instance
function eimr {
  if [[ -z $1 ]] || [[ -z $2 ]] || [[ $1 != "show" && -z $3 ]];
    then
      echo "Need operation, instance id and role name. Use ec2_iam_role <operation(assign/update/show)> <instance_id> <role_name>"
  elif [[ $1 == "show" ]];
  then
    aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$2" 
  elif [[ $1 == "assign" || $1 == "update" ]];
    then
    role_exist=`aws iam get-role --role-name $3`
    [[ -z $role_exist ]] && unset role_exist && return 1
    if [[ $1 == "update" ]];
      then
        association_id=`aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$2" | xargs echo | sed -rn 's/.*AssociationId: ([(a-zA-Z0-9)|-]*),.*/\1/p'`
        [[ -z $association_id ]] && echo "Either instance id is invalid or No association id exist for instance $2. Try using the assign operation." && unset association_id && return 1
        aws ec2 disassociate-iam-instance-profile --association-id $association_id
        unset association_id
    fi
    echo "Assigning role $3 to instance $2"
    aws ec2 associate-iam-instance-profile --iam-instance-profile Name=$3 --instance-id $2
    unset role_exist
  else
    echo "Invalid command ec2_iam_role $1 $2 $3. Use ec2_iam_role <operation(assign/update/show)> <instance_id> <role_name>"
  fi
  return 0
}


# Show ec2 instance id for a kubernetes node with its name
function kgid {
  if [[ -z $1 ]];
    then
      echo "Need node name. Use kgid <node_name>"
      return 1
  else
    kubectl describe node $1 | grep ProviderID | sed -nE 's/.*(i-.*)/\1/p'
  fi
  return 0
}

# Prints Arn for kubernetes nodes
function pni {
  kubectl get nodes -o=jsonpath='{range .items[*]}{.spec.providerID}{"\n"}'
}

# Prints role of an ec2 instance
function girole {
  [[ -z $1 ]] && echo "Need instance id. Use gri <instance_id>" && return 1
  eimr show $1 | xargs echo | sed -nr 's/.*Arn.*instance-profile\/(.*), Id.*/\1/p'
  return 0
}

# Change role of all kubernetes nodes to specified
function nrc {
  [[ -z $1 ]] && echo "Need role name. Use nrc <role_name>" && return 1
  local a=`kubectl get nodes -o=jsonpath='{range .items[*]}{.spec.providerID}{"\t"}'`
  local arr=($(echo $a | tr "[\t]" "\n"))
  for f in $arr; do
    local instance_id=`echo $f | sed -nE 's/.*(i-.*)/\1/p'`
    [[ -z $instance_id ]]  && continue
    echo "================$instance_id START======================\n"
    echo "Updating role for instance $instance_id with role $1"
    local ra=`girole $instance_id`
    if [[ $ra == $1 ]]; 
      then
        echo "Instance $instance_id already has role $1"
    elif eimr update $instance_id $1;
      then
        echo "Done updating role $1 for instance $instance_id"
    else
      echo "Error in updating role $1 for instance $instance_id"
    fi
    echo "\n==================$instance_id FINISHED =======================\n\n"
  done
}

#Runs aws codepipeline
function cpline {
  [[ -z $2 ]] && aws_profile=`[[ -z $AWS_PROFILE ]] && echo default || echo $AWS_PROFILE` || aws_profile=$2
  [[ -z $1 ]] && echo "Need pipeline name. Use cpline <pipeline_name> <profile_name(optional)>. Uses default/configured profile if not specified." && return 1
  aws codepipeline start-pipeline-execution --name $1 --profile $aws_profile
  unset aws_profile
}

# Prints pid of process running at specified port
function find_process {
  [[ -z $1 ]] && echo "Need port number. Use find_process <port_number>" && return 1
  lsof -nP -iTCP -sTCP:LISTEN | grep $1 | xargs echo
  pid=`lsof -nP -iTCP -sTCP:LISTEN | grep $1 | sed -nrE "s/.* ([0-9]+) \`whoami\`.*/\1/p"`
  echo "PID = $pid"
  unset pid
}

# Kills process running at specified port
function stop_process {
    [[ -z $1 ]] && echo "Need port number. Use stop_process <port_number>" && return 1
    pid=`lsof -nP -iTCP -sTCP:LISTEN | grep $1 | sed -nrE "s/.* ([0-9]+) \`whoami\`.*/\1/p"`
    [[ -z $pid ]] && echo "No process at port $1" && return 1
    kill -9 $pid
    echo "Process at pid $pid is killed"
    unset pid
}