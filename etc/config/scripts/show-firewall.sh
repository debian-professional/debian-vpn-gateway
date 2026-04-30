bashfor table in filter nat mangle raw security; do
    echo "========================================"
    echo "TABLE: $table"
    echo "========================================"
    iptables -t $table -L -n -v --line-numbers
    echo ""
done

