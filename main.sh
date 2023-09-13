#!/bin/bash
hostname="$(cat /etc/hostname)"

#Funzione per segnalare un errore
error() {
    curl -d ""
}

# Funzione per controllare i permessi di sudo
check_user() {
     if [ "$EUID" -ne 0 ] && sudo -n true 2>/dev/null; then
        echo "L'utente attuale ha i permessi di sudo."
    else
        echo "L'utente attuale non ha i permessi di sudo o è l'utente root."
        read -p "Vuoi chiudere lo script per cambiare utente oppure vuoi creare l'utente chicco? (chiudi/crea): " retry
        if [ "$retry" = "chiudi" ]; then
            echo "Operazione annullata."
            exit 1
        elif [ "$retry" = "crea" ]; then
            create_chicco_user
        else
            echo "Selezione non valida. Riprova."
        fi
    fi
}

check_internet() {
    ping archlinux.org -c 1 -W 1 && echo "Connessione a internet presente" || echo -e "\e[31mConnessione a internet assente\e[0m" && exit 1
}

# Funzione per installare il repo chaotic aur
enable_chaotic_aur() {
    # Controlla se Chaotic AUR è già installato
    if pacman -Qe | grep -q "chaotic-aur"; then
        echo "La mirrorlist di Chaotic AUR è già installata."
    else
        echo "Installazione mirrorlist Chaotic AUR..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    fi

    # Controlla se la mirrorlist di Chaotic AUR è presente in Pacman
    if ! grep -q "^Server = https://chaotic-aur.chaotic.cx" /etc/pacman.conf; then
        echo "Aggiunta degli ip del Chaotic AUR al file /etc/pacman.conf..."
        echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
        echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    else
        echo "La mirrorlist di Chaotic AUR è già presente in /etc/pacman.conf."
    fi
    sudo pacman -Syy
}


# Funzione per installare yay
install_yay() {
    if which yay > dev/null; then
        echo "Yay è già installato."
        else
        local retry=y
    while [ "$retry" = "y" ]; do
        echo "Installazione yay..."
        sudo pacman --needed --noconfirm -Syu yay go fakeroot

        if [ $? -eq 0 ]; then
            echo "Yay è stato installato con successo."
            break
        else
            read -p "Si è verificato un errore durante l'installazione di yay. Vuoi riprovare? (s/n/saltare): " retry
            if [ "$retry" = "s" ]; then
                continue
            elif [ "$retry" = "saltare" ]; then
                echo "Operazione saltata."
                break
            else
                echo "Selezione non valida. Riprova."
            fi
        fi
    done
    fi
}

# Funzione per abilitare i download multipli
enable_multithreaded_download() {
    if grep -q "^ParallelDownloads =" /etc/pacman.conf; then
        echo "I download multipli sono già abilitati nel file pacman.conf."
    else
        echo "Abilitazione download paralleli..."
        read -p "Inserisci il numero di download contemporanei desiderato: " download_count
        echo "Abilitazione download multiplo con $download_count download contemporanei..."
        sudo sed -i "s/^#\(ParallelDownloads = \).*$/\1$download_count/" /etc/pacman.conf
        echo "Download multiplo abilitato con successo con $download_count download contemporanei."
    fi
}


# Funzione per abilitare i colori di Pacman
enable_pacman_colors() {
    if grep -q "^#Color" /etc/pacman.conf; then
        echo "I colori di Pacman sono già abilitati nel file pacman.conf."
    else
        echo "Abilitazione colori di Pacman..."
        sudo sed -i "s/^#\(Color\)/\1/" /etc/pacman.conf
        echo "Colori di Pacman abilitati con successo."
    fi
}


# Funzione per abilitare la verbose package list
enable_verbose_package_list() {
    if grep -q "^#VerbosePkgLists" /etc/pacman.conf; then
        echo "La verbose package list è già attivata nel file pacman.conf."
    else
        echo "Abilitazione verbose package list..."
        sudo sed -i "s/^#\(VerbosePkgLists\)/\1/" /etc/pacman.conf
        echo "Verbose package list abilitata con successo."
    fi
}

