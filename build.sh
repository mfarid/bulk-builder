LOG_FILE="log_"`date +%Y-%m-%d_%H_%M_%S`".log"
./_build.sh $LOG_FILE >> "$LOG_FILE" 2>&1 &
tail -f $LOG_FILE
 
