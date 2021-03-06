#!/usr/bin/env bash

## 路径
ShellDir=${JD_DIR:-$(
  cd $(dirname $0)
  pwd
)}
[ ${JD_DIR} ] && HelpJd=js || HelpJd=js.sh
ScriptsDir=${ShellDir}/scripts
ConfigDir=${ShellDir}/config
FileConf=${ConfigDir}/config.sh
FileConfSample=${ShellDir}/sample/config.sh.sample
LogDir=${ShellDir}/log
FileShare=${ShellDir}/log/export_sharecodes/sharecodes.sh
ListScripts=($(
  cd ${ScriptsDir}
  ls *.js | grep -E "j[drxs]_"
))
ListCron=${ConfigDir}/crontab.list

## 导入config.sh
function Import_Conf() {
  if [ -f ${FileConf} ]; then
    . ${FileConf}
    if [ -z "${Cookie1}" ]; then
      echo -e "请先在config.sh中配置好Cookie...\n"
      exit 1
    fi
  else
    echo -e "配置文件 ${FileConf} 不存在，请先按教程配置好该文件...\n"
    exit 1
  fi
}

## 导入互助码sharecodes.sh
function Import_Share() {
  if [ -f ${FileShare} ]; then
    . ${FileShare}
  fi
}

## 更新crontab
function Detect_Cron() {
  if [[ $(cat ${ListCron}) != $(crontab -l) ]]; then
    crontab ${ListCron}
  fi
}

## 京东用户数量UserSum  
function Count_UserSum() {
  for ((i = 1; i <= 200; i++)); do
    Tmp=Cookie$i
    CookieTmp=${!Tmp}
    [[ ${CookieTmp} ]] && UserSum=$i || break
  done

  for ((d = 201; d <= 1000; d++)); do
    Del=Cookie$d
    sed -i "/${!Del}/d" ${FileConf} || break
  done
}

## 组合京东Cookie和互助码子程序
function Combin_Sub() {
  CombinAll=""
  if [[ ${AutoHelpOther} == true ]] && [[ $1 == ForOther* ]]; then

    ForOtherAll=""
    MyName=$(echo $1 | perl -pe "s|ForOther|My|")

    for ((m = 1; m <= ${UserSum}; m++)); do
      TmpA=${MyName}$m
      TmpB=${!TmpA}
      ForOtherAll="${ForOtherAll}@${TmpB}"
    done

    for ((n = 1; n <= ${UserSum}; n++)); do
      for num in ${TempBlockCookie}; do
        [[ $n -eq $num ]] && continue 2
      done
      CombinAll="${CombinAll}&${ForOtherAll}"
    done

  else
    for ((i = 1; i <= ${UserSum}; i++)); do
      for num in ${TempBlockCookie}; do
        [[ $i -eq $num ]] && continue 2
      done
      Tmp1=$1$i
      Tmp2=${!Tmp1}
      CombinAll="${CombinAll}&${Tmp2}"
    done
  fi

  echo ${CombinAll} | perl -pe "{s|^&||; s|^@+||; s|&@|&|g; s|@+&|&|g; s|@+|@|g; s|@+$||}"
}

