os="undeclared"

commencementUbuntu(){
  echo "Please ensure the /etc/apt/sources.list file is correct"
  read -p "Press Enter to continue"
  apt update -y
  apt upgrade -y
}

commencementFedora(){
  echo "Fedora stuff"
}

detectOs(){

   if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $NAME in
            "Ubuntu")
                echo "detected os as ubuntu"
                os="ubuntu"
                commencementUbuntu
                ;;
            "Fedora")
                echo "detected os as fedora"
                os="fedora"
                commencementFedora
                ;;
              *)
                echo "detected un-suppored os"
                os="invalid"
                echo "$NAME"
                exit 1
                ;;
        esac
    else
        echo "/etc/os-release file not found. Unable to detect distro."
    fi

}

main(){
    detectOs
}

main
