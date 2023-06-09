# .envファイルを読み込み
# bucketNameなどの引数を入力するのが毎回面倒なので.envから参照する
include .env
environmentVariables:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' .env )
templateFile = $(stackTemplatePath)/$(targetStackTemplate).yaml

profile = $(Profile)

region = $(Region)

stackTemplatePath = $(shell pwd)
targetStackTemplate = vpc

# デプロイ用のサブモジュールの追加
add-submodule:
	git submodule add git@github.com:misupopo/cloudformation-deploy-script cloudformation-deploy-script

clone-submodule:
	git clone git@github.com:misupopo/cloudformation-deploy-script --recurse-submodules

# スタック名
stackName := $(shell jq -r .ProjectName parameters/$(Environment)/common.json)

#ifeq ($(target), )
#	@echo "you must add argument target"
#	@exit 1
#endif

# check arguments correctly
# make test target="test"
test:
	echo "target is $(target)"
	echo "stackName is $(stackName)"
	echo "environmentVariables is $(environmentVariables)"
	echo "Environment is $(Environment)"
	echo "Profile is $(Profile)"

####### deploy #######

# stackNameの引数はMakefile内に定義してあるので不要
# Environmentは与えければdevがdefault
#deploy:
#	cd scripts/cloudformation && npx ts-node deploy.ts -t $(target) -e $(Environment)

# 基本的にはこれを使う
# make deploy parameterTarget=vpc targetStackTemplate=vpc
deploy:
	cd ./cloudformation-deploy-script && \
	make deploy \
	environment="$(Environment)" \
	stackTemplatePath="$(stackTemplatePath)" \
	parameterTarget="$(parameterTarget)" \
	targetStackTemplate="$(targetStackTemplate)" \
	profile="$(profile)" \
	region="$(region)"

# parameter-overridesが存在する場合はdeploy-with-paramsを実行
deploy-with-params:
	aws cloudformation deploy \
		--stack-name $(stackName)-$(target) \
		--template-file $(target).yaml \
		--parameter-overrides \
		 $(params) \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile $(Profile) \

# parameterが存在しない場合はparameter-overridesのオプションを入れることができない
# parameter-overridesのオプションは空白も許容されない
deploy-without-params:
	aws cloudformation deploy \
		--stack-name $(stackName)-$(target) \
		--template-file $(target).yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--profile $(Profile) \

####### update #######
# すでにスタックがあってバージョン情報などを更新する時

# バージョン情報や環境変数などの要素を更新したいときに実行する
# change-set-nameはversion1.0.1などの小数点は入力できない
update-package:
	aws cloudformation create-change-set \
		--stack-name $(stackName)-$(target) \
		--template-body file://$(target).yaml \
		--change-set-name $(changeSetName) \
		--capabilities CAPABILITY_IAM \
		--profile $(Profile) \

# スタックを更新するための実行コマンド
# 事前に同じchangeSetNameをupdate-packageで行なってからexecute-update-packageを実行することができる
execute-update-package:
	aws cloudformation execute-change-set \
		--stack-name $(stackName)-$(target) \
		--change-set-name $(changeSetName)

# 途中まで入力したchange-setを出力する
list-change-set:
	aws cloudformation list-change-sets \
		--stack-name $(stackName)-$(target) \
        --profile $(Profile) \

####### validate #######

validate:
	aws cloudformation validate-template \
		--template-body file://$(target).yaml \
        --profile $(Profile) \
