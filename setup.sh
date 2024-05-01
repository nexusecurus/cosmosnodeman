#!/bin/bash

trap ctrl_c SIGINT

function ctrl_c() {

    case "$current_menu" in
        "under_node")
            main_menu
            ;;
        "under_install")
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "ABORTED!!!" \
            --msgbox "\nThe installation process was aborted.\n\n$pick INSTALLATION FAILED" 9 45
            main_menu
            ;;
        "under_monitor")
            main_menu
            ;;
        "monitor_info")
            monitor_menu
            ;;
        "under_monitor_info")
            monitor_info
            ;;
        "under_prune")
            monitor_menu
            ;;
        "validator_menu")
            main_menu
            ;;
        "validator_options")
            validator_menu
            ;;
        "under_remove")
            main_menu
            ;;
        "under_wallet")
            main_menu
            ;;
        "wallet_menu")
            main_menu
            ;;
        "under_main")
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "QUIT!!!" \
            --yesno "\nAre you sure you want to quit?" 7 50
            if [  $? -eq 0 ]; then
                clear
                exit 0
            else
                main_menu
            fi
            ;;
        *)
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "QUIT!!!" \
            --yesno "\nAre you sure you want to quit?" 7 50
            if [  $? -eq 0 ]; then
                clear
                exit 0
            else
                clear
                go_verify
            fi
            ;;
    esac

    sleep 4

    main_menu
}

current_menu=""

current_dir=$(pwd)

colored_text() {
    local color=$1
    local text=$2
    echo -n -e "\e[${color}m${text}\e[0m"
}

if [[ $EUID -eq 0 ]]; then
    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "WARNING!!!" \
    --msgbox "\nThis script cannot be run with sudo. \n\nRun the command as:  ./nodeinstaller.sh" 10 50
    clear
    exit 1
fi

if ! command -v ping &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y iputils-ping
fi

if ! ping -c 1 google.com >/dev/null 2>&1; then
    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "WARNING!!!" \
    --msgbox "\nNo internet connection. \n\nPlease check your internet connection and try again." 10 50
    clear
    exit 1
fi