## 组合Cookie、Token与互助码
function Combin_All() {
  ## 京东cookie
  export JD_COOKIE=$(Combin_Sub Cookie)
  ## 京东cookie_wskey
  export JD_WSKEY=$(Combin_Sub Wskey)
  ## 京东账号备注
  export JD_COOKIENAME=$(Combin_Sub CookieName)
  ## 京喜财富岛提现token
  export JXNCTOKENS=$(Combin_Sub JxncToken)
  ## 东东农场(jd_fruit.js)
  export FRUITSHARECODES=$(Combin_Sub ForOtherFruit)
  ## 东东萌宠(jd_pet.js)
  export PETSHARECODES=$(Combin_Sub ForOtherPet)
  ## 种豆得豆(jd_plantBean.js)
  export PLANT_BEAN_SHARECODES=$(Combin_Sub ForOtherBean)
  ## 东东工厂(jd_jdfactory.js)
  export DDFACTORY_SHARECODES=$(Combin_Sub ForOtherJdFactory)
  ## 京喜工厂(jd_dreamFactory.js)
  export DREAM_FACTORY_SHARE_CODES=$(Combin_Sub ForOtherDreamFactory)
  ## 京东赚赚(jd_jdzz.js)
  export JDZZ_SHARECODES=$(Combin_Sub ForOtherJdzz)
  ## 疯狂的Joy(jd_crazy_joy.js)
  export JDJOY_SHARECODES=$(Combin_Sub ForOtherJoy)
  ## 口袋书店(jd_bookshop.js)
  export BOOKSHOP_SHARECODES=$(Combin_Sub ForOtherBookShop)
  ## 签到领现金(jd_cash.js)
  export JD_CASH_SHARECODES=$(Combin_Sub ForOtherCash)
  ## 京喜农场(jd_jxnc.js)
  export JXNC_SHARECODES=$(Combin_Sub ForOtherJxnc)
  ## 闪购盲盒(jd_sgmh.js)
  export JDSGMH_SHARECODES=$(Combin_Sub ForOtherSgmh)
  ## 京喜财富岛(jd_cfd.js)
  export JDCFD_SHARECODES=$(Combin_Sub ForOtherCfd)
  ## 环球挑战赛(jd_global.js)
  export JDGLOBAL_SHARECODES=$(Combin_Sub ForOtherGlobal)
  ## 东东健康社区(jd_health.js)
  export JDHEALTH_SHARECODES=$(Combin_Sub ForOtherHealth)
  ## 城城领现金(jd_city.js)
  export CITY_SHARECODES=$(Combin_Sub ForOtherCity)
  ## 手机狂欢城(jd_carnivalcity.js)
  export JD818_SHARECODES=$(Combin_Sub ForOtherCarnivalcity)
}

## 转换JD_BEAN_SIGN_STOP_NOTIFY或JD_BEAN_SIGN_NOTIFY_SIMPLE
function Trans_JD_BEAN_SIGN_NOTIFY() {
  case ${NotifyBeanSign} in
  0)
    export JD_BEAN_SIGN_STOP_NOTIFY="true"
    ;;
  1)
    export JD_BEAN_SIGN_NOTIFY_SIMPLE="true"
    ;;
  esac
}

## 转换UN_SUBSCRIBES 取关参数，取关商品，取关店铺，遇到此商品不取关(完整的商品信息)，遇到此店铺不取关(完整的店铺名称)
function Trans_UN_SUBSCRIBES() {
  export UN_SUBSCRIBES="${goodPageSize}\n${shopPageSize}\n${stopGoods}\n${stopShop}"
}

## 申明全部变量
function Set_Env() {
  Count_UserSum
  Combin_All
  Trans_JD_BEAN_SIGN_NOTIFY
  Trans_UN_SUBSCRIBES
}


## 随机延迟
function Random_Delay() {
  if [[ -n ${RandomDelay} ]] && [[ ${RandomDelay} -gt 0 ]]; then
    CurMin=$(date "+%-M")
    if [[ ${CurMin} -gt 2 && ${CurMin} -lt 30 ]] || [[ ${CurMin} -gt 31 && ${CurMin} -lt 59 ]]; then
      CurDelay=$((${RANDOM} % ${RandomDelay} + 1))
      echo -e "\n命令未添加 \"now\"，随机延迟 ${CurDelay} 秒后再执行任务，如需立即终止，请按 CTRL+C...\n"
      sleep ${CurDelay}
    fi
  fi
}

## 使用说明
function Help() {
  echo -e "本脚本的用法为："
  echo -e "1. bash ${HelpJd} xxx      # 如果设置了随机延迟并且当时时间不在0-2、30-31、59分内，将随机延迟一定秒数"
  echo -e "2. bash ${HelpJd} xxx now  # 无论是否设置了随机延迟，均立即运行"
  echo -e "3. bash ${HelpJd} hangup   # 重启挂机程序"
  echo -e "4. bash ${HelpJd} resetpwd # 重置控制面板用户名和密码"
  echo -e "\n针对用法1、用法2中的\"xxx\"，可以不输入后缀\".js\"，另外，如果前缀是\"jd_\"的话前缀也可以省略。"
  echo -e "当前有以下脚本可以运行（仅列出以jd_、jr_、jx_、js_开头的脚本）："
  cd ${ScriptsDir}
  for ((i = 0; i < ${#ListScripts[*]}; i++)); do
    Name=$(grep "new Env" ${ListScripts[i]} | awk -F "'|\"" '{print $2}')
    echo -e "$(($i + 1)).${Name}：${ListScripts[i]}"
  done
}

## nohup
function Run_Nohup() {
  if [[ $(ps -ef | grep "${js}" | grep -v "grep") != "" ]]; then
    ps -ef | grep "${js}" | grep -v "grep" | awk '{print $2}' | xargs kill -9
  fi
  [ ! -d ${LogDir}/${js} ] && mkdir -p ${LogDir}/${js}
  LogTime=$(date "+%Y-%m-%d-%H-%M-%S")
  LogFile="${LogDir}/${js}/${LogTime}.log"
  nohup node ${js}.js >${LogFile} &
}

## 运行挂机脚本
function Run_HangUp() {
  HangUpJs="jd_crazy_joy_coin"
  cd ${ScriptsDir}
  for js in ${HangUpJs}; do
    Import_Conf ${js} && Set_Env
    if type pm2 >/dev/null 2>&1; then
      pm2 stop ${js}.js 2>/dev/null
      pm2 flush
      pm2 start -a ${js}.js --watch "${ScriptsDir}/${js}.js" --name="${js}"
    else
      Run_Nohup >/dev/null 2>&1
    fi
  done
}

## 重置密码
function Reset_Pwd() {
  cp -f ${ShellDir}/sample/auth.json ${ConfigDir}/auth.json
  echo -e "控制面板重置成功，用户名：admin，密码：adminadmin\n"
}

## 运行京东脚本
function Run_Normal() {
  Import_Conf $1 && Detect_Cron && Set_Env

  FileNameTmp1=$(echo $1 | perl -pe "s|\.js||")
  FileNameTmp2=$(echo $1 | perl -pe "{s|jd_||; s|\.js||; s|^|jd_|}")
  SeekDir="${ScriptsDir} ${ScriptsDir}/backUp ${ConfigDir}"
  FileName=""
  WhichDir=""

  for dir in ${SeekDir}; do
    if [ -f ${dir}/${FileNameTmp1}.js ]; then
      FileName=${FileNameTmp1}
      WhichDir=${dir}
      break
    elif [ -f ${dir}/${FileNameTmp2}.js ]; then
      FileName=${FileNameTmp2}
      WhichDir=${dir}
      break
    fi
  done

  if [ -n "${FileName}" ] && [ -n "${WhichDir}" ]; then
    [ $# -eq 1 ] && Random_Delay
    LogTime=$(date "+%Y-%m-%d-%H-%M-%S")
    LogFile="${LogDir}/${FileName}/${LogTime}.log"
    [ ! -d ${LogDir}/${FileName} ] && mkdir -p ${LogDir}/${FileName}
    cd ${WhichDir}
    node ${FileName}.js | tee ${LogFile}
  else
    echo -e "\n在${ScriptsDir}、${ScriptsDir}/backUp、${ConfigDir}三个目录下均未检测到 $1 脚本的存在，请确认...\n"
    Help
  fi
}

## 命令检测
case $# in
0)
  echo
  Help
  ;;
1)
  if [[ $1 == hangup ]]; then
    Run_HangUp
  elif [[ $1 == resetpwd ]]; then
    Reset_Pwd
  else
    Run_Normal $1
  fi
  ;;
2)
  if [[ $2 == now ]]; then
    Run_Normal $1 $2
  else
    echo -e "\n命令输入错误...\n"
    Help
  fi
  ;;
*)
  echo -e "\n命令过多...\n"
  Help
  ;;
esac
