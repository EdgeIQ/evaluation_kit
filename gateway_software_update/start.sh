PS3="Please make a selection:
  1] Provision Gateway Device (gateway_provision.sh)
  2] Load EdgeIQ Configuration (create_edgeiq_configuration.sh)
  3] Execute Software Update Command (execute_software_update.sh)
  "

select opt in 1 2 3 4 5 quit; do

  case $opt in
    1)
      echo "Running gateway_provision.sh using settings from setenv.sh..."
      ;;
    2)

      ;;
    3)
      echo
      ;;
    *)
      echo "Invalid option: $REPLY\n
      YOU DIDN'T SAY THE MAGIC WORD!\n
      YOU DIDN'T SAY THE MAGIC WORD!\n
      YOU DIDN'T SAY THE MAGIC WORD!\n
      "
      ;;
  esac
done