check_dir() {

    if [ ! -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\n$pick Node is not installed..." 5 40
        sleep 3
        main_menu
        return
    fi
}

check_service_no_running() {

    if ! systemctl is-active --quiet "$CHAIN_NAME.service"; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --msgbox "\n$pick Node Service is not running...\n\n\nPlease start it first.:\n\nNode Operations Menu -> \"Start Node\" option" 12 55
        monitor_menu
    fi
}

check_service_running() {

    if systemctl is-active --quiet "$CHAIN_NAME.service"; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\n$pick Node Service is already running..." 6 55
        sleep 3
        monitor_menu
    fi
}

chains_dir="chains"
    chains_options=()
    for file in "$chains_dir"/*; do
        chain_name_ext=$(basename "$file")
        chain_name_noext="${chain_name_ext%.*}"
        chains_options+=("$chain_name_noext" "")
    done
    
check_wallets() {

    if [ -z "$(ls -A "$DAEMON_HOME/$CHAIN_DIR"/*.info 2>/dev/null)" ]; then
    dialog \
    --clear \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --msgbox "\nNo wallets have been created so far.\n\nPlease create a wallet first." 9 40
    wallet_menu
fi

}


confirm_prune() {

    current_menu="under_prune"

    if [ -d "$DAEMON_HOME/$CHAIN_DIR/data" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "PRUNE NODE BLOCKCHAIN" \
        --defaultno \
        --yesno "\nThis option removes all blockchain data for $pick Node, (Node config files will remain).\n\nThen it will download the latest snapshot from $SNAP_URL\n\nFinally, it will extract it and restart the Node with a smaller disk space usage.\n\n\nARE YOU SURE YOU WANT TO PROCEED?\n\n" 15 110
            if [  $? -eq 0 ]; then
                clear
                prune_node
            elif [ $? -eq 1 ]; then
                dialog \
                --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
                --title "WARNING!!!" \
                --infobox "\nCanceled. Returning to Main menu..." 5 40
    
                sleep 3
    
                main_menu
            else
                dialog \
                --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
                --title "WARNING!!!" \
                --infobox "\nAn unexpected error has occurred..." 5 40
    
                sleep 3
    
                main_menu
            fi
    elif [ ! -d "$DAEMON_HOME/$CHAIN_DIR/data" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "INFO" \
        --infobox "\n$pick Node data folder is not installed..." 5 40
    
        sleep 3
    
        monitor_menu
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nAn unexpected error has occurred..." 5 50
    
        sleep 3
    
        monitor_menu
    fi
}
prune_node() {

    snap_file=$(basename "$SNAP_URL")
    
    current_menu="under_prune"
    colored_text "36;1" "Stopping $CHAIN_NAME service...

"

    sudo systemctl stop $CHAIN_NAME.service
    

    sleep 4


    colored_text "36;1" "
    
Backing up (priv_validator_state.json) to $DAEMON_HOME/$CHAIN_DIR/

"

    sleep 1

    cp -v $DAEMON_HOME/$CHAIN_DIR/data/priv_validator_state.json $DAEMON_HOME/$CHAIN_DIR/priv_validator_state.json

    colored_text "32" "



Files SAVED to $DAEMON_HOME/$CHAIN_DIR

"
    colored_text "32;1" "



Press any key to continue...
"
    read -p  ""

    clear

    colored_text "36;1" "Removing $pick Blockchain database files...

"

    sleep 1
    
    rm -rfv $DAEMON_HOME/$CHAIN_DIR/data/
    

    colored_text "32;1" "

All Blockchain files have been removed...
"
    sleep 2

    colored_text "36;1" "
Downloading latest $pick snapshot from NexuSecurus Servers...

"
    sleep 1

    wget -O $snap_file $SNAP_URL --inet4-only
    
    sleep 2
    
    colored_text "36;1" "


Extracting snapshot to $DAEMON_HOME/$CHAIN_DIR

"
    sleep 1
    
    if [[ $snap_file == *.tar.gz ]]; then

        tar -xvf $snap_file -C $DAEMON_HOME/$CHAIN_DIR

    elif [[ $snap_file == *.lz4 ]]; then

        lz4 -c -d $snap_file | tar -xv -C $DAEMON_HOME/$CHAIN_DIR

    else

        coloror_text "31;1" "
        
Error: Unsupported compression snapshot format. Only .tar.gz and .lz4 are supported...

INSTALLATION ABORTED!!!

Press any key to exit...
"

        read -p ""

        main_menu
    fi
    
    sleep 2
    
    colored_text "36;1" "


Removing $snap_file snapshot...

"
    sleep 1

    rm -rfv $snap_file

    sleep 2

    colored_text "36;1" "


Replacing (priv_validator_state.json) with backup...
"

    sleep 1
    
    mv -v $DAEMON_HOME/$CHAIN_DIR/priv_validator_state.json $DAEMON_HOME/$CHAIN_DIR/data/priv_validator_state.json

    sleep 2

    colored_text "36;1" "

Restarting $CHAIN_NAME service...
"

    sleep 1
    
    sudo systemctl start $CHAIN_NAME.service

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --msgbox "\n$pick Node has been successfully pruned..." 6 50
    
    sleep 2
    
    monitor_menu

    

}
chain_list() {

    current_menu="under_chain"

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Chain List" \
    --cancel-label "Exit" \
    --menu "\nSelect a chain to interact:\n" 20 50 5 "${chains_options[@]}" \
    3>&1 1>&2 2>&3

    if [ $? -ne 0 ]; then
        clear
        exit 1
    fi
}

main_menu() {

    current_menu="under_main"

    choice=$(dialog --clear \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Main Menu" \
    --cancel-label "Exit" \
    --menu "\nSelected Chain: $pick\n\nPlease select an option:\n" 20 60 8 \
    "1" "Install Node" \
    "2" "Node Operations" \
    "3" "Wallet Operations" \
    "4" "Validator Operations" \
    "5" "Change Chain" \
    "0" "Exit" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        exit 0
    fi

    case $choice in
        1)
            install_node $pick ;;
        2)
            monitor_menu $pick ;;
        3)
            wallet_menu $pick;;
        4)
            validator_menu $pick ;;
        5)
            go_verify ;;
        
        0) 
            clear
            exit 0 ;;
    esac
}

update_environment() {
    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --msgbox "\nIn the next screen, you might be propmted to enter your sudo password" 7 75
    dependencies_install
}

dependencies_install() {

    clear
    sudo apt update
    if [ $? -eq 0 ]; then
        sudo apt dist-upgrade -y
        sudo apt install -y \
            dialog \
            bash-completion \
            qemu-guest-agent \
            nano \
            tree \
            ntpdate \
            plocate \
            nmon \
            curl \
            rsync \
            screen \
            wget \
            unzip \
            git \
            make \
            cmake \
            nload \
            duf \
            jq \
            fio \
            zip \
            lm-sensors \
            build-essential \
            gcc \
            chrony \
            snapd \
            lz4 \
            telnet \
            ufw \
            xclip \
            bc \
            qrencode \

        # Check if installation was successful
        if [ $? -eq 0 ]; then
            colored_text "32;1" "


System Update was successful!"
            sleep 2
        else
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "WARNING!!!" \
            --infobox "\nSystem update has failed..." 5 35
            sleep 3
            clear
            exit 0
        fi
    else
        dialog \
        --title "WARNING!!!" \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --infobox "\nSystem update has failed or was aborted by the User..." 5 60

        sleep 3
        clear
        exit 0
    fi
    sleep 3
}

go_verify() {

    source_profile

    if ! command -v go &> /dev/null; then

        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "INFO" \
        --msgbox "\nThis is the first time you are running this program.\n\nSome dependencies need to be installed.\n\n\nPLEASE BE PATIENT..." 11 70
        sleep 5
        
        clear

        update_environment
        go_install
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WELCOME" \
        --infobox "\nWelcome to NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" 5 85
        
        sleep 3

        current_menu="under_chain"
        
        pick=$(chain_list)

        if [ $? -ne 0 ]; then
            clear
            exit 0
        fi

        source "$current_dir/chains/$pick.txt"

        chain_file="$current_dir/chains/$pick.txt"

        main_menu
    fi
}

source_profile() {
    source ~/.profile
}

go_install() {

    current_menu="fisrt_setup"
    
    clear
    colored_text "36;1" "The program will now check additional required dependencies...
"
    sleep 1

    sudo rm -rfv /usr/local/go

    sleep 2
    clear

    colored_text "36;1" "Downloading GO v1.22.0...
"    
    wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz

    sleep 2
    clear
    
    colored_text "36;1" "Installing GO v1.22.0...


"
    sudo tar -C /usr/local -xvzf "go1.22.0.linux-amd64.tar.gz"
    rm go1.22.0.linux-amd64.tar.gz

    # Set environment variables in .profile
    clear
    echo "export GOROOT=/usr/local/go" >> ~/.profile
    echo "export GOPATH=$HOME/go" >> ~/.profile
    echo "export GO111MODULE=on" >> ~/.profile
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.profile    # Upda environment variables systemwide
    
    source_profile    # save go version to variable
    

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "SUCCESS!!!" \
    --pause "\nFirst time setup was successful.\n\nSystem will now reboot in 5 seconds..." 15 65 5
    
    if [ $? -eq 0 ]; then
        clear
        sudo reboot
    else
        clear
        main_menu
    fi
    }




install_node() {

    current_menu="under_node"

    if [ -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --msgbox "\n$pick Node is already installed.\n\n\nTo reinstall it, remove it first, using the Remove Node Menu." 10 70
        main_menu
        return
    fi
    
    edited_content=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Edit file" \
    --editbox "$chain_file" 80 120 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        echo "$edited_content" > "$chain_file"
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "INFO" \
        --infobox "\nFile saved successfully.\n\n$pick will use these settings..." 7 50

        sleep 3

    elif [ $? -eq 1 ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nThe installation process was canceled..." 5 45
        
        sleep 3
        
        main_menu
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nAn unexpected error has occurred..." 5 45
        
        sleep 3 
        
        main_menu
    fi

    source "$chain_file"

    if [ "$MONIKER" = "defaultmoniker" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "CANNOT PROCEED" \
        --msgbox "\nTo proceed, you must change the default MONIKER name in file:\n\n$chain_file" 11 65
        main_menu
    fi

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "PROCEED?" \
    --defaultno \
    --pause "\nNode installation will start in 10 seconds\n\nPress Cancel to abort the installation." 12 75 10
    
    if [ $? -eq 0 ]; then
        clear
        install_chain
    elif [ $? -eq 1 ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nAborted. Returning to Main menu..." 5 45
        
        sleep 3
        
        main_menu
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nAn unexpected error has occurred..." 5 45
        
        sleep 3
        
        main_menu
    fi
}


monitor_menu() {

    current_menu="under_monitor"

    check_dir

    if ! systemctl is-active --quiet "$CHAIN_NAME.service"; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --msgbox "\n$pick Node Service is not running...\n\nSome monitoring options will not display any data..." 9 60
        start="STOPPED"
        mon="(Limited)"
    else
        start="RUNNING"
        mon=""
    fi

    if [ $start = "STOPPED" ]; then
        sync="NODE STOPPED "
    else
        output=$($DAEMON_NAME status 2>&1 | jq .SyncInfo)
        sync=$(echo "$output" | jq -r '.catching_up')

        if [ "$sync" = "false" ]; then
            sync="FULLY SYNCRONIZED"
        elif [ "$sync" = "true" ]; then
            sync="CATCHING UP"
        else
            sync="NOT SYNCING"
        fi
    fi

    option=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Monitor Menu" \
    --cancel-label "Back" \
    --menu "\n$pick Node Service Status: "$start"\n\nNode Sync Status: $sync\n" 20 50 5 \
    "1" "Start Node"  \
    "2" "Stop Node"  \
    "3" "View Node General Info  "$mon"" \
    "4" "Prune Node (ADVANCED)"\
    "5" "Remove Node (CAREFUL)" \
    "0" "Return to Main Menu" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        main_menu
    fi

    case "$option" in
        1)
            start_node
            ;;
        2)
            stop_node
            ;;
        3)
            monitor_info
            ;;
        4)
            confirm_prune
            ;;
        5)
            rm_menu
            ;;
            
        0)
            main_menu
            ;;
        *)
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "WARNING!!!" \
            --infobox "\nAn unexpected error has occurred..." 5 50
            sleep 3
            monitor_menu
            ;;
    esac

}

start_node() {

    check_service_running

    sudo systemctl start $CHAIN_NAME.service

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --infobox "\n$pick Node is starting..." 5 50
    sleep 3

    monitor_menu
}

stop_node() {

    check_service_no_running

    sudo systemctl stop $CHAIN_NAME.service

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --infobox "\n$pick Node is stopping..." 5 50
    
    sleep 3
    
    monitor_menu
}

monitor_info() {

    current_menu="monitor_info"

    clear

    option=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Monitor Menu" \
    --cancel-label "Back" \
    --menu "\n$pick Node Service Status: "$start"\n\nNode Sync Status: $sync\n" 20 60 5 \
    "1" "View Node Log" \
    "2" "View Node Sync Status" \
    "3" "View Node Peers" \
    "4" "View Node Details" \
    "0" "Return to Main Menu" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        monitor_menu
    fi

    case "$option" in
        1)
            current_menu="under_monitor_info"

            clear
            colored_text "36" "Press CTRL+C to exit the daemon monitor...

If this is the first time you are running the daemon, it may take a few minutes for the service to start.

"
            sleep 2

            colored_text "32" "
Please wait...

            
Loading Node Log...

"
            sleep 2

            sudo journalctl -u $CHAIN_NAME.service -f --no-hostname -o cat
            monitor_info
            ;;
        2)
            current_menu="under_monitor_info"

            clear

            colored_text "36" "
Press CTRL+C to exit the daemon monitor...


"
            sleep 3
    
            colored_text "32" "
Please wait...


Loading Node Sync Status...

"
            sleep 2
    
            watch "$DAEMON_NAME status 2>&1 | jq .SyncInfo"
    
            monitor_info
            ;;
        3)
            current_menu="under_monitor_info"

            clear
    
            colored_text "36" "The $pick node is connected to the following peers:


"
            curl -sS http://localhost:"$PORT_PREFIX"57/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
            colored_text "32;1" "


Press any key to continue...

"
            read -p  ""
    
            monitor_info
            ;;
        4)
            current_menu="under_monitor_info"

            clear

            colored_text "36" "Node Details:
"
            $DAEMON_NAME config
            colored_text "36" "


Node ID:
"
            $DAEMON_NAME tendermint show-node-id
            colored_text "36" "


Node Private IP Address:

"
            hostname -I | awk '{print $1}'

            colored_text "33" "


Node Public IP Address:

"
            curl ifconfig.me

            colored_text "32;1" "


Press any key to continue...
"
            read -p  ""
    
            monitor_info
            ;;
        0)
            clear
    
            monitor_menu
            ;;
        *)
            colored_text "31" "
            
Invalid option selected. Please try again...

"
    
            sleep 3
    
            monitor_info
            ;;
    esac
    
}



rm_menu() {

    current_menu="monitor_info"

    if [ -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "PROCEED?" \
        --defaultno \
        --yesno "\nAre you sure you want to remove $pick Node?\n\n" 7 50
            if [  $? -eq 0 ]; then
                clear
                remove_chain
            elif [ $? -eq 1 ]; then
                dialog \
                --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
                --title "WARNING!!!" \
                --infobox "\nCanceled. Returning to Main menu..." 5 40
    
                sleep 3
    
                monitor_menu
            else
                dialog \
                --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
                --title "WARNING!!!" \
                --infobox "\nAn unexpected error has occurred..." 5 40
    
                sleep 3
    
                monitor_menu
            fi
    elif [ ! -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "INFO" \
        --infobox "\n$1 Node is not installed..." 5 40
    
        sleep 3
    
        monitor_menu
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --infobox "\nAn unexpected error has occurred..." 5 50
    
        sleep 3
    
        monitor_menu
    fi
}

remove_chain() {

    colored_text "36;1" "Stopping $CHAIN_NAME service...

"   

    sleep 2

    sudo systemctl stop $CHAIN_NAME.service
    sudo systemctl disable $CHAIN_NAME.service
    sudo systemctl daemon-reload

    sleep 3
    clear

    colored_text "36;1" "Backing up $CHAIN_NAME important files to $DAEMON_HOME/$CHAIN_NAME-backups

"

    sleep 2

    mkdir -p $DAEMON_HOME/$CHAIN_NAME-backups
    cp -v $DAEMON_HOME/$CHAIN_DIR/config/node_key.json $DAEMON_HOME/$CHAIN_NAME-backups/node_key.json.bak
    cp -v $DAEMON_HOME/$CHAIN_DIR/config/priv_validator_key.json $DAEMON_HOME/$CHAIN_NAME-backups/priv_validator_key.json.bak
    cp -v $DAEMON_HOME/$CHAIN_DIR/data/priv_validator_state.json $DAEMON_HOME/$CHAIN_NAME-backups/priv_validator_state.json.bak
    cp -v $DAEMON_HOME/$CHAIN_DIR/config/config.toml $DAEMON_HOME/$CHAIN_NAME-backups/config.toml.bak
    cp -v $DAEMON_HOME/$CHAIN_DIR/config/app.toml $DAEMON_HOME/$CHAIN_NAME-backups/app.toml.bak

    sleep 2

    colored_text "32" "


Files SAVED to $DAEMON_HOME/$CHAIN_NAME-backups

"
    colored_text "32;1" "

    
Press any key to continue...

"
    read -p  ""

    clear

    colored_text "36;1" "Removing $CHAIN_NAME files...

"

    sleep 2
    
    rm -rfv "$DAEMON_HOME/.cache"
    rm -rfv "$DAEMON_HOME/$CHAIN_DIR"
    rm -rfv "$DAEMON_HOME/$CHAIN_NAME"
    sudo rm "$HOME/go/bin/$DAEMON_NAME"
    sudo rm "/etc/systemd/system/$CHAIN_NAME.service"

    if [ "$(ls -A "$HOME/go/bin" | grep -cv "cosmovisor")" -eq 0 ]; then
        sudo rm -rfv "$HOME/go"
    fi

    colored_text "32;1" "
All files have been removed...

"
    sleep 2

    dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "INFO" \
    --msgbox "\n$pick Node has been removed successfully..." 7 50
    
    sleep 2
    
    go_verify
}

git_clone_chain() {
    colored_text "36;1" "Cloning and building $pick Node...

"
    sleep 1

    cd $DAEMON_HOME
    git clone $GIT_URL $CHAIN_NAME
    cd $CHAIN_NAME
    git checkout $BIN_VER

    sleep 2
    clear
    
    colored_text "36;1" "Building $pick binaries...


"
    sleep 1

    make install

    sleep 2
}

cosmovisor_install() {
    clear
    
    colored_text "36;1" "CosmoVisor Service will be installed...

"
    sleep 1

    colored_text "36;1" "
Creating required directories...

"

    sleep 2

    mkdir -p -v $DAEMON_HOME/$CHAIN_DIR/cosmovisor/genesis/bin

    sleep 2
    
    colored_text "36;1" "

Copying $pick binaries to $DAEMON_HOME/$CHAIN_DIR/cosmovisor/genesis/bin...


"
    sleep 2

    cp -v $HOME/go/bin/$DAEMON_NAME $DAEMON_HOME/$CHAIN_DIR/cosmovisor/genesis/bin
    
    sleep 2
    
    colored_text "36;1" "


Downloading and setting up CosmoVisor Service...


"
    sleep 2

    colored_text "32" "Please wait...

"
    go install $COSMOVISOR_URL
    
    sleep 2
}

create_service_file() {

    clear
    service_file="/etc/systemd/system/$CHAIN_NAME.service"

    colored_text "33;1" "Please enter your sudo password to create the CosmoVisor service file...

"
    sudo tee "$service_file" >/dev/null <<EOF
[Unit]
Description=CosmoVisor Service
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
WorkingDirectory=$DAEMON_HOME/$CHAIN_DIR
Restart=always
RestartSec=5
LimitNOFILE=65535
Environment="DAEMON_HOME=$DAEMON_HOME/$CHAIN_DIR"
Environment="DAEMON_NAME=$DAEMON_NAME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$DAEMON_HOME/.teritori/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
    clear

    colored_text "36;1" "Enabling $CHAIN_NAME.service at boot...


"
    sudo systemctl daemon-reload
    sudo systemctl enable $CHAIN_NAME.service
    
    sleep 2
}

chain_setup() {

    clear
    
    $DAEMON_NAME config chain-id $CHAIN_ID
    
    clear
    
    $DAEMON_NAME config node tcp://localhost:$PORT_PREFIX"57"
    
    clear
    
    $DAEMON_NAME init $MONIKER --chain-id $CHAIN_ID --home $DAEMON_HOME/$CHAIN_DIR

    sleep 3
    clear

    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"$MIN_GAS_PRICE$DENOM\"|" $DAEMON_HOME/$CHAIN_DIR/config/app.toml

    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:$PORT_PREFIX"58"\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:$PORT_PREFIX"57"\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:$PORT_PREFIX"60"\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:$PORT_PREFIX"56"\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":$PORT_PREFIX"66"\"%" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s%^address = \"tcp://localhost:131;17\"%address = \"tcp://0.0.0.0:$PORT_PREFIX"17"\"%; s%^address = \":8080\"%address = \":$PORT_PREFIX"80"\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:$PORT_PREFIX"90"\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:$PORT_PREFIX"91"\"%; s%:8545%:$PORT_PREFIX"45"%; s%:8546%:$PORT_PREFIX"46"%; s%:6065%:$PORT_PREFIX"65"%" $DAEMON_HOME/$CHAIN_DIR/config/app.toml
}

chain_files_get() {

    snap_domain=$(echo "$SNAP_URL" | sed 's/https:\/\/\([^\.]*\)\.com.*/\1/')
    gen_domain=$(echo "$GENESIS_URL" | sed 's/https:\/\/\([^\.]*\)\.com.*/\1/')
    addr_domain=$(echo "$ADDR_URL" | sed 's/https:\/\/\([^\.]*\)\.com.*/\1/')

    snap_file=$(basename "$SNAP_URL")


    clear
    colored_text "36;1" "Downloading latest $pick snapshot from $snap_domain Servers...

"
    sleep 2

    wget -O $snap_file $SNAP_URL --inet4-only
    
    sleep 1
    
    colored_text "36;1" "

Extracting snapshot to $DAEMON_HOME/$CHAIN_DIR

"
    sleep 2

    if [[ $snap_file == *.tar.gz ]]; then

        tar -xvf $snap_file -C $DAEMON_HOME/$CHAIN_DIR

    elif [[ $snap_file == *.lz4 ]]; then

        lz4 -c -d $snap_file | tar -x -C $DAEMON_HOME/$CHAIN_DIR

    else

        coloror_text "31;1" "
        
Error: Unsupported compression snapshot format. Only .tar.gz and .lz4 are supported...

INSTALLATION ABORTED!!!

Press any key to exit...
"

        read -p ""

        main_menu
    fi
    
    sleep 1
    clear

    if [ -f "$DAEMON_HOME/$CHAIN_DIR/data/upgrade-info.json" ]; then
        cp -v $DAEMON_HOME/$CHAIN_DIR/data/upgrade-info.json $DAEMON_HOME/$CHAIN_DIR/cosmovisor/genesis/upgrade-info.json
    fi
    
    sleep 2
    
    colored_text "36;1" "

Removing $snap_file

"
    rm -rfv $snap_file

    sleep 2
    clear
    
    colored_text "36;1" "Downloading $pick addrbook from $addr_domain Servers...

"

    sleep 2
    
    wget -O addrbook.json $ADDR_URL --inet4-only
    
    sleep 1
    
    colored_text "36;1" "

Placing addrbook in $DAEMON_HOME/$CHAIN_DIR/config

"
    sleep 2
    
    mv -v addrbook.json $DAEMON_HOME/$CHAIN_DIR/config
    
    sleep 2
    clear
    
    colored_text "36;1" "Downloading $pick genesis from $gen_domain Servers...

"
    sleep 2
    
    wget -O genesis.json $GENESIS_URL --inet4-only
    
    sleep 1
    
    colored_text "36;1" "

Moving genesis to $DAEMON_HOME/$CHAIN_DIR/config

"

    sleep 2
    
    mv -v genesis.json $DAEMON_HOME/$CHAIN_DIR/config
    
    sleep 2

    clear
}

