ssh v8rv02 "cd /home/luyahan/v8-riscv/v8/;git fetch riscv; git checkout riscv/riscv64"
if [ $? -ne 0 ]; then
    echo "ERROR: sync riscv/riscv64 failed" | tee -a log-result.txt
    exit 1
fi

ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/;git log  -1" > commit.txt

ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/;gn gen ./out/riscv64.native.debug.auto --args='is_component_build=false is_debug=true target_cpu=\"riscv64\" v8_target_cpu=\"riscv64\" use_goma=false goma_dir=\"None\" treat_warnings_as_errors=false symbol_level = 0'"
if [ $? -ne 0 ]; then
    echo "ERROR: gn gen riscv64.native.debug.auto failed" | tee -a log-result.txt
    echo "ERROR: gn gen riscv64.native.debug.auto failed" 
    exit 1
fi

ssh v8rv02 "source ~/.bash_profile;cd /home/luyahan/v8-riscv/v8/out/riscv64.native.debug.auto;ninja -t clean;ninja -j32"
if [ $? -ne 0 ]; then
    echo "ERROR: build riscv64.native.debug.auto failed" | tee -a log-result.txt
    exit 1
fi

ssh v8rv02 "cd ~/v8-riscv/v8/;tar czvf v8-riscv64-debug.tar.gz --exclude=*.git* --exclude=*/out/*obj* --exclude=*/out/*gen* --exclude=*/out/*clang* ./test ./tools ./out/riscv64.native.debug"
if [ $? -ne 0 ]; then
    echo "ERROR: tar czvf v8-riscv64-debug.tar.gz" | tee -a log-result.txt
    exit 1
fi
ssh v8rv02 "cd ~/v8-riscv/v8/;mv v8-riscv64-debug.tar.gz ~/"
scp v8rv02:~/v8-riscv64-debug.tar.gz ./
if [ $? -ne 0 ]; then
    echo "ERROR: scp v8-riscv64-debug.tar.gz" | tee -a log-result.txt
    exit 1
fi

tar xzvf v8-riscv64-debug.tar.gz -C ./v8-riscv64-debug-auto/
cd v8-riscv64-debug-auto
rm log-result.txt
touch log-result.txt
date +"%Y-%m-%d %H:%M:%S" >> log-result.txt
echo "| Test Suite | Tests passed (run-rate)| Notes |" >> log-result.txt
echo "| - | - | - |" >> log-result.txt
for i in  wasm-js 
do
        python2 ./tools/run-tests.py --outdir=./out/riscv64.native.debug/ $i | tee log-$i.txt
        num=$(cat log-$i.txt  | sed -nr '/FAILED/p' | wc -l)
        if [ $num == 0 ]
        then
            result="success"
        else
            result="failed"
        fi
        cat log-$i.txt  | sed -nr '/Done$/p' | sed 's/.*\(+[ ]*[0-9]*\)[|| ]*[ ]*\(-[ ]*[0-9]*\).*/|'$i'|\1\/\2|'$result'|/g' >> log-result.txt
done
cd ~/
python2 sendmail.py commit.txt ./v8-riscv64-debug-auto/log-result.txt