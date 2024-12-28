alias c="clear"
alias nvim="vim"

alias follow="journalctl --no-pager -fu "
alias watch_rmq="/root/Capstone-Group-10/.watch_rmq.sh"
alias watch_mdb='watch -ctn0.2 -e "mariadb -u haproxy_check -e \"SHOW STATUS LIKE'" 'wsrep_incoming_addresses'"';"\"'

alias desc_mdb="mariadb -u admin -p -e \"USE information_schema; SELECT TABLE_NAME 'Table', COLUMN_NAME 'Field', COLUMN_TYPE 'Type', IS_NULLABLE 'Null', COLUMN_KEY 'Key', COLUMN_DEFAULT 'Default', EXTRA 'Extra' FROM information_schema.columns WHERE table_schema = 'applicare' ORDER BY TABLE_NAME;\""
alias rmq_proxy="/root/Capstone-Group-10/frontend/src/rabbitmq-proxy.php"
alias update_fe="rm -r /var/www/applicare/*; scp -r /root/Capstone-Group-10/frontend/* /var/www/applicare; systemctl reload apache2"