set_sentry() {
# SET FILE CHECK

    sed -i -e 's|^pruning *=.*|pruning = "custom"|'   -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|'   -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|'   -e 's|^pruning-interval *=.*|pruning-interval = "10"|'   $DAEMON_HOME/$CHAIN_DIR/config/app.toml

    sed -i -e 's|^snapshot-interval *=.*|snapshot-interval = 0|' $DAEMON_HOME/$CHAIN_DIR/config/app.toml

    sed -i -e 's|îndexer *=.*|indexer = "null"|' $DAEMON_HOME/$CHAIN_DIR/config/config.toml
    
    sed -i -e "s|^seed_mode *=.*|seed_mode = \"false\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^pex *=.*|pex = \"true\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^addr_book_strict *=.*|addr_book_strict = \"false\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "36;1" " THIS NODE IS BEING CONFIGURED AS A SENTRY NODE. PEX MODE IS ENABLED, SO PEERS WILL BE ADDED AUTOMATICALLY.

"


    colored_text "33" "
Insert your other Validator/Sentry Nodes Persistent Peers "NodeID@IP:PORT" separated by commas (,) :

"
    colored_text "37" "
For example:

Node1ID@89.207.132;1.170:26656,Node2ID@38.0.101.76:26656

" 
    read -r persistent_peers

    sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$persistent_peers\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "33" "
    
Insert your Validator Nodes Private Peers ID "NodeID" separated by commas (,) :

"
    colored_text "37" "
For example:

Node1ID,Node2ID

" 
    read -r validator_private_peers

    sed -i -e "s|^private_peer_ids *=.*|private_peer_ids = \"$validator_private_peers\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "33" "

Insert your other Validator/Sentry Nodes Unconditional Peers "NodeID" separated by commas (,) :

"
    colored_text "37" "
For example:

Node1ID,Node2ID

" 
    read -r unconditional_peers
    
    sleep 1

    sed -i -e "s|^unconditional_peer_ids *=.*|unconditional_peer_ids = \"$unconditional_peers\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "32;1" "


Applying changes to $DAEMON_HOME/$CHAIN_DIR/config/config.toml

"
    sleep 3
}