# Funzione per abilitare il multilib
enable_multilib() {
    if grep -q "^#[multilib]" /etc/pacman.conf; then
        echo "Abilitazione multilib..."
        sudo sed -i '/\[multilib\]/,+1 s/^#//' /etc/pacman.conf
        echo "Repository multilib attivato con successo."
    else
        echo "Il repository multilib è già abilitato nel file pacman.conf."
    fi
}

# Funzione per inizializzare il Pacman keyring
init_pacman_keyring() {
    echo "Inizializzazione Pacman keyring..."
    sudo pacman-key --init
}

# Funzione per popolare la Keyring di Pacman
populate_pacman_keyring() {
    echo "Popolamento Pacman keyring..."
    sudo pacman-key --populate
}

# Funzione per creare l'utente chicco e impostare la password
create_chicco_user() {
    local password_set=false

    while [ "$password_set" = false ]; do
        echo "Creazione utente chicco e impostazione password..."
        sudo useradd -m -G wheel chicco
        passwd chicco

        if [ $? -eq 0 ]; then
            echo "Password impostata con successo per l'utente chicco."
            password_set=true
        else
            echo "Errore nell'impostazione della password per l'utente chicco."
            read -p "Vuoi riprovare? (s/n): " retry
            if [ "$retry" != "s" ]; then
                password_set=true
            fi
        fi
    done
}

install_base_packages(){
    sudo pacman --needed -Syu go gcc git fakeroot btop neofetch 
}

add_home_bin_path (){
    if [ grep -q "export PATH=$PATH:/home/chicco/.local/bin/" /home/chicco/.bashrc ]; then
    echo "La path per gli eseguibili in home è gia presente"
    else
    echo "export PATH=$PATH:/home/chicco/.local/bin/"
    source .bashrc
    echo "La path è stata aggiunta al file .bashrc"
    
}

install_docker(){
    if [ $pwd = chicco ]; then
        yay --noconfirm --needed -Syu docker docker-compose
        sudo systemctl enable --now docker.service
    else
        create_chicco_user
    fi
}

# Funzione principale
main() {
    echo "Seleziona l'azione da eseguire:"
    echo "1. Serie di funzioni per il server"
    echo "2. Serie di funzioni per il desktop"
    echo "3. Esegui funzioni specifiche (inserisci numeri separati da spazi)"
    read -p "Scelta: " choice

    check_sudo

    case $choice in
        1)
            #Server
            check_user
            check_internet
            init_pacman_keyring
            populate_pacman_keyring
            install_chaotic_aur
            enable_multilib
            install_yay
            enable_parallels_download
            enable_colors
            enable_verbose_package_list
            install_base_packages
            add_home_bin_path
            ;;
        2)
            #Desktop
            check_user
            check_internet
            install_chaotic_aur
            enable_multilib
            install_yay
            enable_colors
            enable_parallels_download
            enable_verbose_package_list
            install_base_packages
            add_home_bin_path

            ;;
        3)
            read -p "Inserisci i numeri delle funzioni da eseguire separati da spazi: " selected_functions
            for function in $selected_functions; do
                case $function in
                    1)

                        ;;
                    2)
                        install_base_packages
                        ;;
                    3)
                        install_chaotic_aur
                        ;;
                    4)
                        install_yay
                        ;;
                    5)
                        enable_parallels_download
                        ;;
                    6)
                        enable_colors
                        ;;
                    7)
                        enable_verbose_package_list
                        ;;
                    8)
                        enable_multilib
                        ;;
                    9)
                        init_pacman_keyring
                        ;;
                    10)
                        populate_pacman_keyring
                        ;;
                    11)
                        create_chicco_user
                        ;;
                    *)
                        echo "Selezione non valida: $function"
                        ;;
                esac
            done
            ;;
        *)
            echo "Selezione non valida."
            ;;
    esac
}

# Esegui la funzione principale
main