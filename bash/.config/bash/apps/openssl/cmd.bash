# base64 encodes to and decodes from base64
base64 () {
  while getopts ":d:e:" opt; do
    case $opt in
      d)
        echo $OPTARG | openssl enc -d -base64
        ;;
      e)
        openssl base64<<<"$OPTARG"
        ;;
      \?)
        echo "[-] Invalid option: -$OPTARG" >&2
        ;;
      :)
        echo "[!] Option -$OPTARG requires an argument"
        return 1
        ;;
    esac
  done

  # reset because we're probably going to be in the same shell for a while
  OPTIND=1
}
