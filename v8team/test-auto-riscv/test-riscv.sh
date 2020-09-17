rm log-result.txt
touch log-result.txt

ssh v8rv02 "cd /home/luyahan/v8-riscv/v8/;git fetch riscv; git checkout riscv/riscv64"
if [ $? -ne 0 ]; then
    echo "ERROR: sync riscv/riscv64 failed" | tee -a log-result.txt
    exit 1
fi

ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/;git log  -1" > commit.txt

target=''
function build_debug(){ 
    ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/;gn gen ./out/riscv64.native.debug.auto --args='is_component_build=false is_debug=true target_cpu=\"riscv64\" v8_target_cpu=\"riscv64\" use_goma=false goma_dir=\"None\" treat_warnings_as_errors=false symbol_level = 0'"
    target=$target"./out/riscv64.native.debug.auto"
    if [ $? -ne 0 ]; then
        echo "ERROR: gn gen riscv64.native.debug.auto failed" | tee -a log-result.txt
        exit 1
    fi

    ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/out/riscv64.native.debug.auto;ninja -j32"
    if [ $? -ne 0 ]; then
        echo "ERROR: build riscv64.native.debug.auto failed" | tee -a log-result.txt
        exit 1
    fi
}

function build_release(){
    ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/;gn gen ./out/riscv64.native.release.auto --args='is_component_build=false is_debug=false target_cpu=\"riscv64\" v8_target_cpu=\"riscv64\" use_goma=false goma_dir=\"None\" treat_warnings_as_errors=false symbol_level = 0'"
    target=$target"./out/riscv64.native.release.auto"
    if [ $? -ne 0 ]; then
        echo "ERROR: gn gen riscv64.native.release.auto failed" | tee -a log-result.txt
        exit 1
    fi
    ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/out/riscv64.native.release.auto;ninja -j32"
    if [ $? -ne 0 ]; then
        echo "ERROR: build riscv64.native.release.auto failed" | tee -a log-result.txt
        exit 1
    fi
}

if [[ "$1" == "debug" ]]; then
   echo "debug"
   build_debug
fi

if [[ "$1" == "release" ]]; then
   echo "release"
   build_release
fi

if [[ "$1" == "all" ]]; then
   echo "all"
   build_debug
   target=$target" "
   build_release
fi


ssh v8rv02 "cd ~/v8-riscv/v8/;tar czvf v8-riscv64.tar.gz --exclude=*.git* --exclude=*/out/*obj* --exclude=*/out/*gen* --exclude=*/out/*clang* ./test ./tools $target"
if [ $? -ne 0 ]; then
    echo "ERROR: tar czvf v8-riscv64.tar.gz" | tee -a log-result.txt
    exit 1
fi
ssh v8rv02 "cd ~/v8-riscv/v8/;mv v8-riscv64.tar.gz ~/"
scp v8rv02:~/v8-riscv64.tar.gz ./
if [ $? -ne 0 ]; then
    echo "ERROR: scp v8-riscv64.tar.gz" | tee -a log-result.txt
    exit 1
fi


rm -rf ./v8-riscv64-auto
mkdir v8-riscv64-auto
tar xzvf v8-riscv64.tar.gz -C ./v8-riscv64-auto/
if [ $? -ne 0 ]; then
    echo "ERROR: tar xzvf v8-riscv64.tar.gz" | tee -a log-result.txt
    exit 1
fi

function runtest() {
    echo $1 >> $2
    echo "| Test Suite | Tests passed (run-rate)| Notes |" >> $2
    echo "| - | - | - |" >> $2
    for i in  cctest unittests mjsunit intl message  inspector mkgrokdump debugger wasm-js wasm-spec-tests wasm-api-tests 
        do
            python2 ./tools/run-tests.py --outdir=$1 $i | tee log-$i.txt
            num=$(cat log-$i.txt  | sed -nr '/FAILED/p' | wc -l)
            if [ $num == 0 ]
            then
                result="success"
            else
                result="failed"
            fi
            cat log-$i.txt  | sed -nr '/Done$/p' | sed 's/.*\(+[ ]*[0-9]*\)[|| ]*[ ]*\(-[ ]*[0-9]*\).*/|'$i'|\1\/\2|'$result'|/g' >> $2
        done
}
cd v8-riscv64-auto
date +"%Y-%m-%d %H:%M:%S" >> ../log-result.txt
if [[ "$1" == "debug" ]]; then
    runtest ./out/riscv64.native.debug.auto ../log-result.txt
fi

if [[ "$1" == "release" ]]; then
    runtest ./out/riscv64.native.release.auto ../log-result.txt
fi

if [[ "$1" == "all" ]]; then
    runtest ./out/riscv64.native.debug.auto ../log-result.txt
    runtest ./out/riscv64.native.release.auto ../log-result.txt
fi
cd ~/
python2 sendmail.py commit.txt log-result.txt