set_validator() {
# SET FILE CHECK

    sed -i -e 's|^pruning *=.*|pruning = "custom"|'   -e 's|^pruning-keep-recent *=.*|#pruning-keep-recent = "100"|'   -e 's|^pruning-keep-every *=.*|#pruning-keep-every = "0"|'   -e 's|^pruning-interval *=.*|#pruning-interval = "10"|'   $DAEMON_HOME/$CHAIN_DIR/config/app.toml

    sed -i -e 's|^snapshot-interval *=.*|snapshot-interval = 0|' $DAEMON_HOME/$CHAIN_DIR/config/app.toml

    sed -i -e 's|îndexer *=.*|indexer = "null"|' $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^seed_mode *=.*|seed_mode = \"false\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^pex *=.*|pex = \"false\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^addr_book_strict *=.*|addr_book_strict = \"false\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    sed -i -e "s|^double_sign_check_height *=.*|double_sign_check_height = \"15\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "31;1" "WARNING:

" 

    colored_text "36" "THIS NODE IS BEING CONFIGURED AS A VALIDATOR NODE USING SENTRY NODES TOPOLOGY FOR DDOS PROTECTION. PLEASE READ THE FOLLOWING TEXT.

>>> If you don't add some peers, this node will not be able to connect to the network, and therefore it will not be able to sync. <<<

"

    colored_text "33" "

Insert your Sentry Nodes Persistent Peers "NodeID@IP:PORT" separated by commas (,) :

"
    colored_text "37" "
For example:

Node1ID@89.207.132;1.170:26656,Node2ID@38.0.101.76:26656

"
    read -r sentry_persistent_peers

    sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$sentry_persistent_peers\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "33" "

Insert your Sentry Nodes Unconditional Peers "NodeID" separated by commas (,) :

"
    colored_text "37" "
For example:

Node1ID,Node2ID

" 
    read -r sentry_unconditional_peers

    sed -i -e "s|^unconditional_peer_ids *=.*|unconditional_peer_ids = \"$sentry_unconditional_peers\"|" $DAEMON_HOME/$CHAIN_DIR/config/config.toml

    colored_text "32" "

Changes successfully applied to $DAEMON_HOME/$CHAIN_DIR/config/config.toml

"
    sleep 2

    set_wallet
}

