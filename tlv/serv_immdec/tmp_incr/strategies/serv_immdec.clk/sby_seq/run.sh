STATUS=ERROR
sby -f serv_immdec.clk.sby > /dev/null && STATUS=$(awk '{print $1}' serv_immdec.clk/status)
echo $STATUS > status
case $STATUS in
    PASS)
        echo "Proved equivalence of partition 'serv_immdec.clk' using strategy 'sby_seq'"
    ;;
    FAIL)
        echo "Could not prove equivalence of partition 'serv_immdec.clk' using strategy 'sby_seq': partitions not equivalent"
    ;;
    UNKNOWN)
        echo "Could not prove equivalence of partition 'serv_immdec.clk' using strategy 'sby_seq': equivalence unknown"
    ;;
    TIMEOUT)
        echo "Could not prove equivalence of partition 'serv_immdec.clk' using strategy 'sby_seq': timeout"
    ;;
    *)
        cat serv_immdec.clk/ERROR 2> /dev/null
        echo "Execution of strategy 'sby_seq' on partition 'serv_immdec.clk' encountered an error."
        echo "More details can be found in 'tmp_incr/strategies/serv_immdec.clk/sby_seq/serv_immdec.clk/logfile.txt'."
        exit 1
    ;;
esac
exit 0

