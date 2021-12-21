# todo あとでcommon.jsonのProjectNameの値と共通で管理できるようにしたい（二重管理をやめたい
stackName := example
# .envファイルを読み込み
# bucketNameなどの引数を入力するのが毎回面倒なので.envから参照する
include .env
environmentVariables:=$(shell sed -ne 's/ *\#.*$$//; /./ s/=.*$$// p' .env )

ifeq ($(target), )
	@echo "you must add argument target"
	@exit 1
endif

# スタックを固定するためstackNameはMakefileで定義された物でなければならない
ifneq ($(stackName), example)
	@echo "stackName must be defined variable in Makefile"
	@exit 1
endif

# check arguments correctly
# make test target="test"
test:
	echo "target is $(target)"
	echo "stackName is $(stackName)"
	echo "environmentVariables is $(environmentVariables)"
	echo "Environment is $(Environment)"

####### deploy #######

# stackNameの引数はMakefile内に定義してあるので不要
# jq -r 'keys[] as $k | "\($k)=\(.[$k])"' parameters/sqs.json
# jqを試してみたがMakefileのコマンドと組み合わせてparameterを渡そうとしたが難しいのjsファイル（deploy.js）で実行する
# Environmentは与えければdevがdefault
deploy:
	cd scripts/cloudformation && node deploy.js -t $(target) -e $(Environment)

# parameter-overridesが存在する場合はdeploy-with-paramsを実行
deploy-with-params:
	aws cloudformation deploy \
		--stack-name $(stackName)-$(target) \
		--template-file $(target).yaml \
		--parameter-overrides \
		 $(params) \
		--capabilities CAPABILITY_NAMED_IAM

# parameterが存在しない場合はparameter-overridesのオプションを入れることができない
# parameter-overridesのオプションは空白も許容されない
deploy-without-params:
	aws cloudformation deploy \
		--stack-name $(stackName)-$(target) \
		--template-file $(target).yaml \
		--capabilities CAPABILITY_NAMED_IAM

####### update #######
# すでにスタックがあってバージョン情報などを更新する時

# バージョン情報や環境変数などの要素を更新したいときに実行する
# change-set-nameはversion1.0.1などの小数点は入力できない
update-package:
	aws cloudformation create-change-set \
		--stack-name $(stackName)-$(target) \
		--template-body file://$(target).yaml \
		--change-set-name $(changeSetName) \
		--capabilities CAPABILITY_IAM

# スタックを更新するための実行コマンド
# 事前に同じchangeSetNameをupdate-packageで行なってからexecute-update-packageを実行することができる
execute-update-package:
	aws cloudformation execute-change-set \
		--stack-name $(stackName)-$(target) \
		--change-set-name $(changeSetName)

# 途中まで入力したchange-setを出力する
list-change-set:
	aws cloudformation list-change-sets \
		--stack-name $(stackName)-$(target)

####### validate #######

validate:
	aws cloudformation validate-template \
		--template-body file://$(target).yaml