set_wallet() {

    current_menu="under_wallet"

    wallet=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Wallet Setup Menu" \
    --cancel-label "Back" \
    --menu "Choose an option:" 10 50 3 \
    "1" "Create New Wallet" \
    "2" "Import Existing Wallet" \
    "3" "Leave" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        wallet_menu
    fi

    case $wallet in
        1)
            clear

            new_wallet_name=$(dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "Wallet Setup Menu" \
            --inputbox "Insert your new wallet name:" 10 50 3>&1 1>&2 2>&3 3>&-)

            if [ $? -ne 0 ]; then
                clear
                wallet_menu
            fi


            sed -i "s/WALLET_NAME=.*/WALLET_NAME=\"$new_wallet_name\"/" "$current_dir/chains/$pick.txt"

            source "$current_dir/chains/$pick.txt"


            sleep 1
            clear
            

            colored_text "36" "
Lets create a new wallet to use with your $pick Node:

The Keyring Backend used will be 'os', so you should enter your $USER password as passphrase to unlock your wallet:

"
            sleep 1
    
            if result=$($DAEMON_NAME keys add $WALLET_NAME --keyring-backend os) ; then

                wallet_address=$(echo "$result" | grep -oP '(?<=address: )[^ ]+')

                sed -i "s/CURRENT_WALLET_ADDR=.*/CURRENT_WALLET_ADDR=\"$wallet_address\"/" "$current_dir/chains/$pick.txt"

                colored_text "33" "

IMPORTANT >>> TAKE NOTE OF YOUR SEED PHRASE ABOVE, IF YOU LOSE IT, YOU WILL NEVER BE ABLE TO ACCESS YOUR FUNDS AGAIN!!!

"
                colored_text "32" " 
$pick Wallet created successfully!

"

                colored_text "32;1" "



SAVE YOUR SEED PHRASE, before pressing any key to continue...

"           
                read -p ""

                sleep 1
    
                wallet_menu
            else
    
                clear
    
                colored_text "31;1" "UPS!!! Something went wrong. Please retry again...
"
    
                sleep 3
    
                wallet_menu
            fi ;;
        2)

            clear
    
            new_wallet_name=$(dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "Wallet Setup Menu" \
            --inputbox "Insert the for your imported wallet:" 10 50 3>&1 1>&2 2>&3 3>&-)

            if [ $? -ne 0 ]; then
                clear
                wallet_menu
            fi 

            sed -i "s/WALLET_NAME=.*/WALLET_NAME=\"$new_wallet_name\"/" "$current_dir/chains/$pick.txt"

            source "$current_dir/chains/$pick.txt"

            clear
    
            colored_text "36" "Lets import an existing wallet to use with your $pick Node:

The Keyring Backend used will be 'os', so you should enter your $USER password as passphrase to unlock your wallet:

"
            
            sleep 2

            if $DAEMON_NAME keys add $WALLET_NAME --recover --keyring-backend os; then

                colored_text "32" "

$pick Wallet imported successfully!

"
                colored_text "32;1" "



Press any key to continue...

" 
            read -p ""

            sleep 1

            wallet_menu
            else
                clear
    
                colored_text "31;1" "UPS!!!, Something went wrong, please try again...
"
    
                sleep 3
    
                wallet_menu
            fi ;;
        3)
            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "INFO" \
            --msgbox "\nWallet setup skipped.\n\nValidator Nodes need a wallet to operate.\n\nYou can create one later in the Wallet Operations Menu." 11 72 ;;
    esac
}

wallet_info() {

    current_menu="under_wallet"

    check_wallets

    colored_text "36;1" "Wallet General Info:
        
        "
    
    if ! $DAEMON_NAME keys show $WALLET_NAME; then
        clear
        colored_text "31" "The wallet named "$WALLET_NAME" was not found, or the password is incorrect.

"

        colored_text "32;1" "
Press any key to continue...

"
        read -p ""
    
        sleep 1
    
        wallet_menu
    else        
        colored_text "32;1" "

Press any key to continue...

" 
        read -p ""

        sleep 2
    
        wallet_menu
    fi
}

send_funds() {

    current_menu="under_wallet"

    check_wallets


    colored_text "36;1" "
***********************************************************
*               WALLET FUNDS TRANSFER MENU                *
***********************************************************    

"
    colored_text "33" "
Currently using >( $WALLET_NAME )< wallet.

"
    
    while true; do

        colored_text "33" "

    
Please enter Recipient's Address: 

" 
        read -r recipient_address
        recipient_address=$(echo "$recipient_address" | tr -d '[:space:]')



        if [[ $recipient_address == *"failed"* ]] ; then
            clear
            colored_text "31" "

The address you entered is not valid. Please enter it again...

"

            sleep 3
        else
            break
        fi

    done




    if [ $? -ne 0 ]; then
        colored_text "31;1" "


UPS!!! Something went wrong... Please retry again...

"
    
        sleep 3
    
        wallet_menu
    fi

    while true; do
        colored_text "33" "

Please enter amount to send (Fees are in AUTO MODE, please left some spare for fees, or the transaction will fail): 

" 
        read -r amount_to_send

        if [[ $amount_to_send =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            uamount_to_send=$(bc <<< "scale=4; $amount_to_send * 1000000")
            break
        else
            colored_text "31" "

Enter a valid amount... Please retry again...

***********************************************************

"
            
            sleep 3
        fi
    done

    if [ $? -ne 0 ]; then
        colored_text "31;1" "
        

UPS!!! Something went wrong... Check the error message above, for more details.

"
    
        sleep 4
    
        wallet_menu
    fi


    colored_text "33" "



You are about to send $amount_to_send $TICKER to $recipient_address account, from your $WALLET_NAME wallet.


"
    colored_text "33" "

Please enter your >( $USER )< system password to unlock your >( $WALLET_NAME )< wallet and confirm the transaction:


"
    $DAEMON_NAME tx bank send $WALLET_NAME $recipient_address $uamount_to_send$DENOM --from $WALLET_NAME --chain-id $CHAIN_ID --gas auto --gas-adjustment 1.5 --gas-prices $MIN_GAS_PRICE$DENOM
    
    if [ $? -ne 0 ]; then
        colored_text "31;1" "


UPS!!! Something went wrong... You can check the error message above, for more details.

"
        colored_text "32;1" "

Press any key to continue...

"
        read -p ""
    
        wallet_menu
    fi

    colored_text "32;1" "

Your request was been successfully completed!


Press any key to continue...

"

    read -p ""

    wallet_menu
    
}

receive_funds() {

    current_menu="under_wallet"

    check_wallets
    
    clear

    colored_text "33" "Please enter your $USER password to unlock your ($WALLET_NAME) wallet: 

"
    
    current_address=$($DAEMON_NAME keys show $WALLET_NAME -a)

    qrencode -t UTF8 -s 10 -m 2 -o .addrfile.txt $current_address

    echo -n "current_address" | xclip -selection clipboard

    echo "
$current_address" >> .addrfile.txt

    clear

    colored_text "36;1" "

Below is your address, in QR Code format, and in plain text format.
    
"
    cat .addrfile.txt
    rm .addrfile.txt

    colored_text "32;1" "



Press any key to continue...

"
    read -p ""

    wallet_menu
}


change_wallet() {

    check_wallets

    current_menu="under_wallet"

    wallet_files_dir="$DAEMON_HOME/$CHAIN_DIR"
    wallets=$(ls $wallet_files_dir/*.info 2>/dev/null)

    wallet_list=()
    for wallets in $wallets; do
        wallet_file=$(basename "$wallets")
        wallet_file_noext="${wallet_file%.*}"
        wallet_list+=("$wallet_file_noext" "")
    done

    choice=$(dialog --clear \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Change Wallet" \
    --menu "Please select an option:" 17 60 8 \
    "${wallet_list[@]}" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        wallet_menu
    fi

    clear

    colored_text "36;1" "Your wallet needs to be unlocked in order to change it:
    

The Keyring Backend used will be 'os', so you should enter your $USER password as passphrase to unlock your wallet:

"
            

    wallet_address=$($DAEMON_NAME keys show $choice -a)

    if [ $? -ne 0 ]; then
        colored_text "31" "


The wallet named "$choice" was not found, or the password is incorrect.

"
        sleep 3

        wallet_menu
    fi

    sed -i "s/CURRENT_WALLET_ADDR=.*/CURRENT_WALLET_ADDR=\"$wallet_address\"/" "$current_dir/chains/$pick.txt"
    sed -i "s/WALLET_NAME=.*/WALLET_NAME=\"$choice\"/" "$current_dir/chains/$pick.txt"



    dialog \
    --clear \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Wallet Changed" \
    --msgbox "\nWallet changed to $choice" 7 50

    source "$current_dir/chains/$pick.txt"
    wallet_menu
}

remove_wallet() {

    current_menu="under_wallet"

    check_wallets

    colored_text "36;1" "Removing Wallet Menu for" && colored_text "33;1" " $WALLET_NAME
    
"


    colored_text "33" "

    
Enter your password to proceed with the removal of the wallet:" && colored_text "33;1" " $WALLET_NAME"


    if ! $DAEMON_NAME keys delete $WALLET_NAME --yes ; then
        clear
        colored_text "31" "

The wallet named "$WALLET_NAME" was not found, or the password was incorrect.

"

        colored_text "32;1" "

Press any key to continue...

"
        read -p ""
    
        wallet_menu
    else

        sed -i "s/WALLET_NAME=.*/WALLET_NAME=\" \"/" "$current_dir/chains/$pick.txt"
        sed -i "s/CURRENT_WALLET_ADDR=.*/CURRENT_WALLET_ADDR=\" \"/" "$current_dir/chains/$pick.txt"

        
        colored_text "32" "



Wallet $WALLET_NAME removed successfully!

"
        colored_text "32;1" "

Press any key to continue...

"
        read -p ""

        source "$current_dir/chains/$pick.txt"

        wallet_menu
    fi
}
wallet_menu() {
    
    current_menu="wallet_menu"

    check_dir

    if ls "$DAEMON_HOME/$CHAIN_DIR"/*.info >/dev/null 2>&1; then
        
        if check_service_no_running; then
        
            account_balance=$($DAEMON_NAME query bank balances $CURRENT_WALLET_ADDR)
            uamount=$(echo "$account_balance" | grep -oP '(?<=amount: ")[^"]+')
            actual_balance=$(bc <<< "scale=4; $uamount / 1000000")

            if [ -z "$actual_balance" ]; then
            actual_balance="0.0000"
            fi
        
            clear

    fi

fi


    option=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Wallet Menu" \
    --cancel-label "Back" \
    --menu "\nSelected Wallet: $WALLET_NAME\n\nCurrent Balance: $actual_balance $TICKER\n" 20 70 7 \
    "1" "Create or Import Wallet" \
    "2" "View Wallet Info" \
    "3" "Send Funds" \
    "4" "Receive Funds" \
    "5" "Change Active Wallet" \
    "6" "Remove Active Wallet" \
    "0" "Return to Main Menu" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        main_menu
    fi

    case "$option" in
        1)
            clear
            set_wallet
            ;;
        2)
            clear
            wallet_info ;;
        3)
            clear
            send_funds ;;
        4)
            clear
            receive_funds ;;
        5)
            clear
            change_wallet ;;
        6)
            clear
            remove_wallet ;;
        0)
            clear
            main_menu ;;
    esac

}

validator_menu() {

    current_menu="validator_menu"

    check_dir

    check_service_no_running

    choice=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Validator Menu" \
    --cancel-label "Back" \
    --menu "Select an option:" 20 60 11 \
    "1" "Claim Rewards from Validator" \
    "0" "Return to Main Menu" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        main_menu
    fi

    case $choice in
        0)
            clear
            main_menu
            ;;
        1)
            current_menu="validator_options"
            clear

            check_wallets

            dialog \
            --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
            --title "CLAIM REWARDS" \
            --defaultno \
            --yesno "\nThis process will claim COMMISSION REWARDS from ( $MONIKER ) Validator.\n\nAll funds will be sent to $WALLET_NAME wallet.\n\n\n\nARE YOU SURE YOU WANT TO CLAIM REWARDS?" 15 85

            if [ $? -ne 0 ]; then
                clear
                validator_menu
            fi

            clear

            colored_text "36;1" "Claiming Rewards Process from the $MONIKER Validator...

"
            colored_text "33" "

Enter your $WALLET_NAME password to use it to claim rewards from the $MONIKER Validator. As usual its your $USER password.

"

            if result=$($DAEMON_NAME keys show $WALLET_NAME --bech=val) ; then

                valoper_address=$(echo "$result" | grep -oP '(?<=address: )[^ ]+')

                colored_text "33" "


Enter your $WALLET_NAME password to proceed with the claiming signing. As usual its your $USER password.

"
                if ! ($DAEMON_NAME tx distribution withdraw-rewards $valoper_address --from $WALLET_NAME --chain-id $CHAIN_ID --yes) ; then

                    colored_text "31" "


Failed to claim rewards from the $MONIKER Validator. Check the error above for more details...

"
                    colored_text "32;1" "

Press any key to continue...

"
                    read -p ""

                    validator_menu

                else
                colored_text "32" "


Rewards were successfully claimed from the $MONIKER Validator.

"

                colored_text "32;1" "
Press any key to continue...

"
                read -p ""

                fi

            else
                colored_text "31" "


Failed to claim rewards from the $MONIKER Validator. Check the error above for more details...

"
                colored_text "32;1" "

Press any key to continue...

"
                read -p ""
            
            fi            
                
            validator_menu 
            ;;
    esac
}

node_mode() {

    current_menu="under_install"
    
    mode=$(dialog \
    --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
    --title "Node Mode Selection" \
    --menu "Select a mode to proceed:" 10 50 2 \
    "1" "Validator" \
    "2" "Sentry / Wallet" \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        main_menu
    fi

    case $mode in
        1)
            clear
            set_validator
            ;;
        2)
            clear
            set_sentry
            ;;
    esac
}



install_chain() {

    current_menu="under_install"

    if [ -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "INFO" \
        --infobox "\n$pick Node is already installed..." 5 50
    
        sleep 3
    
        add_menu
    
    elif [ ! -d "$DAEMON_HOME/$CHAIN_DIR" ]; then
        # Git clone chain function
        git_clone_chain
        # Install CosmoVisor Service function
        cosmovisor_install
        # CosmoVisor init service function
        create_service_file
        # Config Chain params function
        chain_setup
        # Snapshot process function
        chain_files_get
        # Node mode function
        node_mode

        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "SUCCESS!!!" \
        --msgbox "\n$pick Node has been successfully installed..." 7 55
    else
        dialog \
        --backtitle "NexuSecurus Cosmos Ecosystem Node / Wallet / Monitor Manager - v0.5b" \
        --title "WARNING!!!" \
        --msgbox "\nAn unexpected error has occurred..." 5 50
        

    fi

    clear
    main_menu
}

source_profile

go_verify